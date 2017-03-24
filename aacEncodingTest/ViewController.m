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

@interface ViewController () 

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


- (void)didReceiveMemoryWarning {
    
}

- (IBAction)playButtonAction:(id)sender {
    STKAudioPlayer* audioPlayer = [[STKAudioPlayer alloc] init];
    NSURL* url = [NSURL fileURLWithPath:_filePath];
    [audioPlayer play:[url absoluteString]];
}

@end
