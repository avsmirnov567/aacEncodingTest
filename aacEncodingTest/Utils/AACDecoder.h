//
//  AACDecoder.h
//  aacEncodingTest
//
//  Created by Aleksandr Smirnov on 13.03.17.
//  Copyright © 2017 Line App. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AACDecoder : NSObject

- (void)appendDataToEncodedData: (NSMutableData *)dataToAppend;
- (void)appendBytesToEncodedData: (const void *)bytesToAppend length:(NSInteger)length;
- (void)findNextFrame;

@end
