//
//  MediaRendererDelegate.m
//  demo
//
//  Created by liaogang on 15/6/8.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "MediaRendererDelegate.h"



PLT_MediaRendererDelegateMy::~PLT_MediaRendererDelegateMy()
{
    
}

// ConnectionManager
NPT_Result PLT_MediaRendererDelegateMy::OnGetCurrentConnectionInfo(PLT_ActionReference& action) {
    dispatch_sync( dispatch_get_main_queue() , ^{
        [owner OnGetCurrentConnectionInfo:&action];
    });
    return NPT_SUCCESS;
}

// AVTransport
NPT_Result PLT_MediaRendererDelegateMy::OnNext(PLT_ActionReference& action) {
    dispatch_sync( dispatch_get_main_queue() , ^{
        [owner OnNext:&action];
    });
    return NPT_SUCCESS;
}

NPT_Result PLT_MediaRendererDelegateMy::OnPause(PLT_ActionReference& action) {
    dispatch_sync( dispatch_get_main_queue() , ^{
        [owner OnPause:&action];
    });
    return NPT_SUCCESS;
}

NPT_Result PLT_MediaRendererDelegateMy::OnPlay(PLT_ActionReference& action) {
    dispatch_sync( dispatch_get_main_queue() , ^{
        [owner OnPlay:&action];
    });
    return NPT_SUCCESS;
}

NPT_Result PLT_MediaRendererDelegateMy::OnPrevious(PLT_ActionReference& action) {
    dispatch_sync( dispatch_get_main_queue() , ^{
        [owner OnPrevious:&action];
    });
    return NPT_SUCCESS;
}

NPT_Result PLT_MediaRendererDelegateMy::OnSeek(PLT_ActionReference& action) {
    dispatch_sync( dispatch_get_main_queue() , ^{
        [owner OnSeek:&action];
    });
    return NPT_SUCCESS;
}

NPT_Result PLT_MediaRendererDelegateMy::OnStop(PLT_ActionReference& action) {
    dispatch_sync( dispatch_get_main_queue() , ^{
        [owner OnStop:&action];
    });
    return NPT_SUCCESS;
}

NPT_Result PLT_MediaRendererDelegateMy::OnSetAVTransportURI(PLT_ActionReference& action) {
    dispatch_sync( dispatch_get_main_queue() , ^{
        [owner OnSetAVTransportURI:&action];
    });
    return NPT_SUCCESS;
}

NPT_Result PLT_MediaRendererDelegateMy::OnSetPlayMode(PLT_ActionReference& action) {
    dispatch_sync( dispatch_get_main_queue() , ^{
        [owner OnSetPlayMode:&action];
    });
    return NPT_SUCCESS;
}

// RenderingControl
NPT_Result PLT_MediaRendererDelegateMy::OnSetVolume(PLT_ActionReference& action) {
    dispatch_sync( dispatch_get_main_queue() , ^{
        [owner OnSetVolume:&action];
    });
    return NPT_SUCCESS;
}

NPT_Result PLT_MediaRendererDelegateMy::OnSetVolumeDB(PLT_ActionReference& action) {
    dispatch_sync( dispatch_get_main_queue() , ^{
        [owner OnSetVolumeDB:&action];
    });
    return NPT_SUCCESS;
}

NPT_Result PLT_MediaRendererDelegateMy::OnGetVolumeDBRange(PLT_ActionReference& action){
    dispatch_sync( dispatch_get_main_queue() , ^{
        [owner OnGetVolumeDBRange:&action];
    });
    return NPT_SUCCESS;
}

NPT_Result PLT_MediaRendererDelegateMy::OnSetMute(PLT_ActionReference& action) {
    dispatch_sync( dispatch_get_main_queue() , ^{
        [owner OnSetMute:&action];
    });
    return NPT_SUCCESS;
}



