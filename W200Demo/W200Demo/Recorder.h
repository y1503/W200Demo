//
//  Recorder.h
//  RecordAndPlay
//
//  Created by syx on 12/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>


// Audio Settings

#define kNumberBuffers      3
#define t_sample            SInt16
#define kSamplingRate       44100
#define kNumberChannels     1
#define kBitsPerChannels    (sizeof(t_sample) * 8)
#define kBytesPerFrame      (kNumberChannels * sizeof(t_sample))
#define kFrameSize          1000

typedef struct AQCallbackStruct

{
    AudioStreamBasicDescription mDataFormat;
    AudioQueueRef               queue;
    AudioQueueBufferRef         mBuffers[kNumberBuffers];
//    AudioFileID                 outputFile;
    SInt32                      frameSize;
//    long long                   recPtr;
    int                         run;
    
} AQCallbackStruct;

typedef enum
{
    Operation_Type_Unknow = 0,
    Operation_Type_Code = 0x01,//条码
    Operation_Type_Battery = 0x0D,//电量
}Operation_Type;

@class Recorder;
@protocol RecorderDelegate <NSObject>

@optional
//获取到数据，音频解析完成
- (void)parserFinishedFromRecorder:(Recorder *)recorder;
//音频转码后的数据解析完成
/*
 type:数据类型
 data:数据
 */
//收到新数据
- (void)sendFromRecorder:(Recorder *)recorder type:(Operation_Type)type byteData:(unsigned char *)byteData dataLenth:(unsigned char)dataLenth;
//收到确认信息
- (void)receiveFromRecorder:(Recorder *)recorder type:(Operation_Type)type byteData:(unsigned char *)byteData dataLenth:(unsigned char)dataLenth;
@end

@class ViewController;
@interface Recorder : NSObject{
    AQCallbackStruct aqc;
    AudioFileTypeID fileFormat;
}

@property (nonatomic, assign) AQCallbackStruct aqc;
@property (nonatomic, weak) id<RecorderDelegate>delegate;


- (id) init;
- (void) start;
- (void) stop;
- (void) pause;
- (void) processAudioBuffer:(AudioQueueBufferRef) buffer withQueue:(AudioQueueRef) queue;
@end
