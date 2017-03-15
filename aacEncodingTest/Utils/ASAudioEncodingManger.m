//
//  ASAudioEncodingManger.m
//  aacEncodingTest
//
//  Created by Aleksandr Smirnov on 13.03.17.
//  Copyright © 2017 Line App. All rights reserved.
//

#import "ASAudioEncodingManger.h"
#import "AACDecoder.h"
#import "NSData+ASBinary.h"

@interface ASAudioEncodingManger () <NSStreamDelegate>

@property (nonatomic, strong) AACDecoder *decoder;

@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, assign) NSUInteger bytesRead;
@property (nonatomic, strong) NSString *filePath;

@end

@implementation ASAudioEncodingManger

+ (instancetype)sharedInstance {
    static ASAudioEncodingManger *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ASAudioEncodingManger alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _decoder = [[AACDecoder alloc] init];
        _inputStream = nil;
        _bytesRead = 0;
    }
    return self;
}

- (void)setUpStreamFromFileWithPath:(NSString *)filePath {
    _filePath = filePath;
    _inputStream = [[NSInputStream alloc] initWithFileAtPath:filePath];
    [_inputStream setDelegate:self];
    [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                            forMode:NSDefaultRunLoopMode];
    [_inputStream open];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
        {
            [_decoder startBackgroundThreads];
            NSLog(@"Opened stream from file with path: %@", _filePath);
            break;
        }
        case NSStreamEventErrorOccurred:
        {
            NSLog(@"Error ocured in stream from file with path: %@", _filePath);
            break;
        }
        case NSStreamEventEndEncountered:
        {
            NSLog(@"Stream end encountered from file with path: %@", _filePath);
            [_inputStream close];
            [_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop]
                                    forMode:NSDefaultRunLoopMode];
            _inputStream = nil;
            _filePath = nil;
            [_decoder notifyThatIncomingStreamEnded];
            break;
        }
        case NSStreamEventHasBytesAvailable:
        {
            uint8_t buf[2048];
            NSInteger len = 0;
            len = [(NSInputStream *)aStream read:buf maxLength:2048];
            
            if(len) {
                [_decoder appendBytesToEncodedData:(const void*)buf length:len];
                _bytesRead = _bytesRead+len;
                NSLog(@"Bytes read count: %lu", _bytesRead);
            } else {
                NSLog(@"no buffer!");
            }
            
            break;
        }
        default:
            break;
    }
}

@end
