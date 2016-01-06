//
//  PltMediaServerObject.m
//  demo
//
//  Created by geine on 6/15/15.
//  Copyright (c) 2015 com.cs. All rights reserved.
//

#import "PltMediaServerObjectMy.h"
#define PATH_DEVICE_TEMP_RESOURCE @"DIRTEMPFORPLAY"
#import "Util.h"
#import "MAAssert.h"
#import "photosDMSDelegate.h"
#import "ItunesMusicDMSDelegate.h"



const char root_name_folder[] = "Browse Folders";
const char root_name_music[] = "Music";
const char root_name_video[] = "Video";
const char root_name_photo[] = "Photo";

const char str_root_id_folder[] = "root_id_folders";




class PLT_FileMediaServerDelegateMy : PLT_FileMediaServerDelegate
{
public:
    PLT_FileMediaServerDelegateMy(const char* url_root, const char* file_root):PLT_FileMediaServerDelegate(url_root,file_root)
    {
    }
    
    NPT_Result
    OnBrowseDirectChildren(PLT_ActionReference&          action,
                           const char*                   object_id,
                           const char*                   filter,
                           NPT_UInt32                    starting_index,
                           NPT_UInt32                    requested_count,
                           const char*                   sort_criteria,
                           const PLT_HttpRequestContext& context)
    {
        return PLT_FileMediaServerDelegate::OnBrowseDirectChildren(action, object_id, filter, starting_index, requested_count, sort_criteria, context);
    }
    

    NPT_Result
    ProcessFileRequest(NPT_HttpRequest& request, const NPT_HttpRequestContext& context, NPT_HttpResponse& response)
    {
        return PLT_FileMediaServerDelegate::ProcessFileRequest(request, context, response);
    }
    
    NPT_Result
    ExtractResourcePath(const NPT_HttpUrl& url, NPT_String& file_path)
    {
        return PLT_FileMediaServerDelegate::ExtractResourcePath(url, file_path);
    }
};

/*----------------------------------------------------------------------
 |   PLT_MediaServerDelegate_Wrapper
 +---------------------------------------------------------------------*/
class PLT_MediaServerDelegate_Wrapper : public PLT_MediaServerDelegate
{
public:
    PLT_MediaServerDelegate_Wrapper(PLT_MediaServerObjectMy* target)
    {
        fileDelegate =  new PLT_FileMediaServerDelegateMy("/",[[Util sharedInstance] getDocumentPath].UTF8String);
        
        photoDMSDelegate = [[photosDMSDelegate alloc] init];
        
        itunesMusicDMSDelegate = [[ItunesMusicDMSDelegate alloc]init];
    }
    
    ~PLT_MediaServerDelegate_Wrapper()
    {
        itunesMusicDMSDelegate = nil;
        photoDMSDelegate = nil;
        delete fileDelegate;
    }
    
    NPT_Result OnBrowseMetadata(PLT_ActionReference&          action,
                                const char*                   object_id,
                                const char*                   filter,
                                NPT_UInt32                    starting_index,
                                NPT_UInt32                    requested_count,
                                const char*                   sort_criteria,
                                const PLT_HttpRequestContext& context)
    {
        /*
        if (![[m_Target delegate] respondsToSelector:@selector(onBrowseMetadata:)])
            return NPT_FAILURE;
        
        PLT_MediaServerBrowseCapsule* capsule =
        [[PLT_MediaServerBrowseCapsule alloc] initWithAction:action.AsPointer()
                                                    objectId:object_id
                                                      filter:filter
                                                       start:starting_index
                                                       count:requested_count
                                                        sort:sort_criteria
                                                     context:(PLT_HttpRequestContext*)&context];
        NPT_Result result = [[m_Target delegate] onBrowseMetadata:capsule];
        return result;
        */
        
        return NPT_FAILURE;
    }
    
    

    NPT_Result OnBrowseDirectChildren(PLT_ActionReference&          action,
                                      const char*                   object_id,
                                      const char*                   filter,
                                      NPT_UInt32                    starting_index,
                                      NPT_UInt32                    requested_count,
                                      const char*                   sort_criteria,
                                      const PLT_HttpRequestContext& context)
    {
        // is root ?
        if (  object_id[1] == 0 )
        {
            PLT_MediaObject* object =  new PLT_MediaContainer;
            
            ((PLT_MediaContainer*)object)->m_ChildrenCount = (NPT_Int32)-1;
            object->m_ObjectClass.type = "object.container.storageFolder";
            object->m_ParentID = "0";
            
            NPT_String filter2 (filter);
            NPT_String tmp;
            PLT_MediaObjectReference item (object);
            
            /// Browser Folders
            object->m_Title = root_name_folder;
            ((PLT_MediaContainer*)object)->m_ChildrenCount = (NPT_Int32)-1;
            object->m_ObjectID = "0/";
            object->m_ObjectID.Append(str_root_id_folder, sizeof(str_root_id_folder)-1);
            
            
            /// Music
            
            //But we can't export music in ios6..
            bool canExportMusic = [UIDevice currentDevice].systemVersion.floatValue >= 7.0;
            if ( canExportMusic ) {
                NPT_CHECK_SEVERE(PLT_Didl::ToDidl(*item.AsPointer(), filter , tmp));
                ((PLT_MediaContainer*)object)->m_ChildrenCount = (NPT_Int32) 2;
                object->m_Title = root_name_music;
                object->m_ObjectID = "0/";
                object->m_ObjectID.Append( getRootIdMusic() , getRootIdMusicLen() );
            }
            

            
            
            /// Video
            NPT_CHECK_SEVERE(PLT_Didl::ToDidl(*item.AsPointer(), filter , tmp));
            ((PLT_MediaContainer*)object)->m_ChildrenCount = (NPT_Int32)[photosDMSDelegate videoCount];
            object->m_Title = root_name_video;
            object->m_ObjectID = "0/";
            object->m_ObjectID.Append( getRootIdVideo() ,getRootIdVideoLen() );
            NPT_CHECK_SEVERE(PLT_Didl::ToDidl(*item.AsPointer(), filter , tmp));
            
            /// Photo
            object->m_Title = root_name_photo;
            ((PLT_MediaContainer*)object)->m_ChildrenCount = (NPT_Int32)[photosDMSDelegate groupCount];
            object->m_ObjectID = "0/";
            object->m_ObjectID.Append( getRootIdPhoto() , getRootIdPhotoLen() );
            NPT_CHECK_SEVERE(PLT_Didl::ToDidl(*item.AsPointer(), filter , tmp));
            
            
            NPT_String didl = didl_header + tmp + didl_footer;
            
            NPT_CHECK_SEVERE(action->SetArgumentValue("Result", didl));
            
            if (canExportMusic) {
                NPT_CHECK_SEVERE(action->SetArgumentValue("NumberReturned", "4" ));
                NPT_CHECK_SEVERE(action->SetArgumentValue("TotalMatches", "4")); // 0 means we don't know how many we have but most browsers don't like that!!
            }
            else {
                NPT_CHECK_SEVERE(action->SetArgumentValue("NumberReturned", "3" ));
                NPT_CHECK_SEVERE(action->SetArgumentValue("TotalMatches", "3"));
            }
            

            NPT_CHECK_SEVERE(action->SetArgumentValue("UpdateId", "1"));
            
            return  NPT_SUCCESS;
        }
        else
        {
            if(object_id[1] != '/')
            {
                printf("request object id error.\n");
                return NPT_FAILURE;
            }
            
            // --> "0/" -->
            const char *p = object_id+2;
            
            if ( strncmp(p, getRootIdPhoto(), getRootIdPhotoLen()) == 0 || strncmp(p, getRootIdVideo(), getRootIdVideoLen()) == 0 )
            {
                // is photo or video?
                
                PLT_MediaServerBrowseCapsuleMy* capsule =
                [[PLT_MediaServerBrowseCapsuleMy alloc] initWithAction:action.AsPointer()
                                                            objectId:p
                                                             full_id:object_id
                                                              filter:filter
                                                               start:starting_index
                                                               count:requested_count
                                                                sort:sort_criteria
                                                             context:(PLT_HttpRequestContext*)&context];
                
                return [photoDMSDelegate onBrowseDirectChildren: capsule];
            }
            else if ( strncmp(p, getRootIdMusic(), getRootIdMusicLen()) == 0 )
            {
                // is music?
                
                PLT_MediaServerBrowseCapsuleMy* capsule =
                [[PLT_MediaServerBrowseCapsuleMy alloc] initWithAction:action.AsPointer()
                                                            objectId:p
                                                             full_id:object_id
                                                              filter:filter
                                                               start:starting_index
                                                               count:requested_count
                                                                sort:sort_criteria
                                                             context:(PLT_HttpRequestContext*)&context];
                
                return [itunesMusicDMSDelegate onBrowseDirectChildren: capsule];
            }
            else
            {
                // is a file
                
                bool isRoot = strcmp(p, str_root_id_folder) == 0;
                
                return fileDelegate->OnBrowseDirectChildren(action, isRoot ? "0" : object_id, filter, starting_index, requested_count, sort_criteria, context);
                
            }
        }
        
        return  NPT_FAILURE;
    }
    
    
    
    NPT_Result OnSearchContainer(PLT_ActionReference&          action,
                                 const char*                   container_id,
                                 const char*                   search_criteria,
                                 const char*                   filter,
                                 NPT_UInt32                    starting_index,
                                 NPT_UInt32                    requested_count,
                                 const char*                   sort_criteria,
                                 const PLT_HttpRequestContext& context)
    {
        /*
        if (![[m_Target delegate] respondsToSelector:@selector(onSearchContainer:)])
            return NPT_FAILURE;
        
        PLT_MediaServerSearchCapsule* capsule =
        [[PLT_MediaServerSearchCapsule alloc] initWithAction:action.AsPointer()
                                                    objectId:container_id
                                                      search:search_criteria
                                                      filter:filter
                                                       start:starting_index
                                                       count:requested_count
                                                        sort:sort_criteria
                                                     context:(PLT_HttpRequestContext*)&context];
        NPT_Result result = [[m_Target delegate] onSearchContainer:capsule];
        
        return result;
         */
        
        return NPT_FAILURE;
    }
    
    NPT_Result ProcessFileRequest(NPT_HttpRequest& request,
                                  const NPT_HttpRequestContext& context,
                                  NPT_HttpResponse& response)
    {
        NPT_String path ;
        fileDelegate->ExtractResourcePath(request.GetUrl(),path);
        
        const char keyPhoto[] = "assets-library://";
        const char keyMusic[] = "ipod-library";
        
        // is photo or video
        bool isPhoto = strncmp(path, keyPhoto, sizeof(keyPhoto) - 1 ) == 0;
        bool isMusic = strncmp(path, keyMusic, sizeof(keyMusic) - 1 ) == 0;
        
        if (isPhoto || isMusic)
        {
            PLT_HttpRequestContext _context(request, context);
            PLT_MediaServerFileRequestCapsuleMy* capsule =
            [[PLT_MediaServerFileRequestCapsuleMy alloc] initWithResponse:&response context:&_context request:&request];
            
            NPT_String s = request.GetUrl().PercentDecode(request.GetUrl().ToString().GetChars());
            NSString *url = [NSString stringWithCString:s.GetChars() encoding:NSUTF8StringEncoding];
            
            if (isPhoto)
                return [photoDMSDelegate onFileRequest:capsule withURL:url];
            else
                return [itunesMusicDMSDelegate onFileRequest:capsule withURL:url];
            
            return NPT_FAILURE;
        }
        else
        {
            return fileDelegate->ProcessFileRequest(request, context, response);
        }
        
    }
    
private:
    PLT_FileMediaServerDelegateMy *fileDelegate;
    photosDMSDelegate *photoDMSDelegate;
    ItunesMusicDMSDelegate *itunesMusicDMSDelegate;
};

/*----------------------------------------------------------------------
 |   PLT_MediaServerBrowseCapsule
 +---------------------------------------------------------------------*/
@implementation PLT_MediaServerBrowseCapsuleMy

@synthesize objectId, filter, start, count, sort;

- (id)initWithAction:(PLT_Action*)action objectId:(const char*)_id full_id:(const char*)_full_id filter:(const char*)_filter start:(NPT_UInt32)_start count:(NPT_UInt32)_count sort:(const char*)_sort context:(PLT_HttpRequestContext*)_context
{
    if ((self = [super initWithAction:action])) {
        _objectId_full = [NSString stringWithUTF8String:_full_id];
        objectId = [[NSString alloc] initWithCString:_id encoding:NSUTF8StringEncoding];
        filter   = [[NSString alloc] initWithCString:(_filter==NULL)?"":_filter
                                            encoding:NSUTF8StringEncoding];
        sort     = [[NSString alloc] initWithCString:(_sort==NULL)?"":_sort
                                            encoding:NSUTF8StringEncoding];
        start    = _start;
        count    = _count;
        context  = _context;
        
    }
    return self;
}

- (PLT_HttpRequestContext *)getContext {
    return context;
}

@end

/*----------------------------------------------------------------------
 |   PLT_MediaServerSearchCapsule
 +---------------------------------------------------------------------*/
@implementation PLT_MediaServerSearchCapsuleMy

@synthesize search;

- (id)initWithAction:(PLT_Action*)action objectId:(const char*)_id search:(const char*)_search filter:(const char*)_filter start:(NPT_UInt32)_start count:(NPT_UInt32)_count sort:(const char*)_sort context:(PLT_HttpRequestContext*)_context
{
    if ((self = [super initWithAction:action
                             objectId:_id
                              full_id:_id
                               filter:_filter
                                start:_start
                                count:_count
                                 sort:_sort
                              context:_context])) {
        search = [[NSString alloc] initWithCString:_search encoding:NSUTF8StringEncoding];
    }
    return self;
}


@end

/*----------------------------------------------------------------------
 |   PLT_MediaServerFileRequestCapsule
 +---------------------------------------------------------------------*/
@implementation PLT_MediaServerFileRequestCapsuleMy
- (id)initWithResponse:(NPT_HttpResponse*)_response context:(PLT_HttpRequestContext*)_context request:(NPT_HttpRequest*)_request
{
    if ((self = [super init])) {
        response = _response;
        context  = _context;
        request = _request;
    }
    return self;
}


- (NPT_HttpResponse *)getResponse {
    return response;
}


- (PLT_HttpRequestContext *)getContext {
    return context;
}

-(NPT_HttpRequest*)getRequest
{
    return request;
}
@end

/*----------------------------------------------------------------------
 |   PLT_DeviceHostObject
 +---------------------------------------------------------------------*/
@interface PLT_DeviceHostObject (priv)
- (PLT_DeviceHostReference&)getDevice;
@end

/*----------------------------------------------------------------------
 |   PLT_MediaServerObject
 +---------------------------------------------------------------------*/
@implementation PLT_MediaServerObjectMy

@synthesize delegate;

- (id)init
{
    PLT_MediaConnect* server = new PLT_MediaConnect("Test");
    PLT_DeviceHostReference _device(server);
    if ((self = [super initWithDeviceHost:&_device])) {
        server->SetDelegate(new PLT_MediaServerDelegate_Wrapper(self));
    }
    return self;
}


- (id)initServerSelfDelegateWithServerName:(NSString *)theServerName {
    
    PLT_MediaConnect* server = new PLT_MediaConnect([theServerName cStringUsingEncoding:NSUTF8StringEncoding]);
    PLT_DeviceHostReference _device(server);
    _device->m_ModelDescription = "Genie File Media Server";
    if ((self = [super initWithDeviceHost:&_device])) {
        server->SetDelegate(new PLT_MediaServerDelegate_Wrapper(self));
    }
    return self;
}



- (id)initServerWithPath:(NSString *)thePath andServerName:(NSString *)theServerName {
    
    PLT_MediaConnect* server = new PLT_MediaConnect([theServerName cStringUsingEncoding:NSUTF8StringEncoding]);
    //PLT_MediaConnect* server = new PLT_MediaConnect([theServerName cStringUsingEncoding:NSUTF8StringEncoding], false);
    
    
    PLT_DeviceHostReference _device(server);
    if ((self = [super initWithDeviceHost:&_device])) {
        server->SetDelegate(new PLT_LocalMediaFileDelegate("/", [thePath cStringUsingEncoding:NSUTF8StringEncoding]));
    }
    return self;
}


- (void)dealloc
{
    PLT_DeviceHostReference& host = [self getDevice];
    delete ((PLT_MediaServer*)host.AsPointer())->GetDelegate();
}

@end



// PLT_FileMediaServerDelegate methods
bool PLT_LocalMediaFileDelegate::ProcessFile(const NPT_String& filepath, const char* filter ) {
    
    NPT_COMPILER_UNUSED(filter);
    NSString *pathString = [NSString stringWithCString:filepath.GetChars() encoding:NSUTF8StringEncoding];
    if ([pathString rangeOfString:PATH_DEVICE_TEMP_RESOURCE].location != NSNotFound) {
        return false;
    }
    return true;
}


