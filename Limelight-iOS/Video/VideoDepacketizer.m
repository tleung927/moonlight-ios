//
//  VideoDepacketizer.m
//  Limelight-iOS
//
//  Created by Diego Waxemberg on 1/18/14.
//  Copyright (c) 2014 Diego Waxemberg. All rights reserved.
//

#import "VideoDepacketizer.h"

@implementation VideoDepacketizer
static int BUFFER_LENGTH = 131072;

- (id)initWithFile:(NSString *)file renderTarget:(UIView*)renderTarget
{
    self = [super init];
    self.file = file;
    self.target = renderTarget;
    return self;
}

- (void)main
{
    NSLog(@"Allocating input stream\n");
    NSInputStream* inStream = [[NSInputStream alloc] initWithFileAtPath:self.file];
    NSLog(@"Allocating byteBuffer");
    self.byteBuffer = malloc(BUFFER_LENGTH);
    NSLog(@"byte pointer: %p", self.byteBuffer);
    [inStream setDelegate:self];
    
    NSLog(@"Allocating decoder");
    self.decoder = [[VideoDecoder alloc]init];
    NSLog(@"old self pointer: %p", self);
    
    [inStream open];
    while ([inStream streamStatus] != NSStreamStatusOpen) {
        NSLog(@"stream status: %d", [inStream streamStatus]);
        sleep(1);
    }
    while ([inStream streamStatus] != NSStreamStatusAtEnd)
    {
        unsigned int len = 0;
        //NSLog(@"Reading File\n");
        //NSLog(@"stream pointer: %p", inStream);
        //NSLog(@"self pointer: %p", self);
        //NSLog(@"byte buffer pointer: %p", self.byteBuffer);
        len = [(NSInputStream *)inStream read:self.byteBuffer maxLength:BUFFER_LENGTH];
        if (len)
        {
            BOOL firstStart = false;
            for (int i = 0; i < len - 4; i++) {
                self.offset++;
                if (self.byteBuffer[i] == 0 && self.byteBuffer[i+1] == 0
                    && self.byteBuffer[i+2] == 0 && self.byteBuffer[i+3] == 1)
                {
                    if (firstStart)
                    {
                        // decode the first i-1 bytes
                        [self.decoder decode:self.byteBuffer length:i];
                        [self renderFrame];
                        [inStream setProperty:[[NSNumber alloc] initWithInt:self.offset-4] forKey:NSStreamFileCurrentOffsetKey];
                        self.offset -= 1;
                        
                        break;
                    } else
                    {
                        firstStart = true;
                    }
                }
            }
        }
        else
        {
            NSLog(@"No Buffer!");
        }
    }

}

- (void) renderFrame
{
    [self.target performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:NULL waitUntilDone:FALSE];
}

@end
