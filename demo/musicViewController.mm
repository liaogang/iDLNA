//
//  musicViewController.m
//  demo
//
//  Created by liaogang on 15/6/26.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "musicViewController.h"
#import "DlnaRender.h"
#import "PlayerEngine.h"
#import "PlayerMessage.h"
#import "UIImageView+WebCache.h"
#import "UISlider+hideThumbWhenDisable.h"
#import <MediaPlayer/MediaPlayer.h>
#import "CDAlbumViewController.h"


void valueToMinSec(double d, int *m , int *s);




@interface musicViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *albumPicture1;
@property (weak, nonatomic) IBOutlet UIImageView *albumPicture2;

@property (weak, nonatomic) IBOutlet UILabel *trackTitle1;
@property (weak, nonatomic) IBOutlet UILabel *trackTitle2;

@property (weak, nonatomic) IBOutlet UILabel *labelTimeL;
@property (weak, nonatomic) IBOutlet UILabel *labelTimeR;

@property (weak, nonatomic) IBOutlet UISlider *posSlider;
@property (weak, nonatomic) IBOutlet UIButton *btnPause;
@property (weak, nonatomic) IBOutlet UIButton *btnPlay;

@property (nonatomic,strong) NSURL *currURL;

@property (nonatomic,strong) NSString *currTitle,*artist,*album;

@property (nonatomic) bool showLeftSide;

@property (nonatomic) bool isSeeking;

@property (nonatomic,strong) NSURL *album_uri;

@property (nonatomic,strong) UIImage *album_image;

@property (nonatomic,strong) NSMutableDictionary * info;

@property (nonatomic) bool needSendInfoToDevice;

@property (nonatomic) int count;

@property (weak, nonatomic) IBOutlet UIView *cdAlbumPlaceholder;

@property (nonatomic,strong) CDAlbumViewController *cdAlbumViewController;

@end

@implementation musicViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.needSendInfoToDevice = NO;
    
    addObserverForEvent(self , @selector(trackStarted:), EventID_track_started);
    addObserverForEvent(self , @selector(trackStopped), EventID_track_stopped);
    addObserverForEvent(self , @selector(playerStateChanged), EventID_track_state_changed);
    addObserverForEvent(self, @selector(updateProgressInfo:), EventID_track_progress_changed);
    
    
    
    self.cdAlbumViewController = [CDAlbumViewController CDAlbumWithStoryBoard];
    [self.cdAlbumViewController addToView:self.cdAlbumPlaceholder];
}

-(void)trackStopped
{
    ProgressInfo *info = [[ ProgressInfo alloc]init];
    info.total = 0.;
    info.current = 0.;
    [self _updateProgressInfo:info];
    [self updateUI];
    
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;

    return;
}

-(void)playerStateChanged
{
    /// map from PlayState to PlayState2
    int map[] = {PlayState_stopped,PlayState_playing,PlayState_paused,PlayState_playing};
    
    PlayState playstate = [[PlayerEngine shared] getPlayState];

    [DlnaRender shared].mediaPanel.playState =(enum PlayState2) map[ (int)playstate];
    
    [[DlnaRender shared] notifyMediaPanelStateChanged];

    [self updateUI];
    
    self.needSendInfoToDevice = YES;
    
    if (playstate == playstate_playing)
        [self.cdAlbumViewController startAlbumRotation];
    else
        [self.cdAlbumViewController pauseAlbumRotation];
}

-(void)trackStarted:(NSNotification*)n
{
    self.info = nil;
    
    ProgressInfo *info = n.object;
    NSAssert([info isKindOfClass:[ProgressInfo class]], nil);
    [self.posSlider setMaximumValue: info.total];
    [self.posSlider setValue: 0];
    
    
    [DlnaRender shared].mediaPanel.trackPosition = [NSString stringWithUTF8String: dlna_second_to_stirng(info.current) ] ;
    
    [DlnaRender shared].mediaPanel.trackDuration = [NSString stringWithUTF8String: dlna_second_to_stirng(info.total)];
    
    [[DlnaRender shared] notifyMediaPanelStateChanged];
    
    [self updateUI];
}



- (void)setPlayInfoWhenBeingBackground:(ProgressInfo*)pgInfo
{
    if (!self.info)
    {
        self.info = [NSMutableDictionary dictionary];
        if (self.currTitle)
            self.info[MPMediaItemPropertyTitle] = self.currTitle;  //歌曲名字
        if (self.artist)
            self.info[MPMediaItemPropertyArtist] = self.artist; //歌手
        if(self.album)
            self.info[MPMediaItemPropertyAlbumTitle] = self.album; //唱片名字
        self.info[MPNowPlayingInfoPropertyPlaybackRate] = [NSNumber numberWithFloat:1.0];
    }
    
    self.info[MPMediaItemPropertyPlaybackDuration] = @(pgInfo.total).stringValue;
    self.info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(pgInfo.current).stringValue;
    
    if (self.album_image)
        self.info[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithImage:self.album_image];
    
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = self.info;
}


-(void)_updateProgressInfo:(ProgressInfo *)info
{
    NSAssert([info isKindOfClass:[ProgressInfo class]], nil);
    
    if (info.total > 0) {
        [self.posSlider setMaximumValue: info.total];
        [self.posSlider setValue: info.current];
        
        
        if (self.needSendInfoToDevice) {
            self.needSendInfoToDevice = false;
            [self setPlayInfoWhenBeingBackground:info];
        }
        
        
        if (_count++ == 80 ) {
            [self moveImagePosition];
        }
        
    }else
    {
        [self.posSlider setMaximumValue: 0];
        [self.posSlider setValue: 0];
    }
    
    int min , sec;
    
    valueToMinSec(info.current, &min, &sec);
    self.labelTimeL.text = [NSString stringWithFormat:@"%02d:%02d",min,sec];
    
    valueToMinSec(info.total, &min, &sec);
    self.labelTimeR.text = [NSString stringWithFormat:@"%02d:%02d",min,sec];
    
    
    [DlnaRender shared].mediaPanel.trackPosition = [NSString stringWithUTF8String: dlna_second_to_stirng(info.current) ] ;
    
    [DlnaRender shared].mediaPanel.trackDuration = [NSString stringWithUTF8String: dlna_second_to_stirng(info.total) ] ;
    
    [[DlnaRender shared] notifyMediaPanelStateChanged];
}

-(void)updateProgressInfo:(NSNotification*)n
{
    if ( ! ( self.isSeeking  || self.posSlider.highlighted ) )
    {
        ProgressInfo *info = n.object;
        
        [self _updateProgressInfo:info];
    }
}

-(void)reset
{
    self.currTitle = nil;
//    self.trackImage = [UIImage imageNamed:@"cd_icon"];
//    NSAssert(self.trackImage, nil);
    
}

-(void)updateUI
{
    [self.albumPicture1 sd_setImageWithURL:self.album_uri placeholderImage:[UIImage imageNamed:@"cd_icon"]];
    [self.albumPicture2 sd_setImageWithURL:self.album_uri placeholderImage:[UIImage imageNamed:@"cd_icon"]];
    
    if(self.artist)
        self.trackTitle1.text=self.trackTitle2.text = [NSString stringWithFormat:@"%@ %@",self.artist,self.currTitle];
    else
        self.trackTitle1.text=self.trackTitle2.text = [NSString stringWithFormat:@"%@",self.currTitle];
        
    
    if ([PlayerEngine shared].isPlaying) {
        self.btnPause.hidden=FALSE;
        self.btnPlay.hidden=YES;
        
    }
    else
    {
        self.btnPause.hidden=YES;
        self.btnPlay.hidden=FALSE;
    }
    
    [self.posSlider setSliderEnabled: ![PlayerEngine shared].isStopped ];
    
    if (self.showLeftSide) {
        [self.albumPicture1 setAlpha:1.0f];
        [self.trackTitle1 setAlpha:1.0f];
        
        [self.albumPicture2 setAlpha:0.0f];
        [self.trackTitle2 setAlpha:0.0f];
    }
    else
    {
        [self.albumPicture2 setAlpha:1.0f];
        [self.trackTitle2 setAlpha:1.0f];
        
        [self.albumPicture1 setAlpha:0.0f];
        [self.trackTitle1 setAlpha:0.0f];
    }
    
    
    
}

-(void)playMedia:(NSURL*)url title:(NSString*)title artist:(NSString*)artist album:(NSString*)album album_uri:(NSString*)album_uri
{
    [[PlayerEngine shared]stop];
    [self reset];
    [self updateUI];
    
    
    self.currURL = url;
    self.album_uri = [NSURL URLWithString:album_uri];
    
    [self.cdAlbumViewController setAlbumImageUrl:self.album_uri];
    
    __weak musicViewController *weakSelf = self;
    [[SDWebImageManager sharedManager] downloadImageWithURL:self.album_uri options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        weakSelf.album_image = image;
    }];
    
    
    self.currTitle = title;
    self.artist = artist;
    self.album = album;
    
    [[PlayerEngine shared] playURL: url];
    return;
}

-(void)stop
{
    [[PlayerEngine shared]stop];
}

-(void)playPause
{
    if ([PlayerEngine shared].isStopped)
    {
        [self playMedia:self.currURL title:self.currTitle artist:self.artist album:self.album album_uri:self.album_uri.absoluteString];
    }
    else
    {
        [[PlayerEngine shared] playPause];
        
        [self moveImagePosition];
    }
}

-(void)moveImagePosition
{
    _count = rand() % 10;
    
    if ( rand() % 2 != 1 ) {
        [UIView animateWithDuration:2.0f animations:^{
            if (self.showLeftSide) {
                self.showLeftSide = NO;
                [self.albumPicture1 setAlpha: 0.0f];
                [self.trackTitle1 setAlpha:0.0f];
            }
            else
            {
                self.showLeftSide = YES;
                [self.albumPicture2 setAlpha:0.0f];
                [self.trackTitle2 setAlpha:0.0f];
            }
            
        } completion:nil];
        
        
        [UIView animateWithDuration:2.0f delay:3.0f options:0 animations:^{
            if (self.showLeftSide) {
                [self.albumPicture1  setAlpha:1.0f];
                [self.trackTitle1  setAlpha:1.0f];
            }
            else
            {
                [self.albumPicture2 setAlpha:1.0f];
                [self.trackTitle2 setAlpha:1.0f];
            }
        } completion:nil];
    }
}


- (IBAction)actionPause:(id)sender {
    [self playPause];
}

-(void)setSeekingFalse
{
    self.isSeeking = false;
}
- (IBAction)posSliding:(UISlider *)sender {
    float totalSecond = sender.value;
    
    int min = totalSecond / 60;
    
    int sec = totalSecond - min * 60;
    
    self.labelTimeL.text = [NSString stringWithFormat:@"%02d:%02d",min,sec];
}

- (IBAction)posEndChange:(UISlider*)sender {
    
    [self seek:sender.value];
    self.isSeeking = true;
    [self performSelector:@selector(setSeekingFalse) withObject:nil afterDelay:1.0f];
}

-(void)seek:(float)sec
{
    [[PlayerEngine shared] seekToTime: sec ];
    
    self.needSendInfoToDevice = YES;
}

@end

void valueToMinSec(double d, int *m , int *s)
{
    *m = d / 60;
    *s = (int)d % 60;
}






