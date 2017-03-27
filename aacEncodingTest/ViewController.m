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
@property (nonatomic, strong) NSInputStream *inputStream;
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

- (IBAction)playButtonAction:(id)sender {
    STKAudioPlayer* audioPlayer = [[STKAudioPlayer alloc] init];
    _inputStream = [[NSInputStream alloc] initWithFileAtPath:_filePath];

    CFReadStreamRef playerInputStream = (__bridge CFReadStreamRef)_inputStream;
    
    [audioPlayer playStream:playerInputStream];
}

@end
