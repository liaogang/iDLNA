//
//  AppDelegate.m
//  demo
//
//  Created by liaogang on 15/5/18.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "AppDelegate.h"
#import <Platinum/Platinum.h>
#import "UPnPEngine.h"
#import "Util.h"
#import "Macro.h"
#import "DlnaControlPoint.h"
#import "DlnaRender.h"
#import "PlayerMessage.h"
#import <AVFoundation/AVFoundation.h>
#import "playerViewController.h"
#import "constDefines.h"
#import "SDWebImageManager.h"
#import "UITableViewCellMy.h"
#import <Photos/Photos.h>


@interface AppDelegate ()
<MediaRendererDelegate>
{
    bool inBackground;
}

/*app delegate has responsibility to show media player when other dlna client want to play.
 */
@property (nonatomic,strong) UINavigationController *playNav;
@property (nonatomic,strong) playerViewController *playController;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [[SDImageCache sharedImageCache] setShouldDecompressImages:NO];
    [[SDWebImageDownloader sharedDownloader] setShouldDecompressImages:NO];
    
    /*
    /// set dlna device alive time from 30 minutes to 3 minutes. double of the param pass in.
    PLT_Constants::GetInstance().SetDefaultDeviceLease(NPT_TimeInterval( 1.5 * 60 ));
    */
    
    
    initPlayerMessage();
    
    inBackground = false;
    
    [self initUpnpServer];
    [[DlnaRender shared] startUpnp];
    [[DlnaControlPoint shared] startUpnp];
    
    [DlnaRender shared].renderDelegate = self;
    
    
    NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithBool:YES], kKeyDMS_enabled,
                              [NSNumber numberWithBool:YES], kKeyRenderEnabled,
                              nil];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    AVAudioSession * session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
  
    
    
    
      // Load storyboard's initial view controller.
      UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];

      
      self.playNav = [sb instantiateViewControllerWithIdentifier:@"playNav"];
      self.playNav.view.hidden=YES;

      self.playController = self.playNav.viewControllers.firstObject;
    
        playerViewController *pvc = self.playController;
      [DlnaRender shared].renderDelegate2 = pvc;

    
    return YES;
}


- (void)remoteControlReceivedWithEvent: (UIEvent *) receivedEvent {
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlPlay:
                postEvent(EventID_to_play_pause_resume, nil);
                break;
            case UIEventSubtypeRemoteControlPause:
                postEvent(EventID_to_play_pause_resume, nil);
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                postEvent(EventID_to_play_next, nil);
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                break;
            default:
                break;
        }
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    if (!inBackground) {
        inBackground = true;
        [self stopAll];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    if (!inBackground) {
        inBackground = true;
        [self stopAll];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

-(void)stopAll
{
    [[DlnaRender shared] stopUpnp];
    [[DlnaControlPoint shared] stopUpnp];
    [[UPnPEngine getEngine] stopUPnP];
}

-(void)startAll
{
    [[DlnaRender shared] startUpnp];
    [[DlnaControlPoint shared] startUpnp];
    [[UPnPEngine getEngine] startUPnP];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
   
    if (inBackground) {
        inBackground = false;
        [self startAll];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
        [self stopAll];

    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSString *tempDirectory = NSTemporaryDirectory();
    NSArray *cacheFiles = [fileManager contentsOfDirectoryAtPath:tempDirectory  error: &error];
    for (NSString *file in cacheFiles) {
        error = nil;
        
        /// @see ItunesMusicDMSDelegate
        if ( strncmp(file.UTF8String, "T_M_File_", sizeof("T_M_File_")-1) == 0) {
            [fileManager removeItemAtPath:[tempDirectory stringByAppendingPathComponent:file] error: &error];
        }

        /* handle error */
    }
    
    
}


- (void)initUpnpServer {
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    [[UPnPEngine getEngine] intendStartRootFileServer];
    
    [[UPnPEngine getEngine] startUPnP];
    
}

- (void)destroyUpnpServer {
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [[UPnPEngine getEngine] stopUPnP];
}


#pragma mark - MediaRendererDelegate
-(void) OnPlay:(PLT_ActionReference*)action
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyPresentModal object:nil];
    [self performSelector:@selector(presentPlayer) withObject:nil afterDelay:0.5];
}

-(void)presentPlayer
{
    _playNav.view.hidden=NO;
    [_playController tryPresentSelf:self.window.rootViewController];
}


@end




