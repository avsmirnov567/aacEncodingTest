//
//  AACEncodingManger.m
//  aacEncodingTest
//
//  Created by Aleksandr Smirnov on 13.03.17.
//  Copyright © 2017 Line App. All rights reserved.
//

#import "AACEncodingManger.h"

@interface AACEncodingManger () <NSStreamDelegate>

@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, assign) long bytesRead;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSString *filePath;

@end

@implementation AACEncodingManger

+ (instancetype)sharedInstance {
    static AACEncodingManger *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AACEncodingManger alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
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
            break;
        }
        case NSStreamEventHasBytesAvailable:
        {
            if(!_data) {
                _data = [NSMutableData data];
            }
            
            uint8_t buf[1024];
            NSInteger len = 0;
            len = [(NSInputStream *)aStream read:buf maxLength:1024];
            
            if(len) {
                [_data appendBytes:(const void *)buf length:len];
                _bytesRead = _bytesRead+len;
                NSLog(@"Bytes read count: %ld", _bytesRead);
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
