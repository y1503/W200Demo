//
//  BaseViewController.h
//  JinHeApp
//
//  Created by dd on 14-8-20.
//  Copyright (c) 2014年 Ice-Soft. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BaseViewController : UIViewController

@property (nonatomic, copy) void (^callback)(void) ;

-(void)addZTOImage:(NSString *)imageName;
- (void)addZtoTitle:(NSString*)title;

@end
