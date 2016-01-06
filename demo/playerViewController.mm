//
//  playerViewController.m
//  demo
//
//  Created by liaogang on 15/5/20.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "playerViewController.h"
#import "VDLViewController.h"

#import "photoViewController.h"
#import "musicViewController.h"

#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

#import "DlnaControlPoint.h"
#import "DlnaRender.h"


@interface playerViewController () 

@property (nonatomic,strong) NSURL *currentURI;
@property (nonatomic,strong) NSString *currTitle;

@property (nonatomic,strong) VDLViewController *videoVC;

@property (nonatomic,strong) photoViewController *photoVC;

@property (nonatomic,strong) musicViewController *musicVC;

@property (nonatomic,strong)NSString *album_art_uri,*artist,*album;

@property (nonatomic) enum
{
mediaType_unsupport,
mediaType_video,
mediaType_photo,
mediaType_music,
}
mediaType;

@property (nonatomic,strong) MPVolumeView* volumeView;

/// 0.0~1.0
@property (nonatomic) float volume;

@property (nonatomic) BOOL isInModal;
@end

@implementation playerViewController

-(void)reset
{
    self.album_art_uri=nil;
    self.artist=nil;
    self.album=nil;
    self.currentURI=nil;
    self.currTitle=nil;
}

-(void)tryPresentSelf:(UIViewController*)parent
{
    if (self.isInModal == FALSE) {
        self.isInModal = true;
        [parent presentViewController:self.navigationController animated:YES completion:nil];
    }
    
}


- (IBAction)dismissViewController:(id)sender {
    
    self.isInModal = false;
    [self OnStop:NULL];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [DlnaRender shared].renderDelegate2 = self;
    
    // set the render's volume by current system volume
    [DlnaRender shared].mediaPanel.volume = [[AVAudioSession sharedInstance] outputVolume] * 100 ;
    
    
    // Get notice when volume change.
    /// do not remove this line. @see http://stackoverflow.com/questions/3651252/how-to-get-audio-volume-level-and-volume-changed-notifications-on-ios#
    self.volumeView= [[MPVolumeView alloc]init];
    
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(volumeChanged:)
     name:@"AVSystemController_SystemVolumeDidChangeNotification"
     object:nil];
}

- (void)volumeChanged:(NSNotification *)notification
{
    // from 0.0 to 1.0
    float volume = [[[notification userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    
    if (![DlnaRender shared].mediaPanel.mute )
    {
        self.volume = volume ;
        [DlnaRender shared].mediaPanel.volume = (int)(volume * 100);
        [[DlnaRender shared] notifyMediaPanelStateChanged];
    }
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - MediaRendererDelegate

-(void)OnGetCurrentConnectionInfo:(PLT_ActionReference*)action
{
}

// AVTransport

-(void) OnPause:(PLT_ActionReference*)action
{
    if(self.mediaType == mediaType_video)
    {
        [self.videoVC pause];
    }
    else if(self.mediaType == mediaType_music)
    {
        [self.musicVC playPause];
    }
}

-(void)play
{
    if (self.currentURI) {
        NSLog(@"OnPlay2");
        NSLog(@"");
        [self.videoVC setMedia: self.currentURI];
        self.videoVC.view.hidden = NO;
        [self.videoVC play];
    }
}

-(void) OnPlay:(PLT_ActionReference*)action
{
    NSAssert(self.currentURI, nil);
    
    if(self.mediaType == mediaType_photo )
    {
        [self.photoVC showPhoto:self.currentURI];
    }
    else if ( self.mediaType == mediaType_music)
    {
        [self.musicVC playMedia:self.currentURI title:self.currTitle artist:self.artist album:self.album album_uri:self.album_art_uri];
    }
    else if( self.mediaType == mediaType_video)
    {
        // Play with delay. Wait for the view's loading.
        [self performSelector:@selector(play) withObject:nil afterDelay:1];
    }
    else
    {

        
        
    }
}


-(void) OnSeek:(PLT_ActionReference*)action
{
    NPT_String uint;
    NPT_String target;
    
    (*action)->GetArgumentValue("Unit", uint);
    (*action)->GetArgumentValue("Target", target);
    
    if (uint.Compare("REL_TIME") == 0)
    {
        if (self.mediaType == mediaType_video)
        {
            NSString* time = self.videoVC.time;
            NSString* remainingtime = self.videoVC.remainingTime;
            
            // desired time
            int h=0,m=0,s=0;
            
            //vlc movie's time,used plus left.
            int h1=0,m1=0,s1=0;
            int h2=0,m2=0,s2=0;
            
            sscanf(target,"%d:%d:%d",&h,&m,&s);
            
            if (remainingtime.length + time.length > 12) {
                sscanf(time.UTF8String,"%d:%d:%d",&h1,&m1,&s1);
                sscanf(remainingtime.UTF8String,"-%d:%d:%d",&h2,&m2,&s2);
            }
            else{
                sscanf(time.UTF8String,"%d:%d",&m1,&s1);
                sscanf(remainingtime.UTF8String,"-%d:%d",&m2,&s2);
            }
            
            // get the total seconds.
            float total,total1,total2;
            
            total = h*60*60 +  m*60  + s;
            total1= h1*60*60 + m1*60 + s1;
            total2= h2*60*60 + m2*60 + s2;
            
            if (total1 + total2 > 0)
            {
                float f = total / (total1 + total2);
                [self.videoVC setPos: f];
            }
            
        }
        else if( self.mediaType == mediaType_music)
        {
            int sec = dlna_string_to_second(target);
            [self.musicVC seek:sec];
        }
        
    }
    else
    {
        printf("Unsupportted argument value.\n");
    }
    

}

-(void) OnStop:(PLT_ActionReference*)action
{
    if (self.mediaType == mediaType_video) {
        [self.videoVC stop];
    }
    else if (self.mediaType == mediaType_music)
    {
        [self.musicVC stop];
    }

}


-(void) OnSetAVTransportURI:(PLT_ActionReference*)pAction
{
    [self.videoVC stop];
    [self.musicVC stop];
    [self reset];
    
    NPT_String currentURI;
    (*pAction)->GetArgumentValue("CurrentURI", currentURI);
    self.currentURI = [NSURL URLWithString:[NSString stringWithUTF8String:currentURI]];
 
    
    NPT_String currentURIMetaData;
    (*pAction)->GetArgumentValue("CurrentURIMetaData", currentURIMetaData);
    
    PLT_MediaObjectListReference medias;
    PLT_Didl::FromDidl(currentURIMetaData, medias);
    
    if (!medias.IsNull()) {
        int count = medias->GetItemCount();
        if (count > 0)
        {
            PLT_MediaObject * media = *medias->GetFirstItem();
            
            self.currTitle = [NSString stringWithUTF8String: media->m_Title ];
            
            if( media->m_ObjectClass.type.Compare("object.item.videoItem",true) == 0 )
            {
                self.mediaType = mediaType_video;
            }
            else if( media->m_ObjectClass.type.Compare("object.item.imageItem.photo",true) == 0 )
            {
                self.mediaType = mediaType_photo;
            }
            else if( media->m_ObjectClass.type.Compare("object.item.audioItem.musicTrack",true) == 0 ||
                    media->m_ObjectClass.type.Compare("object.item.audioItem.audioBroadcast",true) == 0)
            {
                self.mediaType = mediaType_music;
                
                
                // get album art icon uri
                auto album_arts = media->m_ExtraInfo.album_arts;
                int count = album_arts.GetItemCount();
                if (count > 0) {
                    auto beg = album_arts.GetFirstItem();
                    PLT_AlbumArtInfo album_art = *beg;
                    
                    self.album_art_uri = [NSString stringWithUTF8String:album_art.uri];
                }
                
                // get artist
                auto artists = media->m_People.artists;
                if (artists.GetItemCount() > 0) {
                    auto beg = artists.GetFirstItem();
                    PLT_PersonRole role = *beg;
                    self.artist = [NSString stringWithUTF8String: role.name];
                }
                
                // get album info.
                self.album = [NSString stringWithUTF8String:media->m_Affiliation.album];
                
            }
            else
            {
                self.mediaType = mediaType_unsupport;
                
                // Tread `rmvb` as video.
                for (int i = 0; i < media->m_Resources.GetItemCount(); i++) {
                    PLT_MediaItemResource *r = media->m_Resources.GetItem(i);
                    NPT_String contentType = r->m_ProtocolInfo.GetContentType();
                    if (contentType.Compare("application/vnd.rn-realmedia-vbr",true) == 0) {
                        self.mediaType = mediaType_video;
                        break;
                    }
                }
                
            }
        }
    }
    
        if (self.mediaType == mediaType_music) {
            if (!self.musicVC) {
                self.musicVC =[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"musicVC"];
                [self.musicVC.view setFrame: self.view.bounds];
                [self.view addSubview:self.musicVC.view];
            }
            
            [self.videoVC.view setHidden:YES];
            [self.photoVC.view setHidden:YES];
            [self.musicVC.view setHidden:FALSE];
        }
        else if(self.mediaType == mediaType_photo)
        {
            if (!self.photoVC)
            {
                self.photoVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"photoVC"];
                [self.photoVC.view setFrame:self.view.bounds];
                self.photoVC.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
                [self.view addSubview: self.photoVC.view];
            }
            
            [self.videoVC.view setHidden:YES];
            [self.photoVC.view setHidden:FALSE];
            [self.musicVC.view setHidden:YES];
        }
        else if(self.mediaType == mediaType_video)
        {
            
            if (!self.videoVC) {
                self.videoVC = [[VDLViewController alloc]init];
                self.videoVC.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
                [self.videoVC.view setFrame: self.view.bounds];
                [self.view addSubview: self.videoVC.view];
                self.videoVC.isNotInModalView = false;
                
                __weak playerViewController * weakSelf = self;
                self.videoVC.fullScreenCallBack = ^(BOOL bWillConvertToFullScreen){
                        weakSelf.navigationController.navigationBarHidden = bWillConvertToFullScreen;
                };
                
                
            }
            
            self.navigationController.navigationBarHidden = YES;
            
            [self.videoVC.view setHidden:FALSE];
            [self.photoVC.view setHidden:YES];
            [self.musicVC.view setHidden:YES];
    
        }
        else
        {
            [[[UIAlertView alloc]initWithTitle:@"Can not play meida" message:@"Not supported media format yet" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
            
            NSLog(@"Not supported media type!");
        }

    
}



// RenderingControl
-(void) OnSetVolume:(PLT_ActionReference*)action
{
    NPT_UInt32 volume = 0;
    (*action)->GetArgumentValue("DesiredVolume", volume);
    
    float fVolume = volume / 100.;
    
    self.volume = fVolume;
    
    if(![DlnaRender shared].mediaPanel.mute)
        [self setPlayerVolume:fVolume mute:false];
    
}

/// 0.0~1.0
-(void)setPlayerVolume:(float)volume mute:(bool)mute
{
    /**
     This is a private API.
     @see http://stackoverflow.com/questions/19218729/ios-7-mpmusicplayercontroller-volume-deprecated-how-to-change-device-volume-no
     */
    //find the volumeSlider
    UISlider* volumeViewSlider = nil;
    for (UIView *view in [self.volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }
    
    if (mute) {
//        self.volume = [[AVAudioSession sharedInstance] outputVolume] ;
        [volumeViewSlider setValue:0.0 animated:YES];
    }
    else
    {
        [volumeViewSlider setValue:volume animated:YES];
    }
 
    
    [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
}



-(void) OnSetMute:(PLT_ActionReference*)action
{
    NPT_String mute;
    (*action)->GetArgumentValue("DesiredMute",mute);
    
    bool bMute = ( mute == "1" );
    
    [DlnaRender shared].mediaPanel.mute = bMute;
    [self setPlayerVolume:self.volume mute: bMute];
    [[DlnaRender shared] notifyMediaPanelStateChanged];
}




@end

