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
#import <sys/utsname.h>
#import "UIDevice+DeviceModel.h"
#import <MediaPlayer/MediaPlayer.h>
#import "KEVolumeUtil.h"
#import "Player.h"
#import "wavemake.h"


void printByteArr(Byte *bytes ,int lenth)
{
    for (int i = 0; i < lenth; i++) {
        NSLog(@"0x%02X", bytes[i]);
    }
}

int WriteComm(Byte bytes[],int length){
    int wavelen =0;
    Byte wavedata[48000*2];
    //Log.d("转换元数据","转换元数据start");
    int count = wavemake(bytes,length,wavedata,wavelen);
    //获取到wav数据后就可以播放出去了
    if (count > 0) {
        
        NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        filePath = [filePath stringByAppendingPathComponent:@"image.wav"];
        
        NSData *data = [NSData dataWithBytes:wavedata length:count];
        [data writeToFile:filePath atomically:YES];
        
    }
    
    return 0;
}




//“起始”			帧头。0x40
//“帧长度”	该长度从“收发类型”字段开始（含“收发类型”字段），至“数据”字段结束（含“数据”字段）。
//“收发类型”	   指是收到的数据是返回确认信息还是新的数据信息（’R’表示收到确认信息，’S’表示收到是新的数据，需要处理。）
//“指令类型”	为指令编码，方便通信相互通讯的一一对应
//“数据”	最小1个字节，最大253个字节的任意数据。
//“校验”		“帧长度”开始“数据”为止所有的全字节的总和的低8位
//“终止”			非固定长度标准协议的“终止”字段固定为1个字节：0x2A。



@interface HomeViewController ()<UITableViewDelegate,UITableViewDataSource, UIGestureRecognizerDelegate,AVAudioPlayerDelegate,RecorderDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *billCodeTF;
@property (weak, nonatomic) IBOutlet UILabel *messageLbl;
@property (weak, nonatomic) IBOutlet UIButton *clearBtn;
@property (weak, nonatomic) IBOutlet UITableView *mTableView;
@property (nonatomic, strong) UIButton *batteryBtn;//电池
@property (nonatomic, strong) AVAudioPlayer *scanPlayer;//扫描条码用
@property (nonatomic, strong) AVAudioPlayer *checkBagePlayer;//检测电量用
@property (nonatomic, strong) AVAudioPlayer *pcmWavPlayer;//播放转成pcm的wav数据
@property (nonatomic, strong) Recorder *mRecorder;
@property (nonatomic, strong) UIButton *scanBtn;//扫描按钮
@property (nonatomic, strong) NSMutableArray *billArr;
@property (nonatomic, assign) int bageValue;//记录当前电量
@property (nonatomic, strong) NSTimer *timer;//定时器
@property (nonatomic, strong) NSString *deviceStr;//记录当前手机的型号
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, assign) float volume;//保存当前的音量
@property (nonatomic, strong) Player *player;
@end

@implementation HomeViewController
{
    SystemSoundID soundId;
}

- (void)viewDidLoad {
    [super viewDidLoad];

//    NSQueue *queue = [[NSQueue alloc] init];
//    
//    self.player = [[Player alloc] init];
//    self.player.voiceDataQueue = queue;
//    [self.player startQueue];
    
    
    self.bageValue = -1;
    
    //耳机插入和拔出的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkHeadset) name:AVAudioSessionRouteChangeNotification object:nil];
    [self initViews];

    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    [self.mRecorder start];

    self.deviceStr = [[UIDevice currentDevice] deviceModel];
    NSLog(@"手机型号：%@", self.deviceStr);

//    NSArray* input = [[AVAudioSession sharedInstance] currentRoute].inputs;
//    NSArray* output = [[AVAudioSession sharedInstance] currentRoute].outputs;
//    NSLog(@"current intput:%@",input);
//    NSLog(@"current output:%@",output);
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(checkBageValue:) userInfo:nil repeats:YES];
    self.timer.fireDate = [NSDate distantFuture];
    
    self.queue = [NSOperationQueue mainQueue];
    self.queue.maxConcurrentOperationCount = 1;
    
    
     [self setVolumeValue];
//    [[KEVolumeUtil shareInstance] setVolumeValue:1.0];
    
    //进来先检测一次
    [self checkHeadset];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterForegroundOrBackground:) name:@"ForegroundOrBackground" object:nil];
}

- (void)enterForegroundOrBackground:(NSNotification *)notification
{
    switch ([notification.object intValue]) {
        case 0://进入后台
        {
            [self.mRecorder pause];
        }
            break;
        case 1://进入前台
        {
            [self.mRecorder start];
        }
            break;
            
        default:
            break;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            NSLog(@"获取到mic访问权限");
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"请开启允许【W200】访问您的麦克风" delegate:self cancelButtonTitle:@"忽略" otherButtonTitles:@"去开启", nil];
            [alert show];
        }
    }];
}

- (void)setVolumeValue
{
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [self.view addSubview:volumeView];
//    volumeView.hidden = YES;
    UISlider* volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if (view.class == NSClassFromString(@"MPVolumeSlider")){
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }

    // retrieve system volume
//    float systemVolume = volumeViewSlider.value;
//    if (systemVolume < 1.0) {
//        MPMusicPlayerController *mp = [MPMusicPlayerController applicationMusicPlayer];
//        mp.volume = 1.0;//0为最小1为最大
//    }
    
//    NSLog(@"系统当前音量：%f", systemVolume);
    
    [volumeViewSlider setValue:1.0 animated:YES];
    
    
    // send UI control event to make the change effect right now.
//    [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
}


- (void)volumeChanged:(NSNotification *)notification
{
    
}


- (void)checkBageValue:(NSTimer *)timer
{
    if (self.bageValue == -1) {
        self.messageLbl.text = @"请重新匹配W200设备";
    }else if ([self.messageLbl.text isEqualToString:@"匹配W200设备..."]){
        [self.checkBagePlayer play];
    }
    timer.fireDate = [NSDate distantFuture];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
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
    self.scanBtn.frame = CGRectMake((size.width-64)/2.0, size.height - 200, 100, 100);
    [self.scanBtn setTitle:@"扫描" forState:UIControlStateNormal];
    [self.scanBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.scanBtn setBackgroundImage:[UIImage imageNamed:@"button_blue"] forState:UIControlStateNormal];
    [self.scanBtn setBackgroundImage:[UIImage imageNamed:@"button_green"] forState:UIControlStateSelected];
    
    [self.scanBtn addTarget:self action:@selector(clickedBtn:) forControlEvents:UIControlEventTouchUpInside];
    self.scanBtn.tag = 301;
    [self.view addSubview:self.scanBtn];
    //拖动手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(clickedPan:)];
    pan.delegate = self;
    [self.scanBtn addGestureRecognizer:pan];
    
    //开启后检测一次
    [self.checkBagePlayer play];
//    [self playCheckBage];
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
            [self checkVersion];
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
            self.scanBtn.selected = YES;
            
            //[[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
            [self.scanPlayer play];
//            [self playScan];
        }
            break;
            
        default:
            break;
    }
}


#pragma mark -- 耳机插拔动作的通知响应方法
- (void)checkHeadset
{
    [self.queue addOperationWithBlock:^{
        if ([self isHeadsetPluggedIn]) {
            //检测到设备插入检测一次
            [self.checkBagePlayer play];
//            [self playCheckBage];
            if (self.bageValue == -1) {
                self.messageLbl.text = @"匹配W200设备...";
                self.timer.fireDate = [NSDate dateWithTimeIntervalSinceNow:5];
            }
            
        }else{
            NSLog(@"耳机拔出");
            self.messageLbl.text = @"未插入W200";
            [self.batteryBtn setImage:[UIImage imageNamed:@"charge0"] forState:UIControlStateNormal];
            self.bageValue = -1;
        }
        
        self.scanBtn.selected = NO;
    }];
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
    if (soundId == 0) {
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:soundName ofType:nil];
        if (soundPath == nil) {
            return;
        }
        NSURL *url = [NSURL fileURLWithPath:soundPath];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)(url), &soundId);
    }
    
    //区别在于系统声音调用
//    AudioServicesPlaySystemSound(soundId);
    //而提醒音调用
    AudioServicesPlayAlertSound(soundId);//这个方法会触发震动
    
    AudioServicesAddSystemSoundCompletion(soundId, NULL, NULL, completionCallback, (__bridge void * _Nullable)(self.mRecorder));
}

#pragma mark -- 播放声音结束后的回调函数
static void completionCallback (SystemSoundID  mySSID, void* data)
{//data,这个data就是AudioServicesAddSystemSoundCompletion最后一个参数
//    NSLog(@"completion Callback");
//    AudioServicesRemoveSystemSoundCompletion (mySSID);
//    AudioServicesDisposeSystemSoundID(mySSID);
    Recorder *recorder = (__bridge Recorder *)data;
    [recorder start];
}

#pragma mark -- 震动
- (void)playShake
{//由于实时录音时，无法播放震动，故而先暂停一下
    [self.mRecorder stop];
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    if ([self.deviceStr isEqualToString:Device_iPhone5]) {
        [self.mRecorder performSelector:@selector(start) withObject:nil afterDelay:0.01];
    }else{
        [self.mRecorder performSelector:@selector(start) withObject:nil afterDelay:0.001];
    }
    
}

extern void AudioServicesPlaySystemSoundWithVibration(int, id, id);
#pragma mark -- 私有API控制震动时间,单位毫秒
- (void)playShakeWithMS:(int)ms
{
    [self.mRecorder stop];
    
    if (ms < 0) {
        ms = 0;
    }
    
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    NSMutableArray* arr = [NSMutableArray array];

    [arr addObject:[NSNumber numberWithBool:YES]]; //vibrate for 2000ms
    [arr addObject:[NSNumber numberWithInt:ms]];


    [dict setObject:arr forKey:@"VibePattern"];
    [dict setObject:[NSNumber numberWithFloat:0.3] forKey:@"Intensity"];

    AudioServicesPlaySystemSoundWithVibration(4095,nil, dict);
    
    [self.mRecorder performSelector:@selector(start) withObject:nil afterDelay:ms/1000.0f];
}

#pragma mark -- 懒加载录音对象
- (Recorder *)mRecorder
{
    if (_mRecorder == nil) {
        _mRecorder = [[Recorder alloc] init];
        _mRecorder.delegate = self;
    }
    return _mRecorder;
}

#pragma mark -- 懒加载扫描播放器
- (AVAudioPlayer *)scanPlayer
{
    if (_scanPlayer == nil) {
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"rsine4khz.wav" ofType:nil];
        NSURL *url = [NSURL fileURLWithPath:soundPath];
        NSError *err = nil;
        _scanPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
        _scanPlayer.volume = 1.0;
        _scanPlayer.delegate = self;
        [_scanPlayer prepareToPlay];
        if (err != nil) {
            NSLog(@"scan player init error:%@",err);
            _scanPlayer = nil;
        }
    }
    
    return _scanPlayer;
}

#pragma mark -- 懒加载电量检测播放器
- (AVAudioPlayer *)checkBagePlayer
{
    if (_checkBagePlayer == nil) {
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"rsine500hz.wav" ofType:nil];
        NSURL *url = [NSURL fileURLWithPath:soundPath];
        NSError *err = nil;
        _checkBagePlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
        _checkBagePlayer.volume = 1.0;
        _checkBagePlayer.delegate = self;
        [_checkBagePlayer prepareToPlay];
        if (err != nil) {
            NSLog(@"scan player init error:%@",err);
            _checkBagePlayer = nil;
        }
    }
    
    return _checkBagePlayer;
}

#pragma mark - RecorderDelegate method
- (void)parserFinishedFromRecorder:(Recorder *)recorder
{
    
}

//#pragma mark -- 播放触发出光的音频
//- (void)playScan
//{
//    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"rsine4khz.wav" ofType:nil];
//    self.player = [[playAudio alloc] initWithAudio:soundPath];
//}
//
//#pragma mark -- 播放触发出光的音频
//- (void)playCheckBage
//{
//    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"rsine500hz.wav" ofType:nil];
//    self.player = [[playAudio alloc] initWithAudio:soundPath];
//}


- (void)sendFromRecorder:(Recorder *)recorder type:(COMM_CMD_TYPE)type byteData:(unsigned char *)byteData dataLenth:(unsigned char)dataLenth
{
    switch (type) {
        case COMM_CMD_TYPE_Code://条码
        {
            self.scanBtn.selected = NO;
            [self playWordSound:@"beep5ms.wav"];
            NSString *codeStr = [[NSString alloc] initWithBytes:byteData length:dataLenth-1 encoding:NSUTF8StringEncoding];
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.billCodeTF.text = codeStr;
                [self.billArr insertObject:codeStr atIndex:0];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                [self.mTableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [self.mTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
            });
        }
            break;
        case COMM_CMD_TYPE_Battery://电量
        {
            int value = *byteData / 10;
            NSLog(@"电量：%d", value);
            self.bageValue = value;
            NSLog(@"检测到电量了2");
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.messageLbl.text = @"设备就绪";
                [self.batteryBtn setImage:[UIImage imageNamed:[NSString stringWithFormat:@"charge%i", value]] forState:UIControlStateNormal];
            });

        }
            break;
            
        default:
            break;
    }
    
}

- (void)receiveFromRecorder:(Recorder *)recorder type:(COMM_CMD_TYPE)type byteData:(unsigned char *)byteData dataLenth:(unsigned char)dataLenth
{
    switch (type) {
        case COMM_CMD_TYPE_Code://条码
        {
            [self playWordSound:@"beep5ms.wav"];
            NSString *codeStr = [[NSString alloc] initWithBytes:byteData length:dataLenth-1 encoding:NSUTF8StringEncoding];
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.billCodeTF.text = codeStr;
                [self.billArr insertObject:codeStr atIndex:0];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                [self.mTableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [self.mTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
            });

            
        }
            break;
        case COMM_CMD_TYPE_Battery://电量
        {
            int value = *byteData / 10;
            NSLog(@"电量：%d", value);
            self.bageValue = value;
            NSLog(@"检测到电量了2");
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.messageLbl.text = @"设备就绪";
                [self.batteryBtn setImage:[UIImage imageNamed:[NSString stringWithFormat:@"charge%i", value]] forState:UIControlStateNormal];
            });
        }
            break;
            
        default:
            break;
    }
}


#pragma mark - UITableViewDelegate,UITableViewDataSource method
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
}

#pragma mark -- 懒加载电量检测播放器
- (AVAudioPlayer *)pcmWavPlayer
{
    if (_pcmWavPlayer == nil) {
        NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *soundPath = [filePath stringByAppendingPathComponent:@"image.wav"];
        NSURL *url = [NSURL fileURLWithPath:soundPath];
        NSError *err = nil;
        _pcmWavPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
        _pcmWavPlayer.volume = 1.0;
        _pcmWavPlayer.delegate = self;
        [_pcmWavPlayer prepareToPlay];
        if (err != nil) {
            NSLog(@"player init error:%@",err);
            _pcmWavPlayer = nil;
        }
    }
    
    return _pcmWavPlayer;
}

#pragma mark -- 检测版本信息
- (void)checkVersion
{
    Byte data[] = {0x00,0x00};
    
    [self comm_send:COMM_TRANS_TYPE_SEND cmd:COMM_CMD_TYPE_VERSION pData:data len:2];
        
    [self.pcmWavPlayer play];
    
//    NSString *tmpDir = NSTemporaryDirectory();
}

/*-------------------------------------------------------------------------
 * 函数: comm_send
 * 说明: 发送
 * 参数: pData---数据buffer
 len-----条码长度
 * 返回: HY_OK------发送成功
 HY_ERROR---发送失败
 -------------------------------------------------------------------------*/
- (void)comm_send:(COMM_TRANS_TYPE)transType cmd:(COMM_CMD_TYPE)cmd pData:(Byte[])pData len:(int)len
{
    Byte i;
    Byte temp[len + 6];
    int sum=0;
    
    if (pData == NULL) return;
    
    temp[0] = COMM_PAKET_START_BYTE;
    temp[1] = (Byte)(len+2);
    temp[2] = (Byte)transType;
    temp[3] = (Byte)cmd;
    //拷贝pData到temp中
    memcpy(temp+4, pData, len);
    temp[len+5] = COMM_PAKET_END_BYTE;
    //计算校验位
    for(i = 1; i < len + 3; i++)
    {
        sum += temp[i];
    }
    //把校验数据写进入
    //    temp[len+4] = (Byte)sum;
    temp[len+4] = sum&0xff;
    
    Byte temp1[len+7];
    temp1[0] = 0x11;
    memcpy(temp1+1, temp, len+6);
    WriteComm(temp1, len+7);
    
    printByteArr(temp1, len+7);
    
    signed short pcmData[48000*2];
    
    int size = data2Pcm(temp1, len + 7, pcmData);
    NSData *codeData = [[NSData alloc] initWithBytes:pcmData length:size];
    if (size) {
        [self.player.voiceDataQueue enqueue:codeData];
        
        NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        filePath = [filePath stringByAppendingPathComponent:@"image.pcm"];
        //把pcm数据写入文件
        [codeData writeToFile:filePath atomically:YES];
        
    }
    
}

@end
