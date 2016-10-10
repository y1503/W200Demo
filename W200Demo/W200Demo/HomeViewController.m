//
//  HomeViewController.m
//  W200Demo
//
//  Created by 鱼鱼 on 16/9/27.
//  Copyright © 2016年 鱼鱼. All rights reserved.
//

#import "HomeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "Recorder.h"

@interface HomeViewController ()<UITableViewDelegate,UITableViewDataSource, UIGestureRecognizerDelegate,AVAudioPlayerDelegate>
@property (weak, nonatomic) IBOutlet UITextField *billCodeTF;
@property (weak, nonatomic) IBOutlet UILabel *messageLbl;
@property (weak, nonatomic) IBOutlet UIButton *clearBtn;
@property (weak, nonatomic) IBOutlet UITableView *mTableView;
@property (nonatomic, strong) UIButton *batteryBtn;//电池
@property (nonatomic, strong) AVAudioPlayer *movePlayer;
@property (nonatomic, strong) Recorder *mRecorder;
@property (nonatomic, strong) UIButton *scanBtn;//扫描按钮
@property (nonatomic, strong) NSMutableArray *billArr;
@property (nonatomic, assign) int bageValue;//记录当前电量
@property (nonatomic, strong) NSTimer *timer;//定时器

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.bageValue = -1;
    
    //耳机插入和拔出的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkHeadset) name:AVAudioSessionRouteChangeNotification object:nil];
    [self initViews];

//    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
//    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    __weak typeof(self)weakSelf = self;
    self.mRecorder = [[Recorder alloc] init];
    [self.mRecorder setCallHandle:^(NSString *codeStr) {
//        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
        [weakSelf playWordSound:@"beep100ms.wav"];
        weakSelf.billCodeTF.text = codeStr;
        [weakSelf.billArr addObject:codeStr];
        [weakSelf.mTableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    }];
    
    [self.mRecorder setCallHandleForBat:^(int value) {
        weakSelf.bageValue = value;
        [weakSelf.batteryBtn setImage:[UIImage imageNamed:[NSString stringWithFormat:@"charge%i", value]] forState:UIControlStateNormal];
        
        weakSelf.messageLbl.text = @"设备就绪";
        
    }];
    


//    NSArray* input = [[AVAudioSession sharedInstance] currentRoute].inputs;
//    NSArray* output = [[AVAudioSession sharedInstance] currentRoute].outputs;
//    NSLog(@"current intput:%@",input);
//    NSLog(@"current output:%@",output);
    
}

- (void)checkBageValue
{
    if (self.bageValue == -1) {
        self.messageLbl.text = @"请重新匹配W200设备";
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [self.mRecorder start];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.mRecorder stop];
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
}

#pragma mark -- 初始化视图
- (void)initViews
{
    [self setLeftView];
    [self setRightView];
    
    self.billCodeTF.layer.cornerRadius = 5;
    self.billCodeTF.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.billCodeTF.layer.borderWidth = 0.5;
    
    self.clearBtn.layer.cornerRadius = 10;
    [self.clearBtn addTarget:self action:@selector(clickedBtn:) forControlEvents:UIControlEventTouchUpInside];
    self.clearBtn.tag = 201;
    
    self.billArr = [NSMutableArray array];
    
    [self.mTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"HomeViewController"];
    
    self.scanBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    CGSize size = [UIScreen mainScreen].bounds.size;
    self.scanBtn.frame = CGRectMake((size.width-64)/2.0, size.height - 200, 64, 64);
    [self.scanBtn setBackgroundImage:[UIImage imageNamed:@"button_scan_red"] forState:UIControlStateNormal];
    [self.scanBtn addTarget:self action:@selector(clickedBtn:) forControlEvents:UIControlEventTouchUpInside];
    self.scanBtn.tag = 301;
    [self.view addSubview:self.scanBtn];
    //拖动手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(clickedPan:)];
    pan.delegate = self;
    [self.scanBtn addGestureRecognizer:pan];
    
    //开启后检测一次
    [self play:@"rsine500hz.wav"];
}


#pragma mark -- 设置左上角视图显示效果
- (void)setLeftView
{
    UIView *w200View = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 120, 44)];
    
    UIImageView *leftIV = [[UIImageView alloc] initWithFrame:CGRectMake(10, 7, 30, 30)];
    leftIV.image = [UIImage imageNamed:@"resize_music"];
    [w200View addSubview:leftIV];
    
    UILabel *leftLbl = [[UILabel alloc] initWithFrame:CGRectMake(45, 7, 75, 30)];
    leftLbl.text = @"W200_S";
    leftLbl.textColor = [UIColor whiteColor];
    leftLbl.font = [UIFont systemFontOfSize:17];
    [w200View addSubview:leftLbl];
    
    UIBarButtonItem *leftBtn = [[UIBarButtonItem alloc] initWithCustomView:w200View];
    self.navigationItem.leftBarButtonItem = leftBtn;
}

#pragma mark -- 设置右上角三个视图
- (void)setRightView
{
    //1.电池检测和显示按钮
    self.batteryBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.batteryBtn.frame = CGRectMake(0, 7, 30, 30);
    [self.batteryBtn setBackgroundImage:[UIImage imageNamed:@"charge0"] forState:UIControlStateNormal];
    [self.batteryBtn addTarget:self action:@selector(clickedBtn:) forControlEvents:UIControlEventTouchUpInside];
    self.batteryBtn.tag = 103;
     UIBarButtonItem *btn3 = [[UIBarButtonItem alloc] initWithCustomView:self.batteryBtn];
    //2.检测w200按钮
     UIBarButtonItem *btn2 = [[UIBarButtonItem alloc] initWithTitle:@"检测W200" style:UIBarButtonItemStylePlain target:self action:@selector(clickedBtn:)];
    btn2.tag = 102;
    //3.旋转屏幕按钮
    UIBarButtonItem *btn1 = [[UIBarButtonItem alloc] initWithTitle:@"屏幕旋转" style:UIBarButtonItemStylePlain target:self action:@selector(clickedBtn:)];
    btn1.tag = 101;
    self.navigationItem.rightBarButtonItems = @[btn1, btn2, btn3];
}

#pragma mark -- 各个按钮事件处理
- (void)clickedBtn:(UIBarButtonItem *)barBtn
{
    switch (barBtn.tag) {
        case 101://屏幕旋转
        {
            UIDevice *device = [UIDevice currentDevice];
            NSString *orientation = @"orientation";
            
            if ([[device valueForKey:orientation] intValue] == UIInterfaceOrientationPortraitUpsideDown) {
                NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
                [device setValue:value forKey:orientation];
            }else{
                NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortraitUpsideDown];
                [device setValue:value forKey:orientation];
            }

        }
            break;
        case 102://检测W200
        {
            [self checkHeadset];
        }
            break;
        case 103://检测电量
        {
            
        }
            break;
        case 201://清空
        {
            [self.billArr removeAllObjects];
            [self.mTableView reloadData];
        }
            break;
        case 301://扫描条码
        {
//            [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
            [self play:@"rsine4khz.wav"];
//            AudioServicesPlayAlertSound(kSystemSoundzID_Vibrate);

        }
            break;
            
        default:
            break;
    }
}


#pragma mark -- 耳机插拔动作的通知响应方法
- (void)checkHeadset
{
    if ([self isHeadsetPluggedIn]) {
        //检测到设备插入检测一次
        [self play:@"rsine500hz.wav"];
        self.messageLbl.text = @"匹配W200设备...";
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkBageValue) userInfo:nil repeats:NO];
        
    }else{
        NSLog(@"耳机拔出");
        self.messageLbl.text = @"未插入W200";
        [self.batteryBtn setImage:[UIImage imageNamed:@"charge0"] forState:UIControlStateNormal];
    }
}

#pragma mark -- 检测耳机是否插入
- (BOOL)isHeadsetPluggedIn {
    AVAudioSessionRouteDescription *route = [[AVAudioSession sharedInstance] currentRoute];
    NSArray *arrary = [route outputs];
    for (AVAudioSessionPortDescription *desc in arrary) {
        if ([desc.portType isEqualToString:AVAudioSessionPortHeadphones])
        {
            return YES;
        }
    }
    return NO;
}


#pragma mark -- 播放声音
-(void) playWordSound:(NSString *)soundName
{
    [self.mRecorder stop];
    SystemSoundID soundId;
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:soundName ofType:nil];
    if (soundPath == nil) {
        return;
    }
    NSURL *url = [NSURL fileURLWithPath:soundPath];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(url), &soundId);
    //区别在于系统声音调用
//    AudioServicesPlaySystemSound(soundId);
    //而提醒音调用
    AudioServicesPlayAlertSound(soundId);//这个方法会触发震动
    
    
    AudioServicesAddSystemSoundCompletion(soundId, NULL, NULL, completionCallback, (__bridge void * _Nullable)(self.mRecorder));
}

#pragma mark -- 播放声音结束后的回调函数
static void completionCallback (SystemSoundID  mySSID, void* data)
{//data,这个data就是AudioServicesAddSystemSoundCompletion最后一个参数
    NSLog(@"completion Callback");
    AudioServicesRemoveSystemSoundCompletion (mySSID);
    AudioServicesDisposeSystemSoundID(mySSID);
    Recorder *recorder = (__bridge Recorder *)data;
   [recorder start];
}

- (void)play:(NSString *)soundName
{
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:soundName ofType:nil];
    if (soundPath == nil) {
        return;
    }
    NSURL *url = [NSURL fileURLWithPath:soundPath];
    NSError *err = nil;
    self.movePlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
    self.movePlayer.volume = 1.0;
    self.movePlayer.delegate = self;
    [self.movePlayer prepareToPlay];
    if (err!=nil) {
        NSLog(@"move player init error:%@",err);
    }else {
        [self.movePlayer play];
    }
}


#pragma mark -- UITableViewDelegate,UITableViewDataSource method
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.billArr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HomeViewController" forIndexPath:indexPath];
    cell.textLabel.text = self.billArr[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -- 响应手势拖动
- (void)clickedPan:(UIPanGestureRecognizer *)pan
{
    CGPoint point = [pan locationInView:self.view];
    CGRect frame = self.scanBtn.frame;
    
    self.scanBtn.center = point;
    
    if (CGRectIntersectsRect(self.scanBtn.frame, self.view.frame) == NO) {
        self.scanBtn.frame = frame;//如果按钮超出了边界，就不让它继续移动
    }
    
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    
}

@end
