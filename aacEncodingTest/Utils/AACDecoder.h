//
//  AACDecoder.h
//  aacEncodingTest
//
//  Created by Aleksandr Smirnov on 13.03.17.
//  Copyright © 2017 Line App. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface AACDecoder : NSObject

- (void)notifyThatIncomingStreamEnded;
- (void)startBackgroundThreads;
- (void)appendDataToEncodedData: (NSMutableData *)dataToAppend;
- (void)appendBytesToEncodedData: (const void *)bytesToAppend length:(NSInteger)length;
- (void)findNextFrame;
- (size_t) copyAACFramesIntoBuffer: (AudioBufferList*)ioData;

@end
