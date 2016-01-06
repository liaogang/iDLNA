//
//  photosDMSDelegate.m
//  demo
//
//  Created by geine on 6/15/15.
//  Copyright (c) 2015 com.cs. All rights reserved.
//

#import "photosDMSDelegate.h"
#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetExportSession.h>
#import <AVFoundation/AVMediaFormat.h>
#import <AVFoundation/AVAssetTrack.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import <CoreLocation/CoreLocation.h>
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "NPT_AssetsStream.h"

using namespace std;
#import <vector>


const char root_id_photo[]="root_id_photo";
const char root_id_video[]="root_id_video";

static int iGroupCount = -1;
static int iVideoCount = -1;

@interface photosDMSDelegate ()
{
    std::vector<NPT_AssetsStream *> collocter;
    NSMutableArray *assetGroups;
}
@end


@implementation photosDMSDelegate

-(void)dealloc
{
    for(NPT_AssetsStream *s : collocter)
    {
        delete s;
    }
    collocter.clear();
}

+ (ALAssetsLibrary *)defaultAssetsLibrary {
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    

    return library;
}

- (const char*)getUPnPClass:(NSString *)mimeType {
    
    const char* ret = NULL;
    NPT_String mime_type = [mimeType cStringUsingEncoding:NSUTF8StringEncoding];
    
    if (mime_type.StartsWith("audio")) {
        ret = "object.item.audioItem.musicTrack";
    } else if (mime_type.StartsWith("video")) {
        ret = "object.item.videoItem"; //Note: 360 wants "object.item.videoItem" and not "object.item.videoItem.Movie"
    } else if (mime_type.StartsWith("image")) {
        ret = "object.item.imageItem.photo";
    } else {
        ret = "object.item";
    }
    
    return ret;
}


/*----------------------------------------------------------------------
 |   buildSafeResourceUri
 +---------------------------------------------------------------------*/
- (NPT_String)buildSafeResourceUri:(const NPT_HttpUrl&)base_uri withHost:(const char*)host withResource:(const char*)theRes
{
    NPT_String result;
    NPT_HttpUrl uri = base_uri;
    
    if (host) uri.SetHost(host);
    
    NPT_String uri_path = uri.GetPath();
    if (!uri_path.EndsWith("/")) uri_path += "/";
    
    // some controllers (like WMP) will call us with an already urldecoded version.
    // We're intentionally prepending a known urlencoded string
    // to detect it when we receive the request
    uri_path += "%25/";
    uri_path += NPT_Uri::PercentEncode(theRes, " !\"<>\\^`{|}?#[]:/", true);
    
    // set path but don't urlencode it again
    uri.SetPath(uri_path, true);
    
    // 360 hack: force inclusion of port in case it's 80
    return uri.ToStringWithDefaultPort(0);
}


#pragma mark PLT_MediaServerDelegateObject
- (NPT_Result)onBrowseMetadata:(PLT_MediaServerBrowseCapsuleMy*)info
{
    NSLog(@"onBrowseMetadata");
    return NPT_FAILURE;
}

- (NPT_Result)onBrowseDirectChildrenVideo:(PLT_MediaServerBrowseCapsuleMy*)info
{
    __block NPT_Result ret = NPT_SUCCESS;
    
    NSMutableArray *collectorGroups = [[NSMutableArray alloc] initWithCapacity:10];
    
    ALAssetsLibrary *al = [photosDMSDelegate defaultAssetsLibrary];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [al enumerateGroupsWithTypes:ALAssetsGroupAll
                      usingBlock:^(ALAssetsGroup *group, BOOL *stop){
                          if (group) {
                              [collectorGroups addObject:group];
                          }else {
                              dispatch_semaphore_signal(semaphore);
                          }
                      }
                    failureBlock:^(NSError *error) {
                        NSLog(@"error in enumerateGroupsWithTypes !!!");
                        dispatch_semaphore_signal(semaphore);
                    }
     ];
    
    dispatch_semaphore_wait(semaphore,DISPATCH_TIME_FOREVER);
    
    assetGroups = collectorGroups;
    
    __block unsigned long cur_index = 0;
    __block unsigned long num_returned = 0;
    __block unsigned long total_matches = 0;
    
    
    __block NPT_String didl = didl_header;
    __block PLT_HttpRequestContext *context = [info getContext];
    
    for (int i = 0; i < [collectorGroups count]; i++) {
        
        ALAssetsGroup *group = [collectorGroups objectAtIndex:i];
        
     
        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            
            if (result)
            {
                ALAssetRepresentation *repr = [result defaultRepresentation];
                
                NPT_String sMimeType;
                NPT_String sUrl;
                
                if (repr != nil) {
                    NSString *mimeType = (__bridge NSString*)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)[repr UTI], kUTTagClassMIMEType);
                    sMimeType = [mimeType UTF8String];
                    sUrl = [[[repr url] absoluteString] UTF8String];
                }
                if (!sMimeType.IsEmpty()) {
                    NPT_UrlQuery query(NPT_Url(sUrl).GetQuery());
                    NPT_String sTitle;
                    const char *fId = query.GetField("id");
                    if (fId) {
                        sTitle = fId;
                    } else {
                        sTitle = sUrl;
                    }
                    
                    
                    NSDictionary *dic =
                    @{
                      @"video/quicktime":@"object.item.videoItem",
                      @"video/x-m4v":@"object.item.videoItem",
                      @"video/mp4":@"object.item.videoItem",
                      };
                    
                    NSString *upnpclass = dic[[NSString stringWithUTF8String:(char*)sMimeType]];
                    
                    if (upnpclass)
                    {
                        PLT_MediaObjectReference item;
                        PLT_MediaObject*      object = NULL;
                        object = new PLT_MediaItem();
                        PLT_MediaItemResource resource;
                        
                        object->m_Title = [repr filename].UTF8String;
                        resource.m_ProtocolInfo = PLT_ProtocolInfo::GetProtocolInfoFromMimeType( sMimeType, true, context);
                        resource.m_Size = [repr size];
                        
                        id date = [result valueForProperty:ALAssetPropertyDate];
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        /// @see: dc:date
                        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
                        object->m_Date = [dateFormatter stringFromDate:date].UTF8String;
                        
                        object->m_ObjectClass.type = upnpclass.UTF8String;
                        
                        // get list of ip addresses
                        NPT_List<NPT_IpAddress> ips;
                        //TODO:Veryfy
                        NPT_Result r = PLT_UPnPMessageHelper::GetIPAddresses(ips);
                        if (r == NPT_FAILURE) {
                            ret = NPT_FAILURE;
                        }
                        /* add as many resources as we have interfaces s*/
                        
                        
                        NPT_String m_UrlRoot("/");
                        NPT_HttpUrl base_uri("127.0.0.1", context->GetLocalAddress().GetPort(), m_UrlRoot);
                        NPT_List<NPT_IpAddress>::Iterator ip = ips.GetFirstItem();
                        while (ip) {
                            resource.m_Uri = [self buildSafeResourceUri:base_uri withHost:ip->ToString() withResource:sUrl];
                            object->m_Resources.Add(resource);
                            ++ip;
                        }
                        
                        
                        object->m_ParentID = info.objectId_full.UTF8String ;
                        object->m_ObjectID = [info.objectId_full stringByAppendingPathComponent:@(cur_index).stringValue].UTF8String;
                        
                        
                        item = object;
                        
                        NPT_String tmp;
                        PLT_Didl::ToDidl(*item.AsPointer(), [info.filter cStringUsingEncoding:NSUTF8StringEncoding], tmp);
                        didl += tmp;
                        ++num_returned;
                        ++cur_index;
                        ++total_matches;
                        
                    }
                }
                
            }
            
        }];


    }
    
    iVideoCount = num_returned;
    
    didl += didl_footer;
    NPT_CHECK_SEVERE([info setValue:[NSString stringWithCString:didl.GetChars() encoding:NSUTF8StringEncoding] forArgument:@"Result"]);
    
    NPT_CHECK_SEVERE([info setValue:[[NSNumber numberWithLong:num_returned]stringValue] forArgument:@"NumberReturned"]);
    NPT_CHECK_SEVERE([info setValue:[[NSNumber numberWithLong:total_matches]stringValue] forArgument:@"TotalMatches"]);
    NPT_CHECK_SEVERE([info setValue:@"1" forArgument:@"UpdateId"]);
    
    return  NPT_SUCCESS;
    
}

+(int)videoCount
{
    return iVideoCount;
}

+(int)groupCount
{
    return iGroupCount;
}




- (NPT_Result)onBrowseDirectChildren:(PLT_MediaServerBrowseCapsuleMy*)info
{
    __block NPT_Result ret = NPT_SUCCESS;
    
    const char *object_id = info.objectId.UTF8String;
    
    
    bool isVideo = strncmp( object_id , getRootIdVideo(), getRootIdVideoLen()) == 0;
    if (isVideo) {
        return [self onBrowseDirectChildrenVideo:info];
    }
    
    
    bool isRoot = object_id[ getRootIdPhotoLen()] == 0 ;
    
    
    if ( isRoot )
    {
        NSMutableArray *collectorGroups = [[NSMutableArray alloc] initWithCapacity:10];
        
        ALAssetsLibrary *al = [photosDMSDelegate defaultAssetsLibrary];
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        [al enumerateGroupsWithTypes:ALAssetsGroupAll
                          usingBlock:^(ALAssetsGroup *group, BOOL *stop){
                              if (group) {
                                  [collectorGroups addObject:group];
                              }else {
                                  dispatch_semaphore_signal(semaphore);
                              }
                          }
                        failureBlock:^(NSError *error) {
                            NSLog(@"error in enumerateGroupsWithTypes !!!");
                            dispatch_semaphore_signal(semaphore);
                        }
         ];
        
        dispatch_semaphore_wait(semaphore,DISPATCH_TIME_FOREVER);
        
        assetGroups = collectorGroups;
        
        iGroupCount = assetGroups.count;
        
        unsigned long cur_index = 0;
        unsigned long num_returned = 0;
        unsigned long total_matches = 0;
        
        NPT_String didl = didl_header;
        
        for (int i = 0; i < [collectorGroups count]; i++) {
            
            ALAssetsGroup *group = [collectorGroups objectAtIndex:i];
            NSString *groupName	 = [group valueForProperty:ALAssetsGroupPropertyName];
            
            
            PLT_MediaObjectReference item;
            
            PLT_MediaObject* object = NULL;
            object = new PLT_MediaContainer;
            
            object->m_Title =  groupName.UTF8String;
            
            [group setAssetsFilter: [ALAssetsFilter allPhotos]];
            ((PLT_MediaContainer*)object)->m_ChildrenCount = (NPT_Int32) group.numberOfAssets;
            object->m_ObjectClass.type = "object.container.storageFolder";
            object->m_ObjectID = [info.objectId_full stringByAppendingPathComponent:@(i).stringValue].UTF8String;
            
            item = object;
            
            
            NPT_String tmp;
            NPT_CHECK_SEVERE(PLT_Didl::ToDidl(*item.AsPointer(), [info.filter cStringUsingEncoding:NSUTF8StringEncoding], tmp));
            didl += tmp;
            ++num_returned;
            ++cur_index;
            ++total_matches;
        }
        
        didl += didl_footer;
        NPT_CHECK_SEVERE([info setValue:[NSString stringWithCString:didl.GetChars() encoding:NSUTF8StringEncoding] forArgument:@"Result"]);
        
        NPT_CHECK_SEVERE([info setValue:[[NSNumber numberWithLong:num_returned]stringValue] forArgument:@"NumberReturned"]);
        NPT_CHECK_SEVERE([info setValue:[[NSNumber numberWithLong:total_matches]stringValue] forArgument:@"TotalMatches"]);
        NPT_CHECK_SEVERE([info setValue:@"1" forArgument:@"UpdateId"]);
        
        return  NPT_SUCCESS;
    }else
    {
        NSString *albIndex = [info.objectId	substringFromIndex:getRootIdPhotoLen() + 1];
        
        ALAssetsGroup *group = [assetGroups objectAtIndex:[albIndex intValue]];
        
        __block unsigned long cur_index = 0;
        __block unsigned long num_returned = 0;
        __block unsigned long total_matches = 0;
        
        __block PLT_HttpRequestContext *context = [info getContext];
        
        __block NPT_String didl = didl_header;
        
        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            
            
            if (result)
            {
                ALAssetRepresentation *repr = [result defaultRepresentation];

                /*
                id address = [result valueForProperty:ALAssetPropertyLocation];
                NSLog(@"address , class,%@: %@",[address class],address);
                
                id date2 = [result valueForProperty:ALAssetPropertyDate];
                NSLog(@"date: class: %@, data: %@",[date2 class],date2);
                
                
                //                NSLog(@"%@",repr.metadata);
                NSDictionary *GPSDict=[repr.metadata objectForKey:(__bridge NSString*)kCGImagePropertyGPSDictionary];
                if (GPSDict!=nil) {
                    CLLocation *loc=[GPSDict locationFromGPSDictionary];
                    
                    NSString *a =[NSString stringWithFormat:@"latitude:%f,longitude:%f",loc.coordinate.latitude,loc.coordinate.longitude];
                    NSLog(@"坐标: %@",a);
                    
                    
                    
                    CLGeocoder *geocoder=[[CLGeocoder alloc]init];
                    [geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray *placemark,NSError *error)
                     {
                         CLPlacemark *mark=[placemark objectAtIndex:0];
                         NSString *title=[NSString stringWithFormat:@"%@%@%@",mark.subLocality,mark.thoroughfare,mark.subThoroughfare];
                         NSString *subTitle=[NSString stringWithFormat:@"%@",mark.name];
                         
                         NSLog(@"title: %@,subtitle: %@",title,subTitle);
                     } ];
                    
                    
                }
                
                NSMutableDictionary*   imageMetadata = [[NSMutableDictionary alloc] initWithDictionary:repr.metadata];
                
                //EXIF数据
                NSMutableDictionary *EXIFDictionary =[[imageMetadata objectForKey:(__bridge NSString *)kCGImagePropertyExifDictionary]mutableCopy];
                NSString * dateTimeOriginal=[[EXIFDictionary objectForKey:(__bridge NSString*)kCGImagePropertyExifDateTimeOriginal] mutableCopy];
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];//yyyy-MM-dd HH:mm:ss
                NSDate *date = [dateFormatter dateFromString:dateTimeOriginal];
                
                NSLog(@"date: %@",date);

                */
                

                
                NPT_String sMimeType;
                NPT_String sUrl;
                
                if (repr != nil) {
                    NSString *mimeType = (__bridge NSString*)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)[repr UTI], kUTTagClassMIMEType);
                    sMimeType = [mimeType UTF8String];
                    sUrl = [[[repr url] absoluteString] UTF8String];
                }
                if (!sMimeType.IsEmpty()) {
                    NPT_UrlQuery query(NPT_Url(sUrl).GetQuery());
                    NPT_String sTitle;
                    const char *fId = query.GetField("id");
                    if (fId) {
                        sTitle = fId;
                    } else {
                        sTitle = sUrl;
                    }
                    
                    
                    NSDictionary *dic =
                    @{@"image/jpeg":@"object.item.imageItem.photo",
                      @"image/png":@"object.item.imageItem.photo",
                      @"image/bmp":@"object.item.imageItem.photo",
                      @"image/gif":@"object.item.imageItem.photo",
                      @"image/tiff":@"object.item.imageItem.photo",
                      };
                    NSString *upnpclass = dic[[NSString stringWithUTF8String:(char*)sMimeType]];
                    if (upnpclass)
                    {
                        
                        PLT_MediaObjectReference item;
                        PLT_MediaObject*      object = NULL;
                        object = new PLT_MediaItem();
                        PLT_MediaItemResource resource;
                        
                        object->m_Title = [repr filename].UTF8String;
                        resource.m_ProtocolInfo = PLT_ProtocolInfo::GetProtocolInfoFromMimeType( sMimeType, true, context);
                        resource.m_Size = [repr size];
                        
                        
                        id date = [result valueForProperty:ALAssetPropertyDate];
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        /// @see: dc:date
                        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
                        object->m_Date = [dateFormatter stringFromDate:date].UTF8String;
                        
                        
                        object->m_ObjectClass.type = upnpclass.UTF8String;
                        
                        // get list of ip addresses
                        NPT_List<NPT_IpAddress> ips;
                        //TODO:Veryfy
                        NPT_Result r = PLT_UPnPMessageHelper::GetIPAddresses(ips);
                        if (r == NPT_FAILURE) {
                            ret = NPT_FAILURE;
                        }
                        /* add as many resources as we have interfaces s*/
                        
                        
                        NPT_String m_UrlRoot("/");
                        NPT_HttpUrl base_uri("127.0.0.1", context->GetLocalAddress().GetPort(), m_UrlRoot);
                        NPT_List<NPT_IpAddress>::Iterator ip = ips.GetFirstItem();
                        while (ip) {
                            resource.m_Uri = [self buildSafeResourceUri:base_uri withHost:ip->ToString() withResource:sUrl];
                            object->m_Resources.Add(resource);
                            ++ip;
                        }
                        
                        
                        object->m_ParentID = info.objectId_full.UTF8String ;
                        object->m_ObjectID = [info.objectId_full stringByAppendingPathComponent:@(cur_index).stringValue].UTF8String;
                        
                        
                        item = object;
                        
                        NPT_String tmp;
                        PLT_Didl::ToDidl(*item.AsPointer(), [info.filter cStringUsingEncoding:NSUTF8StringEncoding], tmp);
                        didl += tmp;
                        ++num_returned;
                        ++cur_index;
                        ++total_matches;
                    }
                }
                
            }
            
        }];
        
        
        
        
        
        
        didl += didl_footer;
        
        NPT_CHECK_SEVERE([info setValue:[NSString stringWithCString:didl.GetChars() encoding:NSUTF8StringEncoding] forArgument:@"Result"]);
        
        NPT_CHECK_SEVERE([info setValue:[[NSNumber numberWithLong:num_returned]stringValue] forArgument:@"NumberReturned"]);
        NPT_CHECK_SEVERE([info setValue:[[NSNumber numberWithLong:total_matches]stringValue] forArgument:@"TotalMatches"]);
        NPT_CHECK_SEVERE([info setValue:@"1" forArgument:@"UpdateId"]);
        
        return  NPT_SUCCESS;
    }
    
    return NPT_SUCCESS;
}

- (NPT_Result)onSearchContainer:(PLT_MediaServerSearchCapsuleMy*)info
{
    NSLog(@"onSearchContainer: %@",info.filter);
    
    
    
    
    return NPT_FAILURE;
}



- (NPT_Result)onFileRequest:(PLT_MediaServerFileRequestCapsuleMy*)info withURL:(NSString *)theURL
{
    NSLog(@"on file request: %@",theURL);
    
    info.getResponse->GetHeaders().SetHeader("Accept-Ranges", "bytes");
    
    if (info.getContext->GetRequest().GetMethod().Compare("GET") && info.getContext->GetRequest().GetMethod().Compare("HEAD")) {
        info.getResponse->SetStatus(500, "Internal Server Error");
        return NPT_SUCCESS;
    }
    
    
    NSRange range				= [theURL rangeOfString:@"assets-library://"];
    NSString *urlSubstring = [theURL substringFromIndex:range.location];
    
    
    __block BOOL hasErrorFlag		= NO;
    
    NSURL *theResourceURL = [NSURL URLWithString:urlSubstring];
    
    ALAssetsLibrary *al =	[photosDMSDelegate defaultAssetsLibrary];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [al assetForURL:theResourceURL resultBlock:^(ALAsset *asset) {

        ALAssetRepresentation *repr = [asset defaultRepresentation];
        if (asset && repr) {
            
        
        NPT_AssetsStream *stream = new NPT_AssetsStream(repr);
        
        // collect it for release.
//        collocter.push_back(stream);
        
        NPT_HttpResponse*       response = [info getResponse];
        PLT_HttpRequestContext* context = [info getContext];
        NPT_HttpRequest *request = [info getRequest];
        PLT_HttpRequestContext tmp_context(*request, *context);
        
        NPT_InputStreamReference r_stream(stream);
        
        PLT_HttpServer::ServeStream(*request, *context, *response, r_stream, PLT_MimeType::GetMimeType( urlSubstring.UTF8String, &tmp_context) );
        
        
        }
        
        dispatch_semaphore_signal(semaphore);
        
    } failureBlock:^(NSError *error) {
        NSLog(@"booya, cant get image - %@",[error localizedDescription]);
        hasErrorFlag = NO;
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore,DISPATCH_TIME_FOREVER);
    
    
    return NPT_SUCCESS;
}





@end




const char* getRootIdPhoto()
{
    return root_id_photo;
}

int getRootIdPhotoLen()
{
    return sizeof(root_id_photo)-1;
}

const char* getRootIdVideo()
{
    return root_id_video;
}

int getRootIdVideoLen()
{
    return sizeof(root_id_video)-1;
}

