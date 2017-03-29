//
//  STKInputStreamDataSource.h
//  Pods
//
//  Created by Aleksandr Smirnov on 27.03.17.
//
//

#import "STKCoreFoundationDataSource.h"

@interface STKInputStreamDataSource : STKCoreFoundationDataSource

- (instancetype)initWithStream: (CFReadStreamRef)readStream;

@end
