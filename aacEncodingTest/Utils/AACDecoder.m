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

@interface AACDecoder ()

@property (nonatomic, strong) NSMutableData *encodedData;
@property (nonatomic, assign) NSInteger encodedDataLength;
@property (nonatomic, assign) NSInteger currentPosition;
@property (nonatomic, assign) AudioStreamBasicDescription inputFormat;

@end

@implementation AACDecoder

- (instancetype)init
{
    self = [super init];
    if (self) {
        _encodedData = nil;
        _encodedDataLength = 0;
        _currentPosition = 0;
    }
    return self;
}

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

- (void)findNextFrame {
    uint adtsHeaderLength = 7;
    uint bufLength = 16;
    uint8_t *buf = malloc(sizeof(char) * bufLength); //буфер для поиска ADTS заголовка
    int headerStart = -1;
    
    while (_currentPosition-1<(int)(_encodedDataLength-bufLength)) {
        //заполняем буфер
        
        [_encodedData getBytes:buf range:NSMakeRange(_currentPosition, bufLength)];
        _currentPosition += bufLength-1;
        
        headerStart = [self findADTSSyncWordInBuffer:buf bufLength:bufLength];
        
        if (headerStart>0 && headerStart+adtsHeaderLength <= bufLength) {
            uint8_t *header = [self getHeaderFromBuffer:buf headerStart:headerStart];
            int framesize = [self headerBytesIsValid:header];
            if (framesize > 0){
                if (_inputFormat.mSampleRate == 0){
                    _inputFormat = [self getFormatDescriptionFromADTSHeader:header];
                }
                
            }
        }
        
        continue;
    }
}

- (int)findADTSSyncWordInBuffer: (uint8_t *)buf bufLength: (uint)bufLength{
    for (uint i=0; i<bufLength; i++){
        if (buf[i] == 0xFF) {
            if ((buf[i+1] & 0xF0) == 0xF0){
                return i;
            }
        }
    }
    return -1;
}

- (uint8_t *)getHeaderFromBuffer:(uint8_t *)buf headerStart: (int)headerStart{
    uint adtsHeaderLength = 7;
    uint8_t *header = malloc(sizeof(char) * adtsHeaderLength);
    
    for (int i=0; i<7; i++){
        header[i]=buf[headerStart+i];
    }
    
    return header;
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
    
    NSLog(@"sr=%u, profile=%u, channel=%u, framesize=%u", sampleRate, profile, channel, framesize);
    
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

@end
