//
//  UPnPEngine.m
//  demo
//
//  Created by geine on 6/16/15.
//  Copyright (c) 2015 com.cs. All rights reserved.
//

#import "UPnPEngine.h"
#import "util.h"
#import "Macro.h"
#import <Platinum/Platinum.h>
#import <Platinum/PltUPnPObject.h>
#import "PltMediaServerObjectMy.h"
#import "DemoReachability.h"

NSString *kKeyDMS_enabled = @"Dlna_DMS_enabled";

NSString *kNotifyDMSStopped = @"dms_stopped";

NSString *kNotifyDMSStarted = @"dms_started";

@interface UPnPEngine ()
{
    PLT_UPnPObject* upnp;
    PLT_MediaServerObjectMy* rootServer;
}

@property (nonatomic,strong) DemoReachability* reachabilityForLocalWiFi;

- (void)initUPnP;
@end

@implementation UPnPEngine
-(instancetype)init
{
    self = [super init];
    if (self) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localWiFiChanged:) name:kReachabilityChangedNotificationForDemo object:nil];
        
        self.reachabilityForLocalWiFi = [DemoReachability reachabilityForLocalWiFi];
        [self.reachabilityForLocalWiFi startNotifier];
    }
    return self;
}

-(void)disable
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey: kKeyDMS_enabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if ([self isRunning]) {
        [self stopUPnP];
    }
}

-(void)enable
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey: kKeyDMS_enabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if(![self isRunning])
        [self startUPnP];
}

-(bool)isDisabled
{
    return ![self isEnabled];
}

-(bool)isEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey: kKeyDMS_enabled];
}

-(void)localWiFiChanged:(NSNotification*)n
{
    DemoReachability *r = n.object;
    auto result = r.currentReachabilityStatus;
    
    
    static NSInteger lastStatus =  -1;
    
    if (result != lastStatus) {
        if( result != DemoNotReachable)
        {
            [self startUPnP];
        }
        else
        {
            [self stopUPnP];
        }
        
        lastStatus = result;
    }
    
}


+ (instancetype)getEngine
{
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}

- (void)initUPnP {
    if (!upnp) {
        upnp = [[PLT_UPnPObject alloc] init];
    }
}

-(void)intendStartRootFileServer
{
    [self initUPnP];
    
    rootServer = [[PLT_MediaServerObjectMy alloc] initServerSelfDelegateWithServerName:@"Media Server"];
    
    [upnp addDevice:rootServer];
}

- (BOOL)isRunning {
    return upnp.isRunning;
}


-(BOOL)_startUpnp
{
    printf("dms start upnp\n");
    NPT_Result result = [upnp start];
    if (NPT_FAILED(result)) {
        return NO;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyDMSStarted object:nil];
    
    return YES;
}


-(void)startUPnP
{
    if ([self isEnabled]) {
        [self performSelector:@selector(_startUpnp) withObject:nil afterDelay:3.0];
    }
}


- (void)stopUPnP {
    if ([upnp isRunning]) {
        [upnp stop];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyDMSStopped object:nil];
        printf("dms stop upnp\n");
    }
    
}

@end
