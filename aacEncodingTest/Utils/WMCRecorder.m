//
//  WMCRecorder.m
//  aacEncodingTest
//
//  Created by Aleksandr Smirnov on 13.03.17.
//  Copyright © 2017 Line App. All rights reserved.
//

#import "WMCRecorder.h"
#import "AACEncoder.h"

#import <AVFoundation/AVFoundation.h>

@interface WMCRecorder () <NSStreamDelegate>

@property (nonatomic, strong) AVCaptureSession* session;
@property (nonatomic, strong) AVCaptureAudioDataOutput* audioOutput;
@property (nonatomic, strong) dispatch_queue_t audioQueue;
@property (nonatomic, strong) AVCaptureConnection* audioConnection;
@property (nonatomic, strong) AACEncoder *aacEncoder;

@end

@implementation WMCRecorder

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)setupSession
{
    
}

- (void)setupEncoder
{
    
}

- (void)setupAudioCapture
{
    
}

- (void)startRecording
{
    
}

- (void)stopRecording
{
    
}

@end
