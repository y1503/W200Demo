//
//  Player.h
//  RecordAndPlay
//
//  Created by syx on 12/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "NSQueue.h"

#define QUEUE_BUFFER_SIZE 3//队列缓冲个数 
#define EVERY_READ_LENGTH 1000 //每次从文件读取的长度 
#define MIN_SIZE_PER_FRAME 1000 //每侦最小数据长度 

@class ViewController;
@interface Player : NSObject{
    AudioStreamBasicDescription audioDescription;
    AudioQueueRef audioQueue;
    AudioQueueBufferRef audioQueueBuffers[QUEUE_BUFFER_SIZE];

    Byte *pcmDataBuffer;
    ViewController *m_viewController;
    
    BOOL flag;
}
@property (nonatomic, strong) ViewController *m_viewController;
@property (nonatomic, assign)  BOOL flag;
@property(nonatomic, strong) NSQueue *voiceDataQueue;

static void AudioPlayerAQInputCallback(void *input, AudioQueueRef inQ, AudioQueueBufferRef outQB); 
-(void)readPCMAndPlay:(AudioQueueRef)outQ buffer:(AudioQueueBufferRef)outQB;
-(void)startQueue;
-(void)initAudio;
- (id) init;
- (void) stop;
- (void) pause;
@end
