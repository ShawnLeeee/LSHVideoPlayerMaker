//
//  LSHVideoPlayerVC.m
//  LSHVideoPlayerMaker
//
//  Created by lishihua on 16/3/22.
//  Copyright © 2016年 HistoryPainting. All rights reserved.
//
#define kWholeWidth ([UIScreen mainScreen].bounds.size.width)
#define kWholeHeight ([UIScreen mainScreen].bounds.size.height)
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "LSHVideoPlayerVC.h"
typedef enum : NSInteger {
    kDirectionNone,
    kDirectionUpOrDownR,
    kDirectionUpOrDownL,
    kDirectionRightOrLeft
}Direction;
@interface LSHVideoPlayerVC ()<UIGestureRecognizerDelegate>
{
    Direction _dir;
    BOOL _played;
    UISlider* _volumeViewSlider;
    NSString *_totalTime;
    NSDateFormatter *_dateFormatter;

}
@property (nonatomic ,strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic ,strong) AVPlayerItem *playerItem;
@property (nonatomic ,strong) UIButton *stateButton;
@property (nonatomic ,strong) UILabel *timeLabel;
@property (nonatomic ,strong) id playbackTimeObserver;
@property (nonatomic ,strong) UISlider *videoSlider;
@property (nonatomic ,strong) UIProgressView *videoProgress;
@end

@implementation LSHVideoPlayerVC
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.view];
    if(touchPoint.x >= ([UIScreen mainScreen].bounds.size.width / 2.0))
    {
        _dir = kDirectionUpOrDownR;
    } else {
        _dir = kDirectionUpOrDownL;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self layoutPlayView];
    [self dealDirection];
}
- (void)layoutPlayView
{
    NSURL *videoUrl = [NSURL URLWithString:@"XX.mp4"];
    self.playerItem = [AVPlayerItem playerItemWithURL:videoUrl];
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    _playerLayer.frame = CGRectMake(5, 30, kWholeWidth - 10, kWholeHeight - 30);
    _playerLayer.videoGravity = AVLayerVideoGravityResize;
    [self.view.layer addSublayer:_playerLayer];
    
    [self.player play];
    self.stateButton.enabled = NO;
    // 添加视频播放结束通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    self.stateButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_stateButton setFrame:CGRectMake(10, kWholeHeight - 40, 40, 30)];
    [_stateButton setTitle:@"Play" forState:UIControlStateNormal];
    [_stateButton addTarget:self action:@selector(handleStateBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_stateButton];
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(kWholeWidth - 120, kWholeHeight - 30, 120, 20)];
    [self.view addSubview:_timeLabel];
    self.videoProgress = [[UIProgressView alloc] initWithFrame:CGRectMake(60, kWholeHeight - 21, kWholeWidth - 60 - 130, 2)];
    [self.view addSubview:_videoProgress];
    
    self.videoSlider = [[UISlider alloc] initWithFrame:CGRectMake(60, kWholeHeight - 35, kWholeWidth - 60 - 130, 30)];
    [_videoSlider addTarget:self action:@selector(handleSlider:) forControlEvents:UIControlEventValueChanged];
    [_videoSlider addTarget:self action:@selector(handleEndSlider:) forControlEvents:UIControlEventEditingDidEnd];
    [self.view addSubview:_videoSlider];
    
    //添加控制声音的控件
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(60, kWholeHeight - 45, kWholeWidth - 60 - 130, 30)];
    _volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            _volumeViewSlider = (UISlider*)view;
            break;
        }
    }
}
- (void)dealDirection
{
    UIPanGestureRecognizer *panPressGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureResult:)];
    if (![panPressGesture respondsToSelector:@selector(locationInView:)]) {
    }else {
        panPressGesture.delegate = self;
        panPressGesture.maximumNumberOfTouches = NSUIntegerMax;
        panPressGesture.minimumNumberOfTouches = 1;
        [self.view addGestureRecognizer:panPressGesture];
    }
}
// 拖拽手势
- (void)handleGestureResult:(UIPanGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:{
            NSLog(@"======UIGestureRecognizerStateBegan");
            break;
        }
        case UIGestureRecognizerStateChanged:{
            NSLog(@"======UIGestureRecognizerStateChanged");
            CGPoint translation = [gestureRecognizer translationInView:self.view];
            NSInteger flag = (translation.x * translation.x) >= (translation.y * translation.y) ? 1 : 0;
            NSLog(@"X的偏移量:%f   Y的偏移量:%f", translation.x, translation.y);
            NSLog(@"caca %f", [UIScreen mainScreen].bounds.size.width);
            if (flag) {
                float rate = translation.x / ([UIScreen mainScreen].bounds.size.width);
                float value = _videoSlider.value;
                NSLog(@"快进快退  %f    %f     %f", translation.x, _videoSlider.value, rate);
                value += rate * _videoSlider.maximumValue;
                _videoSlider.value = value;
                [self handleSlider:_videoSlider];
            } else {
                if (_dir == kDirectionUpOrDownR) {
                    float value = [UIScreen mainScreen].brightness;
                    NSLog(@"改变亮度  %f    %f", translation.y, value);
                    float rate = translation.y / ([UIScreen mainScreen].bounds.size.height * 1);
                    value += (rate * -1);
                    [[UIScreen mainScreen] setBrightness:value];
                } else if (_dir == kDirectionUpOrDownL){
                    NSLog(@"改变音量大小 %f", translation.y);
                    float rate = translation.y / ([UIScreen mainScreen].bounds.size.height * 1);
                    float voice = _volumeViewSlider.value;
                    voice += (rate * -1);
                    [_volumeViewSlider setValue:voice animated:NO];
                }
            }
            [gestureRecognizer setTranslation:CGPointMake(0, 0) inView:self.view];//  注意一旦你完成上述的移动，将translation重置为0十分重要。否则translation每次都会叠加，很快你的view就会移除屏幕！
            break;
        }
        case UIGestureRecognizerStateCancelled:{
            NSLog(@"======UIGestureRecognizerStateCancelled");
            break;
        }
        case UIGestureRecognizerStateFailed:{
            NSLog(@"======UIGestureRecognizerStateFailed");
            break;
        }
        case UIGestureRecognizerStatePossible:{
            NSLog(@"======UIGestureRecognizerStatePossible");
            break;
        }
        case UIGestureRecognizerStateEnded:{
            NSLog(@"======UIGestureRecognizerStateEnded || UIGestureRecognizerStateRecognized");
            break;
        }
        default:{
            NSLog(@"======Unknow gestureRecognizer");
            break;
        }
    }
}
//拖动slider快进
- (void)handleSlider:(UISlider *)slider
{
    CMTime changedTime = CMTimeMakeWithSeconds(slider.value, 1);
    __weak typeof(self) weakSelf = self;
    [self.player seekToTime:changedTime completionHandler:^(BOOL finished) {
        [weakSelf.player play];
        //        [weakSelf.stateButton setTitle:@"Stop" forState:UIControlStateNormal];
    }];
}
- (void)handleEndSlider:(UISlider *)slider
{
    NSLog(@"value end:%f",slider.value);
    CMTime changedTime = CMTimeMakeWithSeconds(slider.value, 1);
    __weak typeof(self) weakSelf = self;
    [self.player seekToTime:changedTime completionHandler:^(BOOL finished) {
        [weakSelf.player play];
        [weakSelf.stateButton setTitle:@"Stop" forState:UIControlStateNormal];
    }];
}
//
- (void)updateVideoSlider:(CGFloat)currentSecond {
    [self.videoSlider setValue:currentSecond animated:YES];
}
//点击播放暂停按钮
- (void)handleStateBtn:(UIButton *)btn
{
    if (!_played) {
        [self.player play];
        [self.stateButton setTitle:@"Stop" forState:UIControlStateNormal];
    } else {
        [self.player pause];
        [self.stateButton setTitle:@"Play" forState:UIControlStateNormal];
    }
    _played = !_played;
}
- (void)moviePlayDidEnd:(NSNotification *)notification
{
    NSLog(@"Play end");
    __weak typeof(self) weakSelf = self;
    [self.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        [weakSelf.videoSlider setValue:0.0 animated:YES];
        [weakSelf.stateButton setTitle:@"Play" forState:UIControlStateNormal];
    }];
}
- (void)updatePlayState:(AVPlayerItem *)playerItem {
    __weak typeof(self) weakSelf = self;
    self.playbackTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        CGFloat currentSecond = playerItem.currentTime.value/playerItem.currentTime.timescale;// 计算当前在第几秒
        [weakSelf.videoSlider setValue:currentSecond animated:YES];
        NSString *timeString = [weakSelf dealWithTime:currentSecond];
        weakSelf.timeLabel.text = [NSString stringWithFormat:@"%@/%@",timeString,_totalTime];
    }];
}
//添加观察者
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        if ([playerItem status] == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayerStatusReadyToPlay");
            self.stateButton.enabled = YES;
            CMTime duration = self.playerItem.duration;
            CGFloat totalSecond = playerItem.duration.value / playerItem.duration.timescale;
            _totalTime = [self dealWithTime:totalSecond];
            [self dealWithVideoSlider:duration];
            NSLog(@"movie total duration:%f",CMTimeGetSeconds(duration));
            [self updatePlayState:self.playerItem];
        } else if ([playerItem status] == AVPlayerStatusFailed) {
            NSLog(@"AVPlayerStatusFailed");
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSTimeInterval timeInterval = [self availableDuration];
        NSLog(@"Time Interval:%f",timeInterval);
        CMTime duration = self.playerItem.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        [self.videoProgress setProgress:timeInterval / totalDuration animated:YES];
    }
}
//缓冲区
- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[self.player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;
    return result;
}
//设置Slider的属性
- (void)dealWithVideoSlider:(CMTime)duration {
    self.videoSlider.maximumValue = CMTimeGetSeconds(duration);
    UIGraphicsBeginImageContextWithOptions((CGSize){ 1, 1 }, NO, 0.0f);
    UIImage *transparentImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.videoSlider setMinimumTrackImage:transparentImage forState:UIControlStateNormal];
    [self.videoSlider setMaximumTrackImage:transparentImage forState:UIControlStateNormal];
}
#pragma mark - dealWithTime
//转换时间格式
- (NSString *)dealWithTime:(CGFloat)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    if (second/3600 >= 1) {
        [[self dateFormatter] setDateFormat:@"HH:mm:ss"];
    } else {
        [[self dateFormatter] setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [[self dateFormatter] stringFromDate:d];
    return showtimeNew;
}
- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return _dateFormatter;
}
#pragma mark - removeObserver
//移除观察者
- (void)dealloc {
    [self.playerItem removeObserver:self forKeyPath:@"status" context:nil];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    [self.player removeTimeObserver:self.playbackTimeObserver];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
