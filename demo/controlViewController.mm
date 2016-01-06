//
//  playerViewController.m
//  demo
//
//  Created by liaogang on 15/5/20.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "controlViewController.h"
#import "DlnaControlPoint.h"
#import "UISlider+hideThumbWhenDisable.h"
#import "renderTableViewController.h"


/**
 @param OpenHome_MediaIn
 if 1, OpenHome Media enabled,the next and prev is to play next context in the playlist.(true playlist support)
 if 0, we will use this just to play next or previous media item in the result CDS returned.(play next and next manualy)
 */
#define OpenHome_Media 0



@interface controlViewController ()
@property (weak, nonatomic) IBOutlet UILabel *leftTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightTimeLabel;
@property (weak, nonatomic) IBOutlet UISlider *posSlider;
@property (weak, nonatomic) IBOutlet UISlider *volumnSlider;

@property (weak, nonatomic) IBOutlet UIButton *voiceIsOn;
@property (weak, nonatomic) IBOutlet UIButton *voiceIsOff;

@property (weak, nonatomic) IBOutlet UIButton *prevBtn;
@property (weak, nonatomic) IBOutlet UIButton *stopBtn;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIButton *pauseBtn;
@property (weak, nonatomic) IBOutlet UIButton *nextBtn;

@property (nonatomic,strong) NSURL *currentURI;

@property (nonatomic) bool isSeeking;

@property (weak, nonatomic) IBOutlet UILabel *mediaTitle;

@end

@implementation controlViewController
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (IBAction)actionShowPopRender:(id)sender {
    [renderTableViewController showRenderPopover:sender frame:CGRectNull];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.volumnSlider setSliderEnabled:false];
    [self.posSlider setSliderEnabled:false];
    self.voiceIsOn.enabled = false;
    self.playBtn.enabled = false;
    self.pauseBtn.enabled = false;
    self.prevBtn.enabled = false;
    self.nextBtn.enabled = false;
    
    
    [[DlnaControlPoint shared] setCallback_MediaAndRenderReady:^{
        [self notifyRenderAndMediaIsReady];
    }];
    
    
    [[DlnaControlPoint shared] setCallback_RenderMediaStateChanged:^(MediaPanel *mediaPanel) {
        [self updateUIControls:mediaPanel];
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)updateUIControls:(MediaPanel*)mediaPanel
{
    NSAssert([NSThread currentThread].isMainThread, nil);
    
    switch (mediaPanel.playState)
    {
        case PlayState_stopped:
        {
            self.mediaTitle.text = @"";
            
            self.stopBtn.enabled = FALSE;
            self.playBtn.hidden = NO;
            self.pauseBtn.hidden = YES;
            [self.posSlider setSliderEnabled:FALSE];
            self.posSlider.value = 0.;
            self.rightTimeLabel.text = self.leftTimeLabel.text  = @"00:00:00";
            break;
        }
        case PlayState_playing:
        {
            NPT_String mediaTitle = [DlnaControlPoint shared].pController->playingMediaTitle();
            NSString *title = [NSString stringWithUTF8String:mediaTitle];
            self.mediaTitle.text = title;
            
            self.stopBtn.enabled = YES;
            self.nextBtn.enabled = YES;
            self.prevBtn.enabled = YES;
            self.pauseBtn.enabled = true;
            self.playBtn.enabled = true;
            self.voiceIsOn.enabled = YES;
            [self.volumnSlider setSliderEnabled:YES];
            [self.posSlider setSliderEnabled:YES];
            
            
            self.playBtn.hidden = YES;
            self.pauseBtn.hidden = FALSE;
            break;
        }
        case PlayState_paused:
        {
            [self.posSlider setSliderEnabled:YES];
            self.stopBtn.enabled = YES;
            self.playBtn.hidden = NO;
            self.pauseBtn.hidden = YES;
            break;
        }
        default:
            break;
    }
    
    if ( mediaPanel.mute) {
        self.voiceIsOff.hidden = false;
        self.voiceIsOn.hidden = true;
    }
    else
    {
        self.voiceIsOff.hidden = true;
        self.voiceIsOn.hidden = false;
    }
    
    
    if (!self.volumnSlider.isHighlighted)
        self.volumnSlider.value = mediaPanel.volume;
    
    if (! self.isSeeking  ) {
        if(mediaPanel.trackDuration)
        {
            if(!self.posSlider.isHighlighted)
                self.posSlider.maximumValue = dlna_string_to_second(mediaPanel.trackDuration.UTF8String);
            self.rightTimeLabel.text = mediaPanel.trackDuration;
        }
        
        if(mediaPanel.trackPosition)
        {
            if(!self.posSlider.isHighlighted)
                self.posSlider.value = dlna_string_to_second(mediaPanel.trackPosition.UTF8String);
            self.leftTimeLabel.text = mediaPanel.trackPosition;
        }
    }
    

}


-(void)notifyRenderAndMediaIsReady
{
    [self sendPlayCmd];
}

#if OpenHome_Media
#else
-(bool)openNext
{
    auto medialist = [DlnaControlPoint shared].pController->getCurBrowseResults();
    
    int count = medialist->GetItemCount();
    
    int curr = [DlnaControlPoint shared].pController->m_CurBrowseIndex;
    
    if (curr + 1 == count)
        curr = -1 ;
    
    return  [DlnaControlPoint shared].pController->openIndex(curr+1);
}

-(bool)openPrev
{
    auto medialist = [DlnaControlPoint shared].pController->getCurBrowseResults();
    
    int count = medialist->GetItemCount();
    
    int curr = [DlnaControlPoint shared].pController->m_CurBrowseIndex;
    
    if (curr == 0)
        curr = count ;
    
    return  [DlnaControlPoint shared].pController->openIndex(curr -1);
}
#endif

-(void)setSeekingFalse
{
    self.isSeeking = false;
}

-(void)resumePlay
{
    [DlnaControlPoint shared].pController->HandleCmd_pause();
}

#pragma mark - Control actions
- (IBAction)posSliding:(UISlider *)sender {
    self.leftTimeLabel.text = [NSString stringWithUTF8String:dlna_second_to_stirng(sender.value) ];
}

- (IBAction)positionSliderChanged:(UISlider*)sender
{
    int v = sender.value;
    int h = v/(60*60);
    int m = (v - h * 60*60)/60;
    int s = (v - m * 60);
    char arg[256];
    sprintf(arg, "seek %2d:%2d:%2d", h , m , s);
    [DlnaControlPoint shared].pController->HandleCmd_seek(arg);
   
    self.isSeeking = true;
    [self performSelector:@selector(setSeekingFalse) withObject:nil afterDelay:2.0];
}

- (IBAction)volumnDragExit:(UISlider *)sender {
    [DlnaControlPoint shared].pController->HandleCmd_setVolumn( sender.value );
}

- (IBAction)actionVoiceOff:(UIButton*)sender {
    [DlnaControlPoint shared].pController->HandleCmd_mute();
}

- (IBAction)actionVoiceOn:(UIButton*)sender {
    [DlnaControlPoint shared].pController->HandleCmd_unmute();
}

- (IBAction)actionPrev:(id)sender {
#if OpenHome_Media
    [DlnaControlPoint shared].pController->HandleCmd_prev();
#else
    [self openPrev];
#endif
}

- (IBAction)actionStop:(id)sender {
    [DlnaControlPoint shared].pController->HandleCmd_stop();
    self.mediaTitle.text = @"";
}

-(void)sendPlayCmd
{
    
#if OpenHome_Media
    self.nextBtn.enabled=self.prevBtn.enabled=true;
    // disable next and prev button if current item is not a playlist.
    int index = [DlnaControlPoint shared].pController->m_CurBrowseIndex;
    if ( index != -1) {
        PLT_MediaObjectListReference list =[DlnaControlPoint shared].pController->getCurBrowseResults();
        PLT_MediaObject* object = * list->GetItem(index);
        bool isPlaylist = (object->m_ObjectClass.type.Compare("object.item.playlist",true) == 0 );
        self.nextBtn.enabled=self.prevBtn.enabled=isPlaylist;
    }
#endif
    
    [DlnaControlPoint shared].pController->HandleCmd_play();
}

- (IBAction)actionPlay:(id)sender {
    if ([DlnaControlPoint shared].mediaPanel.playState == PlayState_paused)
        [self resumePlay];
    else
        [DlnaControlPoint shared].pController->HandleCmd_play();
}

- (IBAction)actionPause:(id)sender {
    [DlnaControlPoint shared].pController->HandleCmd_pause();
}

- (IBAction)actionNext:(id)sender {
    
#if OpenHome_Media
    [DlnaControlPoint shared].pController->HandleCmd_next();
#else
    [self openNext];
#endif

}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    UINavigationController *nav = [segue destinationViewController];
    renderTableViewController *renderer = nav.viewControllers.firstObject;
    renderer.viewControllerPresentThis = self.navigationController;
    
}

@end
