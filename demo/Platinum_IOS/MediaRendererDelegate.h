//
//  MediaRendererDelegate.h
//  demo
//
//  Created by liaogang on 15/6/8.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <Platinum/Platinum.h>

@protocol MediaRendererDelegate <NSObject>
@optional
-(void)OnGetCurrentConnectionInfo:(PLT_ActionReference*)action;

// AVTransport
-(void) OnNext:(PLT_ActionReference*)action;
-(void) OnPause:(PLT_ActionReference*)action;
-(void) OnPlay:(PLT_ActionReference*)action;
-(void) OnPrevious:(PLT_ActionReference*)action;
-(void) OnSeek:(PLT_ActionReference*)action;
-(void) OnStop:(PLT_ActionReference*)action;
-(void) OnSetAVTransportURI:(PLT_ActionReference*)action;
-(void) OnSetPlayMode:(PLT_ActionReference*)action;

// RenderingControl
-(void) OnSetVolume:(PLT_ActionReference*)action;
-(void) OnSetVolumeDB:(PLT_ActionReference*)action;
-(void) OnGetVolumeDBRange:(PLT_ActionReference*)action;
-(void) OnSetMute:(PLT_ActionReference*)action;
@end


class PLT_MediaRendererDelegateMy : public PLT_MediaRendererDelegate
{
public:
    __weak id<MediaRendererDelegate> owner;
public:
    ~PLT_MediaRendererDelegateMy();
    
    // ConnectionManager
    NPT_Result OnGetCurrentConnectionInfo(PLT_ActionReference& action) ;
    
    // AVTransport
    NPT_Result OnNext(PLT_ActionReference& action) ;
    NPT_Result OnPause(PLT_ActionReference& action);
    NPT_Result OnPlay(PLT_ActionReference& action) ;
    NPT_Result OnPrevious(PLT_ActionReference& action) ;
    NPT_Result OnSeek(PLT_ActionReference& action) ;
    NPT_Result OnStop(PLT_ActionReference& action) ;
    NPT_Result OnSetAVTransportURI(PLT_ActionReference& action) ;
    NPT_Result OnSetPlayMode(PLT_ActionReference& action) ;
    
    // RenderingControl
    NPT_Result OnSetVolume(PLT_ActionReference& action) ;
    NPT_Result OnSetVolumeDB(PLT_ActionReference& action) ;
    NPT_Result OnGetVolumeDBRange(PLT_ActionReference& action) ;
    NPT_Result OnSetMute(PLT_ActionReference& action) ;
};




