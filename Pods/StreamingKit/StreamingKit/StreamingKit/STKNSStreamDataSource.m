//
//  STKSocketDataSource.m
//  Pods
//
//  Created by Aleksandr Smirnov on 27.03.17.
//
//

#import "STKNSStreamDataSource.h"

@interface STKNSStreamDataSource ()
{
    CFReadStreamRef inputStream;
    SInt64 position;
    SInt64 length;
    AudioFileTypeID _audioFileTypeHint;
}

@end

@implementation STKNSStreamDataSource

- (instancetype)initWithStream:(CFReadStreamRef)readStream {
    if (self = [super init])
    {
        inputStream = readStream;
        _audioFileTypeHint = kAudioFileAAC_ADTSType;
    }
    return self;
}

-(AudioFileTypeID) audioFileTypeHint
{
    return _audioFileTypeHint;
}

-(SInt64) position
{
    return position;
}

-(SInt64) length
{
    return length;
}

-(void) dealloc
{
    [self close];
}

-(void) close
{
    if (stream)
    {
        [self unregisterForEvents];
        
        CFReadStreamClose(stream);
        
        stream = 0;
    }
}

-(void) open
{
    if (stream)
    {
        [self unregisterForEvents];
        
        CFReadStreamClose(stream);
        CFRelease(stream);
        
        stream = 0;
    }
    
    stream = inputStream;
    
    if (stream) {
        [self reregisterForEvents];
        
        CFReadStreamOpen(stream);
    }
}

-(int) readIntoBuffer:(UInt8*)buffer withSize:(int)size
{
    int retval = (int)CFReadStreamRead(stream, buffer, size);
    
    if (retval > 0)
    {
        position += retval;
    }
    else
    {
        NSNumber* property = (__bridge_transfer NSNumber*)CFReadStreamCopyProperty(stream, kCFStreamPropertyFileCurrentOffset);
        
        position = property.longLongValue;
    }
    
    return retval;
}

-(void) seekToOffset:(SInt64)offset
{
    CFStreamStatus status = kCFStreamStatusClosed;
    
    if (stream != 0)
    {
        status = CFReadStreamGetStatus(stream);
    }
    
    BOOL reopened = NO;
    
    if (status == kCFStreamStatusAtEnd || status == kCFStreamStatusClosed || status == kCFStreamStatusError)
    {
        reopened = YES;
        
        [self close];
        [self open];
    }
    
    if (stream == 0)
    {
        CFRunLoopPerformBlock(eventsRunLoop.getCFRunLoop, NSRunLoopCommonModes, ^
                              {
                                  [self errorOccured];
                              });
        
        CFRunLoopWakeUp(eventsRunLoop.getCFRunLoop);
        
        return;
    }
    
    if (CFReadStreamSetProperty(stream, kCFStreamPropertyFileCurrentOffset, (__bridge CFTypeRef)[NSNumber numberWithLongLong:offset]) != TRUE)
    {
        position = 0;
    }
    else
    {
        position = offset;
    }
    
    if (!reopened)
    {
        CFRunLoopPerformBlock(eventsRunLoop.getCFRunLoop, NSRunLoopCommonModes, ^
                              {
                                  if ([self hasBytesAvailable])
                                  {
                                      [self dataAvailable];
                                  }
                              });
        
        CFRunLoopWakeUp(eventsRunLoop.getCFRunLoop);
    }
}

-(NSString*) description
{
    return [NSString stringWithFormat:@"StreamDataSource"];
}

@end
