//
//  AACEncodingManger.h
//  aacEncodingTest
//
//  Created by Aleksandr Smirnov on 13.03.17.
//  Copyright © 2017 Line App. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AACEncodingManger : NSObject

+ (instancetype)sharedInstance;
- (void)setUpStreamFromFileWithPath: (NSString *)filePath;

@end
