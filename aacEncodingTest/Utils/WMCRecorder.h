//
//  WMCRecorder.h
//  aacEncodingTest
//
//  Created by Aleksandr Smirnov on 13.03.17.
//  Copyright © 2017 Line App. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WMCRecorder : NSObject

@property (nonatomic) BOOL isRecording;

- (void)startRecording;
- (void)stopRecording;

@end
