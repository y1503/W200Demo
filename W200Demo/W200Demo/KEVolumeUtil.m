//
//  KEVolumeUtil.m
//  W200Demo
//
//  Created by 鱼鱼 on 2016/10/27.
//  Copyright © 2016年 鱼鱼. All rights reserved.
//

#import "KEVolumeUtil.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@interface KEVolumeUtil()

@property (nonatomic, strong) MPVolumeView *mpVolumeView;

@property (nonatomic, strong) UISlider *slider;

@end

@implementation KEVolumeUtil

@synthesize volumeValue = _volumeValue;

#pragma mark public methods
+(KEVolumeUtil *) shareInstance
{
    static KEVolumeUtil *instance = nil;
    static dispatch_once_t predicate;
    dispatch_once (&predicate, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void) loadMPVolumeView
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self.mpVolumeView];

//    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];
    
}

- (void)registerVolumeChangeEvent
{
    NSError *error;
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChangedNotification:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
}

- (void)unregisterVolumeChangeEvent
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
}

#pragma mark private methods
-(void) generateMPVolumeSlider
{
    for (UIView *view in [self.mpVolumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            self.slider = (UISlider*)view;
            break;
        }
    }
}

#pragma mark setters
-(void) setVolumeValue:(CGFloat) newValue
{
    _volumeValue = newValue;
    
    //确保self.slider ！= nil
    if (!self.slider) {
        [self generateMPVolumeSlider];
    }
    self.slider.value = newValue;
}

#pragma mark getters
-(CGFloat) volumeValue
{
    //确保self.slider ！= nil
    if (!self.slider) {
        [self generateMPVolumeSlider];
    }
    return self.slider.value;
}

-(MPVolumeView *) mpVolumeView
{
    if (!_mpVolumeView) {
        _mpVolumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(0, 50, 100, 100)];
        _mpVolumeView.hidden = YES;
    }
    return _mpVolumeView;
}

#pragma mark notification
- (void)volumeChangedNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    float value = [[userInfo objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    self.volumeValue = value;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:Volume_Change_Notification object:nil];
}

@end
