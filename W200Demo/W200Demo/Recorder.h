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

/* 封包起始和结尾字节 */
typedef NS_ENUM(Byte, COMM_PAKET) {
    
    COMM_PAKET_START_BYTE = 0x40,
    COMM_PAKET_END_BYTE   = 0x2A,
    COMM_PAKET1_END_BYTE  = 0xA2,
};

/* 收发类型 */
typedef NS_ENUM(Byte, COMM_TRANS_TYPE) {
    
    COMM_TRANS_TYPE_SEND = (0x53),/* 'S'---send */
    COMM_TRANS_TYPE_RESP = (0x52),/* 'R'---response */
};


typedef NS_ENUM(Byte, COMM_CMD_TYPE)
{
    COMM_CMD_TYPE_Unknow    = 0,
    COMM_CMD_TYPE_Code = 0x01,//条码
    COMM_CMD_TYPE_Battery   = 0x0D,//电量
    
    COMM_CMD_TYPE_UPDATE    = 0xD0,//软件升级
    COMM_CMD_TYPE_VOICE		= 0xD1,//语音数据传输
    COMM_CMD_TYPE_DONGLE_SN	= 0xD2,//dongle序列号
    COMM_CMD_TYPE_TOUCH		= 0xDF,//touch数据
    COMM_CMD_TYPE_VERSION   = 0xE0,//R11版本信息
};


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
- (void)sendFromRecorder:(Recorder *)recorder type:(COMM_CMD_TYPE)type byteData:(unsigned char *)byteData dataLenth:(unsigned char)dataLenth;
//收到确认信息
- (void)receiveFromRecorder:(Recorder *)recorder type:(COMM_CMD_TYPE)type byteData:(unsigned char *)byteData dataLenth:(unsigned char)dataLenth;
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
