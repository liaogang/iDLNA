//
//  PltMediaServerObject.h
//  demo
//
//  Created by geine on 6/15/15.
//  Copyright (c) 2015 com.cs. All rights reserved.
//

#include <UIKit/UIKit.h>
#import <Platinum/Platinum.h>
#import <Platinum/PltUPnPObject.h>


// define
#if !defined(_PLATINUM_H_)
typedef class PLT_HttpRequestContext PLT_HttpRequestContext;
typedef class NPT_HttpResponse NPT_HttpResponse;
#endif


/**
    CDS目录与id 对应 结构关系.
    根目录用"0"表示(DLNA标准).
 
    第二级 , "Browser Folders":浏览本地文件入口 ,"Music":音频,"Video":视频,"Photo":图片
 
    各父目录与子目录之间用文件分隔符"/"来分隔.
 */




/*----------------------------------------------------------------------
 |   PLT_MediaServerObject
 +---------------------------------------------------------------------*/
@interface PLT_MediaServerObjectMy : PLT_DeviceHostObject {}

@property (nonatomic, weak) id delegate; // we do not retain to avoid circular ref count

- (id)initServerWithPath:(NSString *)thePath andServerName:(NSString *)theServerName;
- (id)initServerSelfDelegateWithServerName:(NSString *)theServerName ;

@end

/*----------------------------------------------------------------------
 |   PLT_MediaServerBrowseCapsule
 +---------------------------------------------------------------------*/
@interface PLT_MediaServerBrowseCapsuleMy : PLT_ActionObject {
    NPT_UInt32              start;
    NPT_UInt32              count;
    PLT_HttpRequestContext* context;
}

- (id)initWithAction:(PLT_Action*)action objectId:(const char*)_id full_id:(const char*)_full_id filter:(const char*)_filter start:(NPT_UInt32)_start count:(NPT_UInt32)_count sort:(const char*)_sort context:(PLT_HttpRequestContext*)_context;

//- (id)initWithAction:(PLT_Action*)action objectId:(const char*)objectId filter:(const char*)filter start:(NPT_UInt32)start count:(NPT_UInt32)count sort:(const char*)sort context:(PLT_HttpRequestContext*)context;


- (PLT_HttpRequestContext *)getContext ;

@property (readonly, strong) NSString* objectId;
@property (readonly, strong) NSString* objectId_full;
@property (readonly) NPT_UInt32 start;
@property (readonly) NPT_UInt32 count;
@property (readonly, strong) NSString* filter;
@property (readonly, strong) NSString* sort;
@end

/*----------------------------------------------------------------------
 |   PLT_MediaServerSearchCapsule
 +---------------------------------------------------------------------*/
@interface PLT_MediaServerSearchCapsuleMy : PLT_MediaServerBrowseCapsuleMy {}

- (id)initWithAction:(PLT_Action*)action objectId:(const char*)objectId search:(const char*)search filter:(const char*)filter start:(NPT_UInt32)start count:(NPT_UInt32)count sort:(const char*)sort context:(PLT_HttpRequestContext*)context;

@property (readonly, strong) NSString* search;
@end

/*----------------------------------------------------------------------
 |   PLT_MediaServerFileRequestCapsule
 +---------------------------------------------------------------------*/
@interface PLT_MediaServerFileRequestCapsuleMy : NSObject {
    NPT_HttpResponse*       response;
    PLT_HttpRequestContext* context;
    NPT_HttpRequest *request;
}

- (id)initWithResponse:(NPT_HttpResponse*)response context:(PLT_HttpRequestContext*)context request:(NPT_HttpRequest*)request;

- (NPT_HttpResponse *)getResponse;
- (PLT_HttpRequestContext *)getContext;
-(NPT_HttpRequest*)getRequest;
@end

/*----------------------------------------------------------------------
 |   PLT_MediaServerDelegateObject
 +---------------------------------------------------------------------*/
@protocol PLT_MediaServerDelegateObject
- (NPT_Result)onBrowseMetadata:(PLT_MediaServerBrowseCapsuleMy*)info;
- (NPT_Result)onBrowseDirectChildren:(PLT_MediaServerBrowseCapsuleMy*)info;
- (NPT_Result)onSearchContainer:(PLT_MediaServerSearchCapsuleMy*)info;
- (NPT_Result)onFileRequest:(PLT_MediaServerFileRequestCapsuleMy*)info withURL:(NSString *)theURL;
@end





/*----------------------------------------------------------------------
 |   PLT_FileMediaConnectDelegate class
 +---------------------------------------------------------------------*/
class PLT_LocalMediaFileDelegate : public PLT_FileMediaConnectDelegate
{
public:
    // constructor & destructor
    PLT_LocalMediaFileDelegate(const char* url_root, const char* file_root) :
    PLT_FileMediaConnectDelegate(url_root, file_root) {}
    virtual ~PLT_LocalMediaFileDelegate() {}
    
    // PLT_FileMediaServerDelegate methods
    virtual bool ProcessFile(const NPT_String& filepath, const char* filter = NULL) ;
    
};

