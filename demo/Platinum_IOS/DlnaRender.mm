//
//  DlnaRender.mm
//  demo
//
//  Created by liaogang on 15/6/30.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "DlnaRender.h"
#import <UIKit/UIKit.h> //UIDevice name
#import "MAAssert.h"
#import "DemoReachability.h"

void write_to_state_variable(MediaPanel *mediaPanel,PLT_Service *serviceAVTransport,PLT_Service *serviceRenderingControl);

NSString *kKeyRenderEnabled = @"DlnaRender_enabled";

NSString *kNotifyDMRStopped = @"dmr_stopped";

NSString *kNotifyDMRStarted = @"dmr_started";

@interface DlnaRender () <MediaRendererDelegate>
{
    PLT_MediaRendererDelegateMy delegateCPP;
    PLT_MediaRenderer *pRenderer;
}
@property (nonatomic,strong) DemoReachability* reachabilityForLocalWiFi;
@property (nonatomic) PLT_UPnP *pUpnpRender;
@end



@implementation DlnaRender

+(instancetype)shared
{
    static DlnaRender *shared = nil;
    
    if (shared == nil) {
        shared = [[DlnaRender alloc]init];
    }
    
    return shared;
}

-(instancetype)init
{
    self  = [super init];
    if (self) {
        [self reset];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localWiFiChanged:) name:kReachabilityChangedNotificationForDemo object:nil];
        
        self.reachabilityForLocalWiFi = [DemoReachability reachabilityForLocalWiFi];
        [self.reachabilityForLocalWiFi startNotifier];
        
    }
    return self;
}

-(bool)isDisabled
{
    return ![self isEnabled];
}

-(bool)isEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kKeyRenderEnabled];
}

-(void)disable
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey: kKeyRenderEnabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self stopUpnp];
}

-(void)enable
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey: kKeyRenderEnabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self startUpnp];
}

-(void)localWiFiChanged:(NSNotification*)n
{
    DemoReachability *r = n.object;
    auto result = r.currentReachabilityStatus;
    
    static NSInteger lastStatus =  -1;
    
    if (result != lastStatus) {
        if( result == DemoNotReachable)
        {
            [self stopUpnp];
        }
        else
        {
            NSLog(@"render wifi changed. start upnp");
            [self startUpnp];
        }
        
        lastStatus = result;
    }

}

-(void)stopUpnp
{
    if (_pUpnpRender->IsRunning()) {
        NSLog(@"render -> stop upnp.");
        _pUpnpRender->Stop();
        
        _serviceAVTransport = nil;
        _serviceRenderingControl = nil;
        _serviceConnectionManager = nil;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyDMRStopped object:nil];
    }
}

-(void)_startUpnp
{
    // do not start the upnp while the network is not reachable.
    if( _pUpnpRender->IsRunning() == false &&
       [self.reachabilityForLocalWiFi currentReachabilityStatus] != DemoNotReachable )
    {
        NSLog(@"render -> start upnp.");
        _pUpnpRender->Start();
        [self customService];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyDMRStarted object:nil];
    }

}

-(void)startUpnp
{
    if ([self isEnabled]) {
        [self performSelector:@selector(_startUpnp) withObject:nil afterDelay:3.0];
    }
    
}


-(bool)isRunning
{
    return _pUpnpRender->IsRunning();
}

-(void)reset
{
    if (!_mediaPanel) {
        _mediaPanel = [[MediaPanel alloc]init];
    }
    
    
    // Setup a media renderer.
    if (!pRenderer) {
        pRenderer = new PLT_MediaRenderer([[UIDevice currentDevice] name].UTF8String, false);
    }
    
    pRenderer->SetByeByeFirst(false);
    
    delegateCPP.owner = self;
    pRenderer->SetDelegate(&delegateCPP);
    PLT_DeviceHostReference device( pRenderer);
    
    _pUpnpRender = new PLT_UPnP;
    _pUpnpRender->AddDevice(device);
}

-(void)customService
{
    // export some service to change.
    NSAssert(_pUpnpRender->IsRunning(), nil);
    
    if (_serviceAVTransport) {
        //already done.
        return;
    }
    
    NPT_Array<PLT_Service*> services = pRenderer->GetServices();
    int c = services.GetItemCount();
    for (int i = 0; i < c; i++) {
        PLT_Service *s = services[i];
        NPT_String sid = s->GetServiceID();
        if ( sid.Compare("urn:upnp-org:serviceId:AVTransport",true) == 0)
        {
            _serviceAVTransport = s;
        }
        else if( sid.Compare("urn:upnp-org:serviceId:RenderingControl",true) == 0)
        {
            _serviceRenderingControl = s;
        }
        else if ( sid.Compare("urn:upnp-org:serviceId:ConnectionManager",true) == 0)
        {
            _serviceConnectionManager = s;
        }
    }
    
    
    // Add support of some media format
    NPT_String sinkProtocalInfo;
    _serviceConnectionManager->GetStateVariableValue("SinkProtocolInfo",sinkProtocalInfo);
    
    sinkProtocalInfo.Append(
                            ",http-get:*:video/quicktime:*"
                            ",http-get:*:video/mp4:*"
                            ",http-get:*:application/vnd.rn-realmedia-vbr:*"
                            ",http-get:*:image/png:DLNA.ORG_PN=PNG_LRG"
                            ",http-get:*:image/tiff:DLNA.ORG_PN=TIFF_LRG"
                            ",http-get:*:image/gif:DLNA.ORG_PN=GIF_LRG"
                            ",http-get:*:audio/mp4:DLNA.ORG_PN=AAC_ISO;DLNA.ORG_OP=01;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=01500000000000000000000000000000"
                            ",http-get:*:audio/wav:*"
                            );
    
    _serviceConnectionManager->SetStateVariable("SinkProtocolInfo", sinkProtocalInfo);
}

#pragma mark - MediaRendererDelegate

-(void)OnGetCurrentConnectionInfo:(PLT_ActionReference*)action
{
    if (self.renderDelegate && [self.renderDelegate respondsToSelector:@selector(OnGetCurrentConnectionInfo:)])
        [self.renderDelegate OnGetCurrentConnectionInfo:action];
    
    if (self.renderDelegate2 && [self.renderDelegate2 respondsToSelector:@selector(OnGetCurrentConnectionInfo:)])
        [self.renderDelegate2 OnGetCurrentConnectionInfo:action];
}

// AVTransport
-(void) OnNext:(PLT_ActionReference*)action
{
    
    if (self.renderDelegate && [self.renderDelegate respondsToSelector:@selector(OnNext:)])
        [self.renderDelegate OnNext:action];
    
    if (self.renderDelegate2 && [self.renderDelegate2 respondsToSelector:@selector(OnNext:)])
        [self.renderDelegate2 OnNext:action];
}

-(void) OnPause:(PLT_ActionReference*)action
{
    
    if (self.renderDelegate && [self.renderDelegate respondsToSelector:@selector(OnPause:)])
        [self.renderDelegate OnPause:action];
    
    if (self.renderDelegate2 && [self.renderDelegate2 respondsToSelector:@selector(OnPause:)])
        [self.renderDelegate2 OnPause:action];
}

-(void) OnPlay:(PLT_ActionReference*)action
{
    
    if (self.renderDelegate && [self.renderDelegate respondsToSelector:@selector(OnPlay:)])
        [self.renderDelegate OnPlay:action];
    
    if (self.renderDelegate2 && [self.renderDelegate2 respondsToSelector:@selector(OnPlay:)])
        [self.renderDelegate2 OnPlay:action];
}

-(void) OnPrevious:(PLT_ActionReference*)action
{
    
    if (self.renderDelegate && [self.renderDelegate respondsToSelector:@selector(OnPrevious:)])
        [self.renderDelegate OnPrevious:action];
    
    if (self.renderDelegate2 && [self.renderDelegate2 respondsToSelector:@selector(OnPrevious:)])
        [self.renderDelegate2 OnPrevious:action];
}

-(void) OnSeek:(PLT_ActionReference*)action
{
    
    if (self.renderDelegate && [self.renderDelegate respondsToSelector:@selector(OnSeek:)])
        [self.renderDelegate OnSeek:action];
    
    if (self.renderDelegate2 && [self.renderDelegate2 respondsToSelector:@selector(OnSeek:)])
        [self.renderDelegate2 OnSeek:action];
}

-(void) OnStop:(PLT_ActionReference*)action
{
    if (self.renderDelegate && [self.renderDelegate respondsToSelector:@selector(OnStop:)])
        [self.renderDelegate OnStop:action];
    
    if (self.renderDelegate2 && [self.renderDelegate2 respondsToSelector:@selector(OnStop:)])
        [self.renderDelegate2 OnStop:action];
    
}

-(void) OnSetAVTransportURI:(PLT_ActionReference*)action
{
    if (self.renderDelegate && [self.renderDelegate respondsToSelector:@selector(OnSetAVTransportURI:)])
        [self.renderDelegate OnSetAVTransportURI:action];
    
    
    if (self.renderDelegate2 && [self.renderDelegate2 respondsToSelector:@selector(OnSetAVTransportURI:)])
        [self.renderDelegate2 OnSetAVTransportURI:action];
    
}

-(void) OnSetPlayMode:(PLT_ActionReference*)action
{
    
    if (self.renderDelegate && [self.renderDelegate respondsToSelector:@selector(OnSetPlayMode:)])
        [self.renderDelegate OnSetPlayMode:action];
    
    if (self.renderDelegate2 && [self.renderDelegate2 respondsToSelector:@selector(OnSetPlayMode:)])
        [self.renderDelegate2 OnSetPlayMode:action];
}

// RenderingControl
-(void) OnSetVolume:(PLT_ActionReference*)action
{
    
    if (self.renderDelegate && [self.renderDelegate respondsToSelector:@selector(OnSetVolume:)])
        [self.renderDelegate OnSetVolume:action];
    
    if (self.renderDelegate2 && [self.renderDelegate2 respondsToSelector:@selector(OnSetVolume:)])
        [self.renderDelegate2 OnSetVolume:action];
}

-(void) OnSetVolumeDB:(PLT_ActionReference*)action
{
    
    if (self.renderDelegate && [self.renderDelegate respondsToSelector:@selector(OnSetVolumeDB:)])
        [self.renderDelegate OnSetVolumeDB:action];
    
    if (self.renderDelegate2 && [self.renderDelegate2 respondsToSelector:@selector(OnSetVolumeDB:)])
        [self.renderDelegate2 OnSetVolumeDB:action];
}

-(void) OnGetVolumeDBRange:(PLT_ActionReference*)action
{
    
    if (self.renderDelegate && [self.renderDelegate respondsToSelector:@selector(OnGetVolumeDBRange:)])
        [self.renderDelegate OnGetVolumeDBRange:action];
    
    if (self.renderDelegate2 && [self.renderDelegate2 respondsToSelector:@selector(OnGetVolumeDBRange:)])
        [self.renderDelegate2 OnGetVolumeDBRange:action];
}

-(void) OnSetMute:(PLT_ActionReference*)action
{
    
    if (self.renderDelegate && [self.renderDelegate respondsToSelector:@selector(OnSetMute:)])
        [self.renderDelegate OnSetMute:action];
    
    if (self.renderDelegate2 && [self.renderDelegate2 respondsToSelector:@selector(OnSetMute:)])
        [self.renderDelegate2 OnSetMute:action];
}

-(void)notifyMediaPanelStateChanged
{
    if ([self isRunning])
    {
        // the service pointer may point to invalid object when upnp restarted?
        MAAssert( _serviceRenderingControl->GetDevice() );
        write_to_state_variable(_mediaPanel, _serviceAVTransport,_serviceRenderingControl);
    }
}

@end



void write_to_state_variable(MediaPanel *mediaPanel,PLT_Service *serviceAVTransport,PLT_Service *serviceRenderingControl)
{
    char volume[5] = {0};
    sprintf(volume, "%d" , mediaPanel.volume);
    serviceRenderingControl->SetStateVariable("Volume", volume);
    
    serviceRenderingControl->SetStateVariable("Mute", mediaPanel.mute?"1":"0" );

    if (mediaPanel.trackPosition) {
        serviceAVTransport->SetStateVariable("RelativeTimePosition", mediaPanel.trackPosition.UTF8String );
    }
    
    if (mediaPanel.trackDuration) {
        serviceAVTransport->SetStateVariable("CurrentTrackDuration", mediaPanel.trackDuration.UTF8String );
    }
    
    serviceAVTransport->SetStateVariable("TransportState", kStrPlayState[mediaPanel.playState] );
}
