//
//  DlnaControlPoint.mm
//  demo
//
//  Created by liaogang on 15/6/10.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "DlnaControlPoint.h"
#import <UIKit/UIKit.h>
#import "DemoReachability.h"


void read_from_state_variable(MediaPanel *mediaPanel, NPT_List<PLT_StateVariable*>* vars);

void eventHandler(enum event_name eventName,void *result,void* event_custom_data);



@interface DlnaControlPoint ()
{
    dispatch_source_t	_timer;
}

@property (nonatomic,strong) DemoReachability* reachabilityForLocalWiFi;

@property (nonatomic,copy) RenderMediaStateChanged renderMediaStateChanged;

@property (nonatomic,copy) Callback callbackMediaSelected,mediaAndRenderReady,sourceListChanged,renderlistChanged;

-(void)eventHandler:(enum event_name)eventName :(void *)result;

@end

@implementation DlnaControlPoint

-(void)eventHandler:(enum event_name)eventName :(void *)result
{
    switch (eventName) {
        case event_media_selected:
        {
            if (_callbackMediaSelected)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _callbackMediaSelected();
                });
            }
            else
            {
                NSLog(@"no renderer selected,pop a renderer in the callback [DlnaControllPoint setCallback_MediaSelected] or select one by yourself");
            }
            
            break;
        }
        case event_rendering_control_response:
        {
            eventDataRenderControlResponse *d = (eventDataRenderControlResponse*)result;
            [self renderingControlResponse: d];
            break;
        }
        case event_state_variables_changed:
        {
            eventDataStateVariables *d = (eventDataStateVariables*)result;
            
            [self MRStateVariablesChanged:d];
            
            break;
        }
        case event_render_and_media_selected:
        {
            if (_mediaAndRenderReady)
            {
                self.pController->HandleCmd_getMute();
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    _mediaAndRenderReady();
                });
            }
            
            break;
        }
        case event_render_list_changed:
        {
            if (_renderlistChanged)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _renderlistChanged();
                });
            }
            break;
        }
        case event_media_server_list_changed:
        {
            if (_sourceListChanged)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _sourceListChanged();
                });
            }
            break;
        }
        default:
            break;
    }
}

+(instancetype)shared
{
    static DlnaControlPoint *sharedDlnaControlPoint = nil;

    if (sharedDlnaControlPoint == nil) {
        sharedDlnaControlPoint = [[DlnaControlPoint alloc]initPrivate];
    }
    
    return sharedDlnaControlPoint;
}


-(void)stopUpnp
{
    if(_pUpnpControl->IsRunning())
    {
        NSLog(@"control point-> stop upnp.");
        _pUpnpControl->Stop();
    }
}

-(void)_startUpnp
{
    if( ! _pUpnpControl->IsRunning())
    {
        NSLog(@"control point-> start upnp.");
        _pUpnpControl->Start();
    }
}

-(void)startUpnp
{
    [self performSelector:@selector(_startUpnp) withObject:nil afterDelay:2.0];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        NSAssert(false, @"use the shared instance.");

    }
    return self;
}

-(void)reset
{
    _mediaPanel = [[MediaPanel alloc]init];

    
    
    if (self.pUpnpControl) {
        self.pUpnpControl->Stop();
        delete _pUpnpControl;
        _pUpnpControl = NULL;
    }
    

    _pController = NULL;
    
    if (_pCtrlPoint)
    {
        delete _pCtrlPoint;
        _pCtrlPoint = NULL;
    }
    
    
    // setup Neptune logging
    {
        NPT_LogManager::GetDefault().SetEnabled(false);
//        NPT_LogManager::GetDefault().Configure("plist:.level=FINE;.handlers=ConsoleHandler;.ConsoleHandler.colors=off;.ConsoleHandler.filter=24");
        
        // Create upnp engine
        _pUpnpControl = new PLT_UPnP;
        
        // Create control point
        _pCtrlPoint = new PLT_CtrlPoint();
        PLT_CtrlPointReference rCtrlPoint(_pCtrlPoint);
        
        // Create controller
        _pController = new PLT_MicroMediaController (rCtrlPoint);
        
        // add control point to upnp engine and start it
        self.pUpnpControl->AddCtrlPoint(rCtrlPoint);
        self.pUpnpControl->Start();
        
        _pController->startSearchDevices();
        
        _pController->setEventNotifyHandler(eventHandler, (__bridge void*)self);
    }
    
    
    
#ifdef BROADCAST_EXTRA
    // tell control point to perform extra broadcast discover every 6 secs
    // in case our device doesn't support multicast
    ctrlPoint->Discover(NPT_HttpUrl("255.255.255.255", 1900, "*"), "upnp:rootdevice", 1, 6000);
    ctrlPoint->Discover(NPT_HttpUrl("239.255.255.250", 1900, "*"), "upnp:rootdevice", 1, 6000);
#endif
    
   
}

-(instancetype)initPrivate
{
    self = [super init];
    if (self) {
        [self reset];
        
        // Update the UI 3 times per second
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, NSEC_PER_SEC / 2, NSEC_PER_SEC / 3);
        
        dispatch_source_set_event_handler(_timer, ^{
            if (_mediaPanel.playState == PlayState_playing) {
                _pController->HandleCmd_getPositionInfo();
            }
        });
        
        // Start the timer
        dispatch_resume(_timer);
        
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localWiFiChanged:) name:kReachabilityChangedNotificationForDemo object:nil];
        
        self.reachabilityForLocalWiFi = [DemoReachability reachabilityForLocalWiFi];
        [self.reachabilityForLocalWiFi startNotifier];
        

        
    }
    
    return self;
}

-(void)dealloc
{
    // Stop everything
    if (self.pUpnpControl) {
    self.pUpnpControl->Stop();
        delete _pUpnpControl;
    }
    
    if (_pController)
        delete _pController;
    
    if (_pCtrlPoint)
        delete _pCtrlPoint;
}

-(void)localWiFiChanged:(NSNotification*)n
{
    DemoReachability *r = n.object;
    auto result = r.currentReachabilityStatus;
    
    
    static NSInteger lastStatus =  -1;
    
    if (result != lastStatus) {
        if( result != DemoNotReachable)
        {
            NSLog(@"control point-> wifi changed.");
            [self startUpnp];
        }
        else
        {
            [self stopUpnp];
        }
        
        lastStatus = result;
    }
    
}

-(void)setCallback_RenderMediaStateChanged:(RenderMediaStateChanged)renderMediaStateChanged
{
    _renderMediaStateChanged = renderMediaStateChanged;
}

-(void)setCallback_MediaSelected:(Callback)callback
{
    _callbackMediaSelected = callback;
}

-(void)setCallback_MediaAndRenderReady:(Callback)callback
{
    _mediaAndRenderReady = callback;
}

-(void)setCallback_deviceListChanged:(Callback)callback
{
    _sourceListChanged = callback;
}

-(void)setCallback_renderListChanged:(Callback)callback
{
    _renderlistChanged = callback;
}

-(void)MRStateVariablesChanged:(eventDataStateVariables*)d
{
    read_from_state_variable(_mediaPanel, (NPT_List<PLT_StateVariable*>*)d);
    
    if(_renderMediaStateChanged)
    {
        MediaPanel*  mp = [[MediaPanel alloc]init];
        
        mp.trackPosition = _mediaPanel.trackPosition ;
        mp.trackDuration = _mediaPanel.trackDuration;
        mp.playState = _mediaPanel.playState;
        
        if (mp.playState == PlayState_stopped) {
            self.pController->clearPlayingMediaTitle();
        }
        
        mp.volume = _mediaPanel.volume;
        mp.mute = _mediaPanel.mute;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _renderMediaStateChanged(mp);
        });
    }
    
}

-(void)renderingControlResponse:(eventDataRenderControlResponse*)d
{
    const char *name = d->actionName;
    void* result = d->result;
    
    if (!result) {
        return;
    }
    
    if ( strcmp(name,"GetVolume") == 0) {
        NPT_UInt32	volume;
        volume = *(NPT_UInt32*)result;
        
        _mediaPanel.volume = volume;
        
    }
    else if ( strcmp(name,"GetPositionInfo") == 0) {
        PLT_PositionInfo info = *(PLT_PositionInfo*)result;
        int sec = (int)info.track_duration.ToSeconds();
        
        _mediaPanel.trackDuration = [NSString stringWithUTF8String: dlna_second_to_stirng(sec)];
        
        _mediaPanel.trackPosition = [NSString stringWithUTF8String: dlna_second_to_stirng( (int)info.rel_time.ToSeconds()) ];
    }
    else if ( strcmp(name,"GetMute") == 0) {
        bool mute = *(bool*)result;
        
        _mediaPanel.mute = mute;
    }
    
    
    if(_renderMediaStateChanged)
    {
        MediaPanel*  mp = [[MediaPanel alloc]init];
        
        mp.trackPosition = _mediaPanel.trackPosition ;
        mp.trackDuration = _mediaPanel.trackDuration;
        mp.playState = _mediaPanel.playState;
        mp.volume = _mediaPanel.volume;
        mp.mute = _mediaPanel.mute;
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _renderMediaStateChanged(mp);
        });
    }
    
}

@end


void read_from_state_variable(MediaPanel *mediaPanel, NPT_List<PLT_StateVariable*>* vars)
{
    NPT_List<PLT_StateVariable*>::Iterator var = vars->GetFirstItem();
    while (var)
    {
        NPT_String name = (*var)->GetName();
        NPT_String value = (*var)->GetValue();
        
        if ( name.Compare("Volume" ,true) == 0) {
            
            unsigned int volume = 0;
            
            sscanf( (*var)->GetValue(), "%ud" , &volume);
            
            mediaPanel.volume =  volume;
            
        }
        else if (name.Compare("Mute",true) == 0)
        {
            mediaPanel.mute = value == "1" ? TRUE : FALSE;
        }
        else if (name.Compare("TransportState",true) == 0 )
        {
            if ( value == kStrPlayState[PlayState_stopped] ) {
                mediaPanel.playState = PlayState_stopped;
            }
            else if (value == kStrPlayState[PlayState_playing] )
            {
                mediaPanel.playState = PlayState_playing;
            }
            else if ( value == kStrPlayState[PlayState_paused] )
            {
                mediaPanel.playState = PlayState_paused;
            }
            else if (value == kStrPlayState[PlayState_unknown] )
            {
                mediaPanel.playState = PlayState_unknown;
            }
            
        }
        
        
        ++var;
    }
    
}

void eventHandler(enum event_name eventName,void *result,void* event_custom_data)
{
    DlnaControlPoint *cp = (__bridge DlnaControlPoint*)event_custom_data;
    [cp eventHandler:eventName :result];
}
