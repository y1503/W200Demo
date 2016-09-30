//
//  RootViewController.m
//  W200Demo
//
//  Created by 鱼鱼 on 16/9/27.
//  Copyright © 2016年 鱼鱼. All rights reserved.
//

#import "RootViewController.h"
#import "HomeViewController.h"

@interface RootViewController ()

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //设置导航栏文字统一为白色
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor], NSFontAttributeName : [UIFont systemFontOfSize:16]}];
    //设置顶部按钮字体大小
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14]} forState:UIControlStateNormal];
    
    HomeViewController *homeVC = [[HomeViewController alloc] init];
    UINavigationController *naVC = [[UINavigationController alloc] initWithRootViewController:homeVC];
    //设置导航栏字体未白色
    naVC.navigationBar.tintColor = [UIColor whiteColor];
    //设置导航栏背景为黑色
    naVC.navigationBar.barTintColor = [UIColor blackColor];
    
    [self.view addSubview:naVC.view];
    [self addChildViewController:naVC];
    
}

#pragma mark -- 适配屏幕旋转
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait|UIInterfaceOrientationMaskPortraitUpsideDown;
}


@end
