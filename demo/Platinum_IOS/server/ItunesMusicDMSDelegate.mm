//
//  ItunesMusicDMSDelegate.m
//  demo
//
//  Created by geine on 6/17/15.
//  Copyright (c) 2015 com.cs. All rights reserved.
//

#import "ItunesMusicDMSDelegate.h"
#import "Util.h"
#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetExportSession.h>
#import <AVFoundation/AVMediaFormat.h>
#import <AVFoundation/AVAssetTrack.h>
#import <CoreMedia/CMFormatDescription.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <MediaPlayer/MediaPlayer.h>

#import <MobileCoreServices/UTType.h>
#import "id3Info.h"

#import <pthread.h>

@implementation ItunesMusicDMSDelegate

@synthesize albumsArray;


#pragma mark - DocumentPath
- (NSString *)getDocumentPath {
    return [[Util sharedInstance] getDocumentPath];
}


- (NSString *)getTempPath {
    return NSTemporaryDirectory();
}


- (void)loadSongs {
    
    if (albumsArray) {
        return;
    }
    
    MPMediaQuery *query = [MPMediaQuery albumsQuery];
    
    NSArray *albums = [query collections];
    self.albumsArray = albums;
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


- (NPT_Result)onBrowseDirectChildren:(PLT_MediaServerBrowseCapsuleMy*)info
{
    /**
     0/Music/Albums/AlbumsName/music.mp3
     0/Music/Songs/music.mp3
     */
    
    const char *object_id = info.objectId.UTF8String;
    
    char *object_id2 = (char*)object_id;
    
    if(strncmp(object_id, getRootIdMusic(), getRootIdMusicLen()) != 0)
    {
        printf(" id error: %s\n",object_id);
        return NPT_FAILURE;
    }
    
    
    object_id2 += getRootIdMusicLen() ;
    
    bool isMusicRoot = object_id2[0] == 0;
    
    if (isMusicRoot)
    {
        NPT_String didl = didl_header;
        PLT_MediaObjectReference item;
        
        PLT_MediaObject* object = NULL;
        
        [self loadSongs];
        
        
        // Albums
        
        object = new PLT_MediaContainer;
        object->m_Title = "Albums";
        
        ((PLT_MediaContainer*)object)->m_ChildrenCount = (NPT_Int32)self.albumsArray.count;
        object->m_ObjectClass.type = "object.container.storageFolder";
        
        object->m_ParentID = info.objectId_full.UTF8String;
        
        object->m_ObjectID = info.objectId_full.UTF8String;
        object->m_ObjectID.Append("/Albums") ;
        
        item = object;

        NPT_String tmp;
        NPT_CHECK_SEVERE(PLT_Didl::ToDidl(*item.AsPointer(), [info.filter cStringUsingEncoding:NSUTF8StringEncoding], tmp));
        
        /* add didl header and footer */
        didl += tmp;
        
        
        // Songs
        
        object = new PLT_MediaContainer;
        object->m_Title = "Songs";
        
        MPMediaQuery *query = [[MPMediaQuery alloc] init] ;
        [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInt:MPMediaTypeMusic] forProperty:MPMediaItemPropertyMediaType]];
        
        ((PLT_MediaContainer*)object)->m_ChildrenCount = (NPT_Int32) query.items.count;
        
        object->m_ObjectClass.type = "object.container.storageFolder";
        object->m_ParentID = info.objectId_full.UTF8String;
        
        object->m_ObjectID =  info.objectId_full.UTF8String;
        object->m_ObjectID.Append("/Songs");
        item = object;
        
        
        NPT_String tmp2;
        NPT_CHECK_SEVERE(PLT_Didl::ToDidl(*item.AsPointer(), [info.filter cStringUsingEncoding:NSUTF8StringEncoding], tmp2));
        
        /* add didl header and footer */
        didl += tmp2;
        
        
        didl += didl_footer;
        
        NPT_CHECK_SEVERE([info setValue:[NSString stringWithCString:didl.GetChars() encoding:NSUTF8StringEncoding] forArgument:@"Result"]);
        NPT_CHECK_SEVERE([info setValue:[NSString stringWithCString:"2" encoding:NSUTF8StringEncoding] forArgument:@"NumberReturned"]);
        NPT_CHECK_SEVERE([info setValue:[NSString stringWithCString:"2" encoding:NSUTF8StringEncoding] forArgument:@"TotalMatches"]);
        
        // update ID may be wrong here, it should be the one of the container?
        // TODO: We need to keep track of the overall updateID of the CDS
        NPT_CHECK_SEVERE([info setValue:[NSString stringWithCString:"1" encoding:NSUTF8StringEncoding] forArgument:@"UpdateId"]);
        
        return  NPT_SUCCESS;
    }
    else
    {
        object_id2 += 1;
        
        if ( strncmp( object_id2 , "Albums" , sizeof( "Albums" ) - 1 )  == 0 )
        {
            object_id2 += sizeof( "Albums" ) - 1;
            
            
            char *p = strchr( object_id2 , '/');
            
            // groups or groups's chrild items?
            if ( p == 0)
            {
                unsigned long cur_index = 0;
                unsigned long num_returned = 0;
                unsigned long total_matches = 0;
                
                NPT_String didl = didl_header;
                
                for (int i = 0; i < [albumsArray count]; i++) {
                    
                    MPMediaItemCollection *album = [albumsArray objectAtIndex:i];
                    MPMediaItem *representativeItem = [album representativeItem];
                    NSString *albumName = [representativeItem valueForProperty: MPMediaItemPropertyAlbumTitle];
                    
                    PLT_MediaObjectReference item;
                    
                    PLT_MediaObject* object = NULL;
                    object = new PLT_MediaContainer;
                    
                    NPT_String title([albumName cStringUsingEncoding:NSUTF8StringEncoding]);
                    object->m_Title =  title;
                    
                    
                    ((PLT_MediaContainer*)object)->m_ChildrenCount = (NPT_Int32)album.items.count;
                    object->m_ObjectClass.type = "object.container.storageFolder";
                    
                    object->m_ParentID = info.objectId_full.UTF8String;
                    
                    NPT_String objID(info.objectId_full.UTF8String);
                    objID.Append("/");
                    objID.Append(NPT_String::FromInteger((NPT_Int64)i));
                    object->m_ObjectID = objID;
                    
                    
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
            }
            else
            {
                NSString *albIndex = [NSString stringWithFormat:@"%s",p+1];
                MPMediaItemCollection *album = [albumsArray objectAtIndex:[albIndex intValue]];
                
                //MPMediaItem *representativeItem = [album representativeItem];
                //NSString *artistName = [representativeItem valueForProperty: MPMediaItemPropertyArtist];
                //NSString *albumName = [representativeItem valueForProperty: MPMediaItemPropertyAlbumTitle];
                
                NSArray *songs = [album items];
                
                unsigned long cur_index = 0;
                unsigned long num_returned = 0;
                unsigned long total_matches = 0;
                
                PLT_HttpRequestContext *context = [info getContext];
                
                NPT_String didl = didl_header;
                
                for (MPMediaItem *song in songs) {
                    NSString *songTitle = [song valueForProperty: MPMediaItemPropertyTitle];
                    NSURL *assetURL = [song valueForProperty:MPMediaItemPropertyAssetURL];
                    
                    
                    
                    
                    
                    
                    PLT_MediaObject* object = new PLT_MediaItem();
                    /* Set the title using the filename for now */
                    object->m_Title = [songTitle cStringUsingEncoding:NSUTF8StringEncoding];
                    if (object->m_Title.GetLength() == 0){
                        return NPT_FAILURE;
                    };
                    
                    /* Set the protocol Info from the extension */
                    PLT_MediaItemResource resource;
                    resource.m_ProtocolInfo = PLT_ProtocolInfo::GetProtocolInfoFromMimeType("audio/mpeg", true, context);
                    if (!resource.m_ProtocolInfo.IsValid()){
                        return NPT_FAILURE;
                    }
                    
                    /* Set the resource file size */
                    NSTimeInterval playbackDuration = ((NSNumber*)[song valueForProperty:MPMediaItemPropertyPlaybackDuration]).doubleValue;
                    resource.m_Size =  -1;
                    resource.m_Duration = playbackDuration;
                    
                    // artist
                    object->m_People.artists.Add( ((NSString*)[song valueForProperty:MPMediaItemPropertyArtist]).UTF8String);
                    
                    // album
                    object->m_Affiliation.album = ((NSString*)[song valueForProperty:MPMediaItemPropertyAlbumTitle]).UTF8String;
                    
                    
                    
                    
                    NPT_String filepath([[assetURL path] cStringUsingEncoding:NSUTF8StringEncoding]);
                    NPT_String root("/");
                    /* format the resource URI */
                    NPT_String url = filepath.SubString(root.GetLength()+1);
                    
                    // get list of ip addresses
                    NPT_List<NPT_IpAddress> ips;
                    //TODO:Veryfy
                    NPT_Result r = PLT_UPnPMessageHelper::GetIPAddresses(ips);
                    if (r == NPT_FAILURE) {
                        return NPT_FAILURE;
                    }
                    
                    
                    
                    
                    /* if we're passed an interface where we received the request from
                     move the ip to the top so that it is used for the first resource */
                    if (context->GetLocalAddress().GetIpAddress().ToString() != "0.0.0.0") {
                        ips.Remove(context->GetLocalAddress().GetIpAddress());
                        ips.Insert(ips.GetFirstItem(), context->GetLocalAddress().GetIpAddress());
                    }
                    object->m_ObjectClass.type = [self getUPnPClass:@"audio/mpeg"];
                    
                    /* add as many resources as we have interfaces s*/
                    NPT_String m_UrlRoot("/");
                    NPT_HttpUrl base_uri("127.0.0.1", context->GetLocalAddress().GetPort(), m_UrlRoot);
                    NPT_List<NPT_IpAddress>::Iterator ip = ips.GetFirstItem();
                    
                    if (ip) {
                        NSString *assetStr = [assetURL absoluteString];
                        // album art icon uri
                        MPMediaItemArtwork *artwork = ((MPMediaItemArtwork *)[song valueForProperty:MPMediaItemPropertyArtwork]);
                        if (artwork) {
                            PLT_AlbumArtInfo data;
                            char *p = (char*)assetStr.UTF8String;
                            char tmp[256];
                            strcpy(tmp, p);
                            p = strstr(tmp, "ipod-library://");
                            p += sizeof("ipod-library://")-1;
                            p[0]='a';
                            p[1]='l';
                            p[2]='b';
                            p[3]='m';
                            
                            strcat(tmp, ".png");
                            
                            data.uri = [self buildSafeResourceUri:base_uri withHost:ip->ToString() withResource: tmp];
                            object->m_ExtraInfo.album_arts.Add(data);
                        }
                    }
                    
                    
                    while (ip) {
                        resource.m_Uri = [self buildSafeResourceUri:base_uri withHost:ip->ToString() withResource:[[assetURL absoluteString] cStringUsingEncoding:NSUTF8StringEncoding]];
                        
                        
                        object->m_Resources.Add(resource);
                        
                        
                        ++ip;
                    }
                    
                    
                    
                    
                    
                    
                    
                    
                    /*
                     NPT_String parentID("Albums/");
                     parentID.Append([info.objectId cStringUsingEncoding:NSUTF8StringEncoding]);
                     */
                    
                    //                NPT_String objID("Albums/");
                    //                objID.Append([info.objectId cStringUsingEncoding:NSUTF8StringEncoding]);
                    //                objID.Append("/");
                    //                objID.Append([songTitle cStringUsingEncoding:NSUTF8StringEncoding]);
                    
                    object->m_ParentID = info.objectId_full.UTF8String;
                    object->m_ObjectID = [info.objectId_full stringByAppendingPathComponent:songTitle].UTF8String;
                    
                    ///////end
                    
                    PLT_MediaObjectReference item;
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
                
            }
            
            
        }else
        {
            
            if ( strncmp( object_id2 , "Songs" , sizeof( "Songs" ) - 1 )  != 0 )
            {
                printf("request id error: %s",object_id);
                return NPT_FAILURE;
            }
            
            unsigned long cur_index = 0;
            unsigned long num_returned = 0;
            unsigned long total_matches = 0;
            
            PLT_HttpRequestContext *context = [info getContext];
            NPT_String didl = didl_header;
            
            //Fill the MpMediaItem fro URL.
            MPMediaQuery *query = [[MPMediaQuery alloc] init] ;
            [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInt:MPMediaTypeMusic] forProperty:MPMediaItemPropertyMediaType]];
            for ( MPMediaItem *song in [query items])
            {
                NSURL *assetURL = [song valueForProperty:MPMediaItemPropertyAssetURL];
                NSString *songTitle = [song valueForProperty: MPMediaItemPropertyTitle];
                
                
                PLT_MediaObject* object = new PLT_MediaItem();
                
                /* Set the title using the filename for now */
                object->m_Title = [songTitle cStringUsingEncoding:NSUTF8StringEncoding];
                if (object->m_Title.GetLength() == 0){
                    return NPT_FAILURE;
                };
                
                /* Set the protocol Info from the extension */
                PLT_MediaItemResource resource;
                resource.m_ProtocolInfo = PLT_ProtocolInfo::GetProtocolInfoFromMimeType("audio/mpeg", true, context);
                if (!resource.m_ProtocolInfo.IsValid()){
                    return NPT_FAILURE;
                }
                
                /* Set the resource file size */
                NSTimeInterval playbackDuration = ((NSNumber*)[song valueForProperty:MPMediaItemPropertyPlaybackDuration]).doubleValue;
                resource.m_Size = -1;
                resource.m_Duration = playbackDuration ;
                
                // artist
                object->m_People.artists.Add( ((NSString*)[song valueForProperty:MPMediaItemPropertyArtist]).UTF8String);
                
                // album
                object->m_Affiliation.album = ((NSString*)[song valueForProperty:MPMediaItemPropertyAlbumTitle]).UTF8String;
                
                
                NPT_String filepath([[assetURL path] cStringUsingEncoding:NSUTF8StringEncoding]);
                NPT_String root("/");
                /* format the resource URI */
                NPT_String url = filepath.SubString(root.GetLength()+1);
                
                // get list of ip addresses
                NPT_List<NPT_IpAddress> ips;
                //TODO:Veryfy
                NPT_Result r = PLT_UPnPMessageHelper::GetIPAddresses(ips);
                if (r == NPT_FAILURE) {
                    return NPT_FAILURE;
                }
                
                
                
                
                /* if we're passed an interface where we received the request from
                 move the ip to the top so that it is used for the first resource */
                if (context->GetLocalAddress().GetIpAddress().ToString() != "0.0.0.0") {
                    ips.Remove(context->GetLocalAddress().GetIpAddress());
                    ips.Insert(ips.GetFirstItem(), context->GetLocalAddress().GetIpAddress());
                }
                object->m_ObjectClass.type = [self getUPnPClass:@"audio/mpeg"];
                
                /* add as many resources as we have interfaces s*/
                NPT_String m_UrlRoot("/");
                NPT_HttpUrl base_uri("127.0.0.1", context->GetLocalAddress().GetPort(), m_UrlRoot);
                NPT_List<NPT_IpAddress>::Iterator ip = ips.GetFirstItem();
                
                if (ip) {
                    NSString *assetStr = [assetURL absoluteString];
                    // album art icon uri
                    MPMediaItemArtwork *artwork = ((MPMediaItemArtwork *)[song valueForProperty:MPMediaItemPropertyArtwork]);
                    if (artwork) {
                        PLT_AlbumArtInfo data;
                        char *p = (char*)assetStr.UTF8String;
                        char tmp[256];
                        strcpy(tmp, p);
                        p = strstr(tmp, "ipod-library://");
                        p += sizeof("ipod-library://")-1;
                        p[0]='a';
                        p[1]='l';
                        p[2]='b';
                        p[3]='m';
                        
                        strcat(tmp, ".png");
                        
                        data.uri = [self buildSafeResourceUri:base_uri withHost:ip->ToString() withResource: tmp];
                        object->m_ExtraInfo.album_arts.Add(data);
                    }
                }
                
                
                while (ip) {
                    resource.m_Uri = [self buildSafeResourceUri:base_uri withHost:ip->ToString() withResource:[[assetURL absoluteString] cStringUsingEncoding:NSUTF8StringEncoding]];
                    
                    object->m_Resources.Add(resource);
                    
                    
                    ++ip;
                }
                
                
                
                
                
                
                
                
                /*
                 NPT_String parentID("Albums/");
                 parentID.Append([info.objectId cStringUsingEncoding:NSUTF8StringEncoding]);
                 */
                
                //                NPT_String objID("Albums/");
                //                objID.Append([info.objectId cStringUsingEncoding:NSUTF8StringEncoding]);
                //                objID.Append("/");
                //                objID.Append([songTitle cStringUsingEncoding:NSUTF8StringEncoding]);
                
                object->m_ParentID = info.objectId_full.UTF8String;
                object->m_ObjectID = [info.objectId_full stringByAppendingPathComponent:songTitle].UTF8String;
                
                ///////end
                
                PLT_MediaObjectReference item;
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
        }
    }
    
    return NPT_FAILURE;
}

- (NPT_Result)onSearchContainer:(PLT_MediaServerSearchCapsuleMy*)info
{
    NSLog(@"onSearchContainer: %@",info.filter);
    
    
    
    
    
    
    
    return NPT_FAILURE;
}


- (BOOL)updateCurrentFileDate:(NSString *)theFilePath {
    
    BOOL retFlag = NO;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:theFilePath]) {
        NSDictionary *attributesDict = [NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate];
        NSError *error = nil;
        [[NSFileManager defaultManager] setAttributes:attributesDict ofItemAtPath:theFilePath error:&error];
        
        if (error) {
            NSLog(@"update date error!");
        }else {
            retFlag = YES;
        }
    }
    
    return retFlag;
}


NSInteger dateSort(id s1, id s2, void *context) {
    
    NSDate *d1;
    [s1 getResourceValue:&d1 forKey:NSURLAttributeModificationDateKey error:NULL];
    NSDate *d2;
    [s2 getResourceValue:&d2 forKey:NSURLAttributeModificationDateKey error:NULL];
    
    return [d2 compare:d1];
}


- (void)sweepCache {
    
    static int cacheInt = 5;
    
    NSURL *url = [NSURL URLWithString:[self getTempPath]];
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtURL:url includingPropertiesForKeys:[NSArray arrayWithObject:NSURLContentModificationDateKey] options:NSDirectoryEnumerationSkipsSubdirectoryDescendants|NSDirectoryEnumerationSkipsHiddenFiles|NSDirectoryEnumerationSkipsPackageDescendants errorHandler:nil];
    
    
    NSMutableArray *fileArray = [NSMutableArray arrayWithCapacity:15];
    
    for (NSURL *theFileURL in dirEnum) {
        
        NSString *fileName;
        [theFileURL getResourceValue:&fileName forKey:NSURLNameKey error:NULL];
        
        if ([fileName rangeOfString:@"T_M_File_"].location != NSNotFound) {
            [fileArray addObject:theFileURL];
        }
        
    }
    
    if ([fileArray count] < cacheInt) {
        return;
    }
    
    NSArray* sortedArray = [fileArray sortedArrayUsingFunction:dateSort context:nil];
    
    for (int i = cacheInt; i < [sortedArray count]; i ++) {
        NSError *deleteErr = nil;
        
        NSLog (@"delete %@", [sortedArray objectAtIndex:i]);
        
        [[NSFileManager defaultManager] removeItemAtURL:[sortedArray objectAtIndex:i] error:&deleteErr];
        if (deleteErr) {
            NSLog (@"Can't delete %@: %@", [sortedArray objectAtIndex:i], deleteErr);
        }
    }
    
}


- (NPT_Result)onFileRequest:(PLT_MediaServerFileRequestCapsuleMy*)info withURL:(NSString *)theURL {
    
    info.getResponse->GetHeaders().SetHeader("Accept-Ranges", "bytes");
    
    if (info.getContext->GetRequest().GetMethod().Compare("GET") && info.getContext->GetRequest().GetMethod().Compare("HEAD")) {
        info.getResponse->SetStatus(500, "Internal Server Error");
        return NPT_SUCCESS;
    }
    
    NSRange range = [theURL rangeOfString:@"ipod-library:"];
    NSString *substring = [theURL substringFromIndex:range.location];
    
    NSRange nameRange		= [theURL rangeOfString:@"?id="];
    NSString *nameStringPart = [theURL substringFromIndex:NSMaxRange(nameRange)];
    
    NSString *fileNamePrefix = @"T_M_File_%@";
    NSString *fileName = [NSString stringWithFormat:fileNamePrefix, nameStringPart];
    NSString *tempDir = [self getTempPath];
    NSString *filePath = [tempDir stringByAppendingPathComponent:fileName];


    
    bool isAlbum = strncmp(substring.UTF8String + sizeof("ipod-library://") - 1, "albm" , 4 ) == 0;
    if (isAlbum)
    {
        NSString *iconFilePath = filePath;
        
        substring = [substring substringToIndex: substring.length -4];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:iconFilePath])
        {
            PLT_HttpServer::ServeFile(info.getContext->GetRequest(),
                                      *info.getContext,
                                      *info.getResponse,
                                      NPT_String([iconFilePath cStringUsingEncoding:NSUTF8StringEncoding]));
            
            NPT_HttpEntity* entity = info.getResponse->GetEntity();
            if (entity) entity->SetContentType("image/png");
            return NPT_SUCCESS;
        }
        else
        {
            //Fill the MpMediaItem fro URL.
            MPMediaQuery *query = [[MPMediaQuery alloc] init] ;
            [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInt:MPMediaTypeMusic] forProperty:MPMediaItemPropertyMediaType]];
            MPMediaItem *mediaItem;
            NSString *target = substring;
            target = [target stringByReplacingOccurrencesOfString:@"albm" withString:@"item"];
            
            for ( MPMediaItem *i in [query items])
            {
                NSURL *assetURL = [i valueForProperty:MPMediaItemPropertyAssetURL];
                if ([assetURL.absoluteString isEqualToString: target]) {
                    mediaItem = i;
                    break;
                }
            }
            
            if( mediaItem) {
                MPMediaItemArtwork *artwork = ((MPMediaItemArtwork *)[mediaItem valueForProperty:MPMediaItemPropertyArtwork]);
                if (artwork) {
                    UIImage *image = [artwork imageWithSize: artwork.imageCropRect.size];
                    if (image) {
                        NSData *pngData =  UIImagePNGRepresentation(image);
                        if (pngData) {
                            [pngData writeToFile:iconFilePath atomically:YES];
                            
                            
                            PLT_HttpServer::ServeFile(info.getContext->GetRequest(),
                                                      *info.getContext,
                                                      *info.getResponse,
                                                      NPT_String([iconFilePath cStringUsingEncoding:NSUTF8StringEncoding]));
                            
                            NPT_HttpEntity* entity = info.getResponse->GetEntity();
                            if (entity) entity->SetContentType("image/png");
                            return NPT_SUCCESS;
                            
                        }
                    }
                }
            }
            
            
        }
        
        
        return NPT_FAILURE;
    }
    
    
    filePath = [ filePath stringByAppendingPathExtension:@"m4a"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        NSURL *theResourceURL = [NSURL URLWithString:substring];

        
        __block BOOL retResult = NO;
        
        AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:theResourceURL options:nil];
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:songAsset presetName: AVAssetExportPresetPassthrough];
        exportSession.outputURL = [NSURL fileURLWithPath:filePath];
        exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        exportSession.shouldOptimizeForNetworkUse = true;

        NSLog(@"export session create");
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                NSLog(@"export session completed");
                retResult = YES;
            } else {
                retResult = false;
                NSLog(@"export session error");
            }
            
            printf("semaphore signal\n");
            dispatch_semaphore_signal(semaphore);
        }];
         
        
        dispatch_semaphore_wait(semaphore,DISPATCH_TIME_FOREVER);
        printf("semaphore wait complete\n");
        
        if (!retResult) {
            info.getResponse->SetStatus(404, "File Not Found");
            return NPT_SUCCESS;
        }
        
    }
    else
    {
        printf("file exist.\n");
    }
    

    
    
    
    PLT_HttpServer::ServeFile(info.getContext->GetRequest(),
                              *info.getContext,
                              *info.getResponse,
                              NPT_String([filePath cStringUsingEncoding:NSUTF8StringEncoding]));
    
    NPT_HttpEntity* entity = info.getResponse->GetEntity();
    if (entity) entity->SetContentType("audio/mpeg3");
    
    
    if ([self updateCurrentFileDate:filePath]) {
        [self sweepCache];
    }
    
    return NPT_SUCCESS;
}

@end


const char str_root_id_music[] = "root_id_music";
const int  len_root_id_music = sizeof(str_root_id_music) - 1;


const char* getRootIdMusic()
{
    return str_root_id_music;
}

int getRootIdMusicLen()
{
    return len_root_id_music;
}
