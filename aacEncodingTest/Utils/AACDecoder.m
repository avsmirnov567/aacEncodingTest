//
//  AACDecoder.m
//  aacEncodingTest
//
//  Created by Aleksandr Smirnov on 13.03.17.
//  Copyright © 2017 Line App. All rights reserved.
//

#import "AACDecoder.h"
#import "NSData+ASBinary.h"
#import <AudioToolbox/AudioToolbox.h>

static const int kBufLength = 2048;
static const int kADTSHeaderLength = 7;

@interface AACDecoder ()

//background queues
@property (nonatomic, strong) NSOperationQueue *dataReadingQueue;
@property (nonatomic, strong) NSOperationQueue *decodingQueue;
@property (nonatomic, assign) BOOL incomingStreamEnded;

//for reading frames
@property (nonatomic, strong) NSMutableData *encodedData;
@property (nonatomic, strong) NSMutableData *buffer;
@property (nonatomic, assign) NSInteger encodedDataLength;
@property (nonatomic, assign) NSInteger currPosInData;
@property (nonatomic, assign) NSInteger currPosInBuffer;

//for decoding
@property (nonatomic, strong) NSMutableArray<NSMutableData*> *decoderBuffer;
@property (nonatomic, assign) NSInteger currPosInDecoderBuf;
@property (nonatomic, assign) AudioConverterRef audioConverter;
@property (nonatomic, assign) BOOL converterConfigured;

@end

@implementation AACDecoder

struct PassthroughUserData {
    UInt32 mChannels;
    UInt32 mDataSize;
    const void* mData;
    AudioStreamPacketDescription mPacket;
};

#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        _buffer = [NSMutableData dataWithLength:kBufLength];
        _decoderBuffer = [[NSMutableArray alloc] init];
        _encodedData = nil;
        _encodedDataLength = 0;
        _currPosInData = 0;
        _currPosInBuffer = 0;
        _currPosInDecoderBuf = 0;
        _incomingStreamEnded = NO;
        _decodingQueue = [[NSOperationQueue alloc] init];
        _decodingQueue.maxConcurrentOperationCount = 1;
        _decodingQueue.name =  @"com.wheremychildren.ios.decoderProcessingQueue";
        _dataReadingQueue = [[NSOperationQueue alloc] init];
        _dataReadingQueue.maxConcurrentOperationCount = 1;
        _dataReadingQueue.name = @"com.wheremychildren.ios.decoderDataReadingQueue";
    }
    return self;
}

- (void)notifyThatIncomingStreamEnded{
    _incomingStreamEnded = YES;
}

#pragma mark - Multi-threading Logic

- (BOOL)hasBytesToRead {
    return (_currPosInData < _encodedDataLength) && (_encodedDataLength>0);
}

- (BOOL)hasFramesToDecode {
    return (_currPosInDecoderBuf < _decoderBuffer.count) && (_decoderBuffer.count>0);
}

- (void)startBackgroundThreads {
    __weak typeof(self) weakSelf = self;
    
    NSBlockOperation *readingOperation = [NSBlockOperation blockOperationWithBlock:^{
        typeof(self) strongSelf = weakSelf;
        while(1){
            if ([strongSelf hasBytesToRead]) {
                [strongSelf refillBuffer];
                [strongSelf findNextFrame];
            } else {
                if (_incomingStreamEnded){
                    [strongSelf stopDataReadingQueue];
                    break;
                }
            }
        }
    }];
    [self.dataReadingQueue addOperation:readingOperation];
    
    NSBlockOperation *decodingOperation = [NSBlockOperation blockOperationWithBlock:^{
        typeof(self) strongSelf = weakSelf;
        while (1) {
            if ([strongSelf hasFramesToDecode]) {
                [self decodeAudioFrame:_decoderBuffer[_currPosInDecoderBuf]];
                _currPosInDecoderBuf += 1;
            }
        }
    }];
    [self.decodingQueue addOperation:decodingOperation];
    NSLog(@"----> AAC Decoder Queues started!");
}

- (void)stopDataReadingQueue {
    _dataReadingQueue.suspended = YES;
    [_dataReadingQueue cancelAllOperations];
    _dataReadingQueue.suspended = NO;
    _dataReadingQueue = nil;
    NSLog(@"----> DataReadingQueue stopped!");
}

- (void)stopDecodingTread {
    _decodingQueue.suspended = YES;
    [_decodingQueue cancelAllOperations];
    _decodingQueue.suspended = NO;
    _decodingQueue = nil;
    NSLog(@"----> DecodingQueue stopped!");
}

#pragma mark - Frames Reading Logic

- (void)appendDataToEncodedData:(NSMutableData *)dataToAppend{
    if (!_encodedData){
        _encodedData = dataToAppend;
        _encodedDataLength = dataToAppend.length;
        return;
    }
    [_encodedData appendData:dataToAppend];
    _encodedDataLength += dataToAppend.length;
}

- (void)appendBytesToEncodedData:(const void *)bytesToAppend length:(NSInteger)length{
    if (!_encodedData){
        _encodedData = [NSMutableData dataWithBytes:bytesToAppend length:length];
        _encodedDataLength = length;
        return;
    }
    [_encodedData appendBytes:bytesToAppend length:length];
    _encodedDataLength += length;
}

- (void)refillBuffer {
    NSInteger dataLengthToKeep = kBufLength - _currPosInBuffer;
    NSInteger dataLengthToTake = kBufLength - dataLengthToKeep;
    
    if (_encodedDataLength - _currPosInData > dataLengthToTake) {
        dataLengthToTake = kBufLength - dataLengthToKeep;
    } else {
        dataLengthToTake = _encodedDataLength - _currPosInData;
    }
    
    if (_currPosInBuffer > 0) {
        NSData *bufUnread = [_buffer subdataWithRange:NSMakeRange(_currPosInBuffer, dataLengthToKeep)];
        [_buffer replaceBytesInRange:NSMakeRange(0, dataLengthToKeep) withBytes:bufUnread.bytes];
        _currPosInBuffer = 0;
        NSData *takenData = [_encodedData subdataWithRange:NSMakeRange(_currPosInData, dataLengthToTake)];
        _currPosInData += dataLengthToTake;
        [_buffer replaceBytesInRange:NSMakeRange(dataLengthToKeep, dataLengthToTake) withBytes:takenData.bytes];
        
        if (_encodedDataLength == _currPosInData) {
            NSInteger bytesToZero = kBufLength - dataLengthToKeep - dataLengthToTake;
            [_buffer resetBytesInRange:NSMakeRange(kBufLength-bytesToZero+1, bytesToZero)];
        }
        
    } else {
        NSData *takenData = [_encodedData subdataWithRange:NSMakeRange(_currPosInData, kBufLength)];
        _currPosInData += kBufLength;
        [_buffer replaceBytesInRange:NSMakeRange(0, kBufLength) withBytes:takenData.bytes];
        
    }
}

- (void)findNextFrame {
    int headerStart = [self findADTSSyncWordInBuffer];
    
    if (headerStart<0){
        return;
    }
    
    uint8_t *header = malloc(sizeof(uint8_t) * kADTSHeaderLength);
    [_buffer getBytes:header range:NSMakeRange(headerStart, kADTSHeaderLength)];
    
    int framesize = [self headerBytesIsValid:header];
    
    if (framesize <= 0){
        _currPosInBuffer += kADTSHeaderLength;
        return;
    }
    
    if (framesize > kBufLength){
        _currPosInBuffer = kBufLength-kADTSHeaderLength;
        return;
    }
    
    if (kBufLength - _currPosInBuffer >= framesize) {
        NSMutableData *frameData = [[_buffer subdataWithRange:NSMakeRange(headerStart, framesize)] mutableCopy];
        [_decoderBuffer addObject:frameData];
        _currPosInBuffer += framesize;
        if (!_converterConfigured){
            [self configureAudioConverterWithInputFormat: [self getFormatDescriptionFromADTSHeader:header]];
            _converterConfigured = YES;
        }
    }
}

- (int)findADTSSyncWordInBuffer{
    uint8_t *buf = malloc(sizeof(uint8_t) * kBufLength);
    [_buffer getBytes:buf length:kBufLength];
    for (uint i=0; i<kBufLength-kADTSHeaderLength-1; i++){
        _currPosInBuffer = (NSInteger)i;
        if (buf[i] == 0xFF) {
            if ((buf[i+1] & 0xF0) == 0xF0){
                return i;
            }
        }
    }
    return -1;
}

- (int)headerBytesIsValid: (uint8_t *)header {
    int sampleRate = (header[2] & 0x3C) >> 2;
    int profile = (header[2] & 0xC0) >> 6;
    int channel = ((header[2] & 0x01) << 2) | ((header[3] & 0xC0) >> 6);
    int framesize = (((header[3] & 0x03) << 11) | (header[4] << 3) | ((header[5] & 0xE0) >> 5));
    
    //проверки
    if ([AACDecoder getFrequensyForSampleRateIndex:sampleRate]<0){
        return -1;
    }
    
    if (profile+1 > 4 || profile < 0) {
        return -1;
    }
    
    if (channel <= 0 || channel>7){
        return -1;
    }
    
    if (framesize <= 0) {
        return -1;
    }
    
    return framesize;
}

- (AudioStreamBasicDescription)getFormatDescriptionFromADTSHeader: (uint8_t *)header {
    int sampleRate = (header[2] & 0x3C) >> 2;
    int profile = (header[2] & 0xC0) >> 6;
    int channel = ((header[2] & 0x01) << 2) | ((header[3] & 0xC0) >> 6);
    int framesize = (((header[3] & 0x03) << 11) | (header[4] << 3) | ((header[5] & 0xE0) >> 5));
    
    NSLog(@"Converter configured for format: sr=%u, profile=%u, channel=%u, framesize=%u", sampleRate, profile, channel, framesize);
    
    AudioStreamBasicDescription inputFormat = {0};
    inputFormat.mBitsPerChannel = 0;
    inputFormat.mBytesPerFrame = 0;
    inputFormat.mBytesPerPacket = 0;
    inputFormat.mChannelsPerFrame = channel;
    inputFormat.mFormatFlags = profile;
    inputFormat.mFormatID = kAudioFormatMPEG4AAC;
    inputFormat.mFramesPerPacket = 1024;
    inputFormat.mReserved = 0;
    inputFormat.mSampleRate = [AACDecoder getFrequensyForSampleRateIndex:sampleRate];
    
    return inputFormat;
}

+ (Float64)getFrequensyForSampleRateIndex: (int)sampleRateIndex {
    NSArray *sampleRates = @[ @96000.0f, @88200.0f, @64000.0f, @48000.0f, @44100.0f, @32000.0f, @24000.0f, @22050.0f, @16000.0f, @12000.0f, @11025.0f, @8000.0f, @7350.0f];
    if (sampleRates.count > sampleRateIndex){
        return [sampleRates[sampleRateIndex] floatValue];
    }
    return -1;
}

#pragma mark - Audio Decoding Logic

- (void)configureAudioConverterWithInputFormat: (AudioStreamBasicDescription)inputFormat {
    AudioStreamBasicDescription outputFormat;
    memset(&outputFormat, 0, sizeof(outputFormat));
    outputFormat.mSampleRate       = inputFormat.mSampleRate;
    outputFormat.mFormatID         = kAudioFormatLinearPCM;
    outputFormat.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger;
    outputFormat.mBytesPerPacket   = 2;
    outputFormat.mFramesPerPacket  = 1;
    outputFormat.mBytesPerFrame    = 2;
    outputFormat.mChannelsPerFrame = 1;
    outputFormat.mBitsPerChannel   = 16;
    outputFormat.mReserved         = 0;
    
    OSStatus status =  AudioConverterNew(&inputFormat, &outputFormat, &_audioConverter);
    
    if (status != 0) {
        printf("setup converter error, status: %i\n", (int)status);
    }
}

OSStatus inInputDataProc(AudioConverterRef aAudioConverter,
                         UInt32* aNumDataPackets /* in/out */,
                         AudioBufferList* aData /* in/out */,
                         AudioStreamPacketDescription** aPacketDesc,
                         void* aUserData)
{
    
    struct PassthroughUserData *userData = aUserData;
    if (!userData->mDataSize) {
        *aNumDataPackets = 0;
        return -1;
    }
    
    if (aPacketDesc) {
        userData->mPacket.mStartOffset = 0;
        userData->mPacket.mVariableFramesInPacket = 0;
        userData->mPacket.mDataByteSize = userData->mDataSize;
        *aPacketDesc = &userData->mPacket;
    }       
    
    aData->mBuffers[0].mNumberChannels = userData->mChannels;
    aData->mBuffers[0].mDataByteSize = userData->mDataSize;
    aData->mBuffers[0].mData = (void*)(userData->mData);
    
    // No more data to provide following this run.
    userData->mDataSize = 0;
    
    return noErr;
}

- (void)decodeAudioFrame:(NSData *)frame{

    struct PassthroughUserData userData = { 1, (UInt32)frame.length, [frame bytes]};
    NSMutableData *decodedData = [NSMutableData new];
    
    const uint32_t MAX_AUDIO_FRAMES = 128;
    const uint32_t maxDecodedSamples = MAX_AUDIO_FRAMES * 1;
    
    do{
        uint8_t *buffer = (uint8_t *)malloc(maxDecodedSamples * sizeof(short int));
        AudioBufferList decBuffer;
        decBuffer.mNumberBuffers = 1;
        decBuffer.mBuffers[0].mNumberChannels = 1;
        decBuffer.mBuffers[0].mDataByteSize = maxDecodedSamples * sizeof(short int);
        decBuffer.mBuffers[0].mData = buffer;
        
        UInt32 numFrames = MAX_AUDIO_FRAMES;
        
        AudioStreamPacketDescription outPacketDescription;
        memset(&outPacketDescription, 0, sizeof(AudioStreamPacketDescription));
        outPacketDescription.mDataByteSize = MAX_AUDIO_FRAMES;
        outPacketDescription.mStartOffset = 0;
        outPacketDescription.mVariableFramesInPacket = 0;
        
        OSStatus rv = AudioConverterFillComplexBuffer(_audioConverter,
                                                      inInputDataProc,
                                                      &userData,
                                                      &numFrames /* in/out */,
                                                      &decBuffer,
                                                      &outPacketDescription);
        
        if (rv && rv != -1) {
            NSLog(@"Error decoding audio stream: %d\n", rv);
            break;
        }
        
        if (numFrames) {
            [decodedData appendBytes:decBuffer.mBuffers[0].mData length:decBuffer.mBuffers[0].mDataByteSize];
        }
        
        if (rv == -1) {
            break;
        }
        
        
    }while (true);

    NSLog(@"decoded %lu bytes of AAC", (unsigned long)decodedData.length);
}

@end
