//
//  DlnaRender.h
//  demo
//
//  Created by liaogang on 15/6/30.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Platinum/Platinum.h>
#import "MediaRendererDelegate.h"
#import "MediaPanel.h"

/**
 should call [[NSUserDefaults standardUserDefaults] synchronize] when applicationDidEnterBackground
 */
@interface DlnaRender : NSObject

+(instancetype)shared;

-(void)stopUpnp;

-(void)startUpnp;

-(bool)isRunning;

-(void)disable;
-(void)enable;
-(bool)isDisabled;
-(bool)isEnabled;


@property (nonatomic,strong) MediaPanel *mediaPanel;

@property (nonatomic,weak) id<MediaRendererDelegate> renderDelegate,renderDelegate2;

-(void)notifyMediaPanelStateChanged;

@property (nonatomic,readonly,assign) PLT_Service *serviceAVTransport, *serviceRenderingControl, *serviceConnectionManager;

@end

extern NSString *kKeyRenderEnabled;

extern NSString *kNotifyDMRStopped;

extern NSString *kNotifyDMRStarted;
