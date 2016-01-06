//
//  DlnaControlPoint.h
//  demo
//
//  Created by liaogang on 15/6/10.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Platinum/Platinum.h>
#include "PltMicroMediaController.h"
#import "MediaPanel.h"


typedef void(^RenderMediaStateChanged)(MediaPanel *mediaPanel);
typedef void(^Callback)(void);


/**  
 A DLNA Control pointer manager
 
 1. Media Server  ==> Control Point ==>   Media Render
 2: Receive state from Media Render
 */
@interface DlnaControlPoint : NSObject

+(instancetype)shared;

/// delete the shared instance and recreate a new one.

-(void)stopUpnp;

-(void)startUpnp;

@property (nonatomic,readonly,assign) PLT_UPnP *pUpnpControl;

@property (nonatomic,readonly,assign) PLT_MicroMediaController *pController;

@property (nonatomic,readonly,assign) PLT_CtrlPoint *pCtrlPoint;

@property (nonatomic,readonly) MediaPanel *mediaPanel;

/**
 当前正在控制的Render播放状态已发生改变。
 更新控制点界面
 */
-(void)setCallback_RenderMediaStateChanged:(RenderMediaStateChanged)renderMediaStateChanged;

/**
 源媒体已指定而Render未指定。
 引导客户​指定Render.
 */
-(void)setCallback_MediaSelected:(Callback)callback;


/**
 源媒体与Render均已就绪.
 Control point可以控制播放了.
 */
-(void)setCallback_MediaAndRenderReady:(Callback)callback;

/**
 源列表已更新
 */
-(void)setCallback_deviceListChanged:(Callback)callback;

/**
 Render列表已更新
 */
-(void)setCallback_renderListChanged:(Callback)callback;

@end

