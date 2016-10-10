//
//  Recorder.m
//  RecordAndPlay
//
//  Created by syx on 12/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Recorder.h"
#import "jiema.h"

@implementation Recorder
@synthesize aqc;

static void AQInputCallback (void * __nullable       inUserData,
                             AudioQueueRef          inAudioQueue,
                             AudioQueueBufferRef    inBuffer,
                             const AudioTimeStamp   * inStartTime,
                             UInt32          inNumPackets,
                             const AudioStreamPacketDescription * __nullable inPacketDesc)

{
    
    Recorder * engine = (__bridge Recorder *) inUserData;
    if (inNumPackets > 0)  
    {
        [engine processAudioBuffer:inBuffer withQueue:inAudioQueue]; 
    }
    
    if (engine.aqc.run)  
    {
        AudioQueueEnqueueBuffer(engine.aqc.queue, inBuffer, 0, NULL);//把处理后的buf插入到缓存队列中
    }
    
}
 
- (id)init
{
    if (self = [super init])
    {
        
        memset(&aqc.mDataFormat, 0, sizeof(aqc.mDataFormat));
        
        aqc.mDataFormat.mSampleRate = 44100;// 采样率 (立体声 = 8000)
        aqc.mDataFormat.mFormatID = kAudioFormatLinearPCM;//PCM格式
        aqc.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        aqc.mDataFormat.mFramesPerPacket = 1;
        aqc.mDataFormat.mChannelsPerFrame = 1;//1:单声道；2:立体声
        aqc.mDataFormat.mBitsPerChannel = 16;//语音每采样点占用位数,语音每采样点占用位数,比特率 8 16 24 32
        aqc.mDataFormat.mBytesPerFrame = 2;
        aqc.frameSize = kFrameSize;//缓存队列中buf的大小
        aqc.mDataFormat.mBytesPerPacket = aqc.mDataFormat.mBytesPerFrame * aqc.mDataFormat.mFramesPerPacket;
        
        AudioQueueNewInput(&aqc.mDataFormat, AQInputCallback, (__bridge void * _Nullable)(self), NULL, kCFRunLoopCommonModes, 0, &aqc.queue);
        
        
        //        aqc.recPtr = 0;
        aqc.run = 1;
        
        AudioQueueSetParameter (aqc.queue,kAudioQueueParam_Volume,1.0);//设置音量

        
        for (int i=0;i<kNumberBuffers;i++)
        {
            //创建缓存buf
            AudioQueueAllocateBuffer(aqc.queue, aqc.frameSize, &aqc.mBuffers[i]);
            //把创建好的buf添加到缓存队列中取
            AudioQueueEnqueueBuffer(aqc.queue, aqc.mBuffers[i], 0, NULL);
        }
        UInt32 size = sizeof(UInt32) ;
        UInt32 enableLevelMetering = 1 ;
        
        AudioQueueSetProperty(aqc.queue, kAudioQueueProperty_EnableLevelMetering, &enableLevelMetering, size ) ;
        
        
        int status = AudioQueueStart(aqc.queue, NULL);
        NSLog(@"AudioQueueStart = %d", status);
        
    }
    
    return self;
}

- (void) dealloc
{
    AudioQueueStop(aqc.queue, true);
    
    aqc.run = 0;
    
    AudioQueueDispose(aqc.queue, true);
    
}

- (void) start
{
    AudioQueueStart(aqc.queue, NULL);
}

- (void) stop
{
    AudioQueueStop(aqc.queue, true);
}


- (void) pause
{
    AudioQueuePause(aqc.queue);
}


- (void) processAudioBuffer:(AudioQueueBufferRef) buffer withQueue:(AudioQueueRef) queue
{
    long size = buffer->mAudioDataByteSize;
    
    t_sample * data = (t_sample *) buffer->mAudioData;
    
    unsigned char retBuf[128];
    
    int ret = audioInterface_wav2digital(data, (int)size/2, retBuf);
    
    if (ret) {
        NSLog(@"解码结果:%d", ret);
        [self jiebao:retBuf length:ret];
        
    }
    
    
    //    [self.outFile writeData:codeData];
    
    
//    [codeData release];
}
//“起始”			帧头。0x40
//“帧长度”	该长度从“收发类型”字段开始（含“收发类型”字段），至“数据”字段结束（含“数据”字段）。
//“收发类型”	   指是收到的数据是返回确认信息还是新的数据信息（’R’表示收到确认信息，’S’表示收到是新的数据，需要处理。）
//“指令类型”	为指令编码，方便通信相互通讯的一一对应
//“数据”	最小1个字节，最大253个字节的任意数据。
//“校验”		“帧长度”开始“数据”为止所有的全字节的总和的低8位
//“终止”			非固定长度标准协议的“终止”字段固定为1个字节：0x2A。


#pragma mark -- 解包
- (void)jiebao:(unsigned char *)dataBuf length:(int)length
{
    if (length < 7) {//最小包长度为7，所以不够一个包直接返回
        return;
    }
    
    int i = 0;
    while (i < length) {
        if (dataBuf[i] == 0x40 && ++i < length) {//包的头，当前指向帧长度位
            int frameLength = dataBuf[i];//帧长度
            if (i + frameLength + 2 < length && dataBuf[i + frameLength + 2] == 0x2A) {//判断剩下的长度是否够一个完整的包
                //检验校验位是否正确
                int total = 0;
                for (int j = 0; j < frameLength + 1; j++) {
                    total += dataBuf[j+i];
                }
                
                int a = total&0xff;
                int b = dataBuf[i + frameLength + 1];
                
                if (a == b) {//校验通过
                    char type = dataBuf[i+1];//获取收发类型
                    switch (type) {
                        case 'R'://收到确认信息
                        {
                            NSLog(@"收");
                            [self send:dataBuf[i+2] data:dataBuf+i+2+1 dataLenght:frameLength-2];
                        }
                            break;
                        case 'S'://收到是新的数据
                        {
                            [self send:dataBuf[i+2] data:dataBuf+i+2+1 dataLenght:frameLength-2];
                        }
                            break;
                            
                        default:
                            break;
                    }
                }
                
                i += i + frameLength + 2;
            }
        }
        i++;
    }
}

- (void)send:(Operation_Type)type data:(unsigned char *)data dataLenght:(int)length
{
    switch (type) {
        case Operation_Type_Code://条码指令
        {
            NSString *codeStr = [[NSString alloc] initWithBytes:data length:length encoding:NSUTF8StringEncoding];
            NSLog(@"扫描出来的条码：%@", codeStr);
            if (self.callHandle) {
                self.callHandle(codeStr);
            }
        }
            break;
        case Operation_Type_Battery://电量获取
        {
            NSLog(@"电量值：%d", data[0]);
            if (self.callHandleForBat) {
                self.callHandleForBat(data[0]/10 + 1);
            }
        }
            break;
            
        default:
            break;
    }
}

@end
