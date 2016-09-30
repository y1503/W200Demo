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
    AudioFileID                 outputFile;
    SInt32                      frameSize;
    long long                   recPtr;
    int                         run;
    
} AQCallbackStruct;

typedef enum
{
    Operation_Type_Unknow = 0,
    Operation_Type_Code = 0x01,//条码
    Operation_Type_Battery = 0x0D,//电量
}Operation_Type;


@class ViewController;
@interface Recorder : NSObject{
    AQCallbackStruct aqc;
    AudioFileTypeID fileFormat;
}
@property (nonatomic, assign) AQCallbackStruct aqc;
@property (nonatomic , copy) void(^callHandle)(NSString *code);
@property (nonatomic , copy) void(^callHandleForBat)(int value);

- (id) init;
- (void) start;
- (void) stop;
- (void) pause;
- (void) processAudioBuffer:(AudioQueueBufferRef) buffer withQueue:(AudioQueueRef) queue;
@end
