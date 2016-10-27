//
//  KEVolumeUtil.h
//  W200Demo
//
//  Created by 鱼鱼 on 2016/10/27.
//  Copyright © 2016年 鱼鱼. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define Volume_Change_Notification @"Volume_Change_Notification"

@interface KEVolumeUtil : NSObject

@property (nonatomic,assign) CGFloat volumeValue;

+ (KEVolumeUtil *) shareInstance;

-(void)loadMPVolumeView;

- (void)registerVolumeChangeEvent;

- (void)unregisterVolumeChangeEvent;

@end
