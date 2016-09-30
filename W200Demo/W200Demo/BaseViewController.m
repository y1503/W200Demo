//
//  BaseViewController.m
//  JinHeApp
//
//  Created by dd on 14-8-20.
//  Copyright (c) 2014年 Ice-Soft. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()

@end

@implementation BaseViewController


#pragma mark - Life Cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.view.frame = [UIScreen mainScreen].bounds;
    [self.view setBackgroundColor:[UIColor whiteColor]];
    UINavigationBar *bar = self.navigationController.navigationBar;
    [bar setBarStyle:UIBarStyleDefault];
    bar.translucent = NO;
    

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        self.navigationController.navigationBar.translucent = NO;
        self.tabBarController.tabBar.translucent = NO;
        
    }
    
    bar.tintColor = [UIColor whiteColor];
    bar.barTintColor = [UIColor blackColor];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
}


-(void)addZTOImage:(NSString *)imageName{
 
    UIImageView* titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    self.navigationItem.titleView = titleView;
    
}

-(void)addZtoTitle:(NSString *)title{
    
    UILabel* labelView = [[UILabel alloc] initWithFrame:CGRectMake(85, 0, 150, 44)];
    [labelView setFont:[UIFont systemFontOfSize:16]];
    labelView.text = title;
    labelView.textColor = [UIColor whiteColor];
    labelView.textAlignment = NSTextAlignmentCenter;
    self.navigationItem.titleView = labelView;
    self.title = title;
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
