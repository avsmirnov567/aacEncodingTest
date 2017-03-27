//
//  ViewController.m
//  aacEncodingTest
//
//  Created by Aleksandr Smirnov on 13.03.17.
//  Copyright © 2017 Line App. All rights reserved.
//

#import "ViewController.h"
#import "ASAudioEncodingManger.h"
#import <AVFoundation/AVFoundation.h>
#import "STKAudioPlayer.h"


@interface ViewController () <NSStreamDelegate>

@property (nonatomic, assign) NSUInteger bytesRead;
@property (nonatomic, strong) NSInputStream *iStream;
@property (nonatomic, strong) NSOutputStream *oStream;
@property (nonatomic, strong) NSString *filePath;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *myFile = [mainBundle pathForResource: @"testaudio" ofType: @"aac"];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:myFile]) {
        _filePath = myFile;
        NSLog(@"File exists");
    } else {
        NSLog(@"File not exits");
    }
}


-(void)initialSocket {
    printf("initialSocket\n");
    CFReadStreamRef readStream = NULL;
    CFWriteStreamRef writeStream = NULL;
    
    NSString *ip = @"185.137.12.28";   //Your IP Address
    uint port = 12556;
    
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef)ip, port, &readStream,  &writeStream);
    
    if (readStream && writeStream) {
        CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        
        _iStream = (__bridge NSInputStream *)readStream;
        CFReadStreamRef playerInputStream = (__bridge CFReadStreamRef)_iStream;
        STKAudioPlayer *ap = [[STKAudioPlayer alloc] init];
        [ap playStream:playerInputStream];
        
        _oStream = (__bridge NSOutputStream *)writeStream;
        [_oStream setDelegate:self];
        [_oStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_oStream open];
    }
}

- (void)join {
    const char DataTobeSent[] = {0xff, 0xf1, 0x1F};
    uint8_t dataArray[3]; // an 3 byte array
    for (NSInteger i = 0; i < 3; i++) {
        dataArray[i] = (uint8_t) DataTobeSent[i];
    }
    
    [_oStream write:dataArray maxLength:sizeof(dataArray)];
    
    NSDictionary *sendData = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"ZOQJZ7qDMzmTiImr3zaTDQ3KCE7htw==", @"u",
                              @"138261", @"childId", nil];
    
    NSLog (@"JSON: %@", (NSString*)sendData);
    
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:sendData
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
    
    const char bytes[] = {([data length] >> 8 & 0xff), ([data length] & 0xff)};
    
    uint8_t bytesArray[2];
    for (NSInteger i = 0; i < 2; i++) {
        bytesArray[i] = (uint8_t) bytes[i];
    }
    
    [_oStream write:bytesArray maxLength:sizeof(bytesArray)];
    [_oStream write:[data bytes] maxLength:[data length]];
}

- (IBAction)playButtonAction:(id)sender {
    [self initialSocket];
    [self join];
}

@end
