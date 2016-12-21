//
//  Player.m
//  RecordAndPlay
//
//  Created by syx on 12/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Player.h"

@implementation Player
@synthesize m_viewController;
@synthesize flag;

-(void)startQueue{
     AudioQueueStart(audioQueue, NULL);

    for(int i=0;i<QUEUE_BUFFER_SIZE;i++)
    {
        AudioQueueAllocateBuffer(audioQueue, MIN_SIZE_PER_FRAME, &audioQueueBuffers[i]);
        [self readPCMAndPlay:audioQueue buffer:audioQueueBuffers[i]];
    }
}

- (void) stop
{
    AudioQueueStop(audioQueue, true);
}


- (void) pause
{
    AudioQueuePause(audioQueue);
}

- (id) init{
    self = [super init];
    if (self)  
    {
        [self initAudio];
    }
    return self;
}

-(void)initAudio 
{ 
    ///设置音频参数
    audioDescription.mSampleRate = 44100;//采样率
    audioDescription.mFormatID = kAudioFormatLinearPCM; 
    audioDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioDescription.mFramesPerPacket = 1;//每一个packet一侦数据
    audioDescription.mChannelsPerFrame = 1;///单声道
    audioDescription.mBitsPerChannel = 16;//每个采样点16bit量化     
    audioDescription.mBytesPerFrame = 2; 
    audioDescription.mBytesPerPacket = 2 ;

    AudioQueueNewOutput(&audioDescription, AudioPlayerAQInputCallback, (__bridge void * _Nullable)(self), nil, nil, 0, &audioQueue);//使用player的内部线程播 
  
    flag = TRUE;
    
} 
-(void)readPCMAndPlay:(AudioQueueRef)outQ buffer:(AudioQueueBufferRef)outQB{

    @synchronized(self.voiceDataQueue){
        if (self.voiceDataQueue.count <=0 && flag) {
            AudioQueueEnqueueBuffer(outQ, outQB, 0, NULL);
        }else if(self.voiceDataQueue.count > 0 && flag){
            NSData *myData  = [self.voiceDataQueue dequeue];
            Byte *pcmDataByte = (Byte *)myData.bytes;
            outQB->mAudioDataByteSize = (UInt32)myData.length;
            Byte *audiodata = (Byte *)outQB->mAudioData;
            for(int i=0;i<myData.length;i++)
            {
                audiodata[i] = pcmDataByte[i];
            }
            AudioQueueEnqueueBuffer(outQ, outQB, 0, NULL);
        }
    }
      

}
static void AudioPlayerAQInputCallback(void *input, AudioQueueRef outQ, AudioQueueBufferRef outQB) 
{ 
    Player *player = (__bridge Player *)input;
   [player readPCMAndPlay:outQ buffer:outQB];
    
} 

@end
