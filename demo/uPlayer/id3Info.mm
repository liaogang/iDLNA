//
//  id3Info.m
//
//  Created by liaogang on 6/20/14.
//
//


#import "id3Info.h"
#import <AVFoundation/AVFoundation.h>

/*
BOOL getId3FromAudio(NSURL *audioFile,
                     NSMutableString *artist,
                     NSMutableString *album,
                     NSMutableString *title,
                     NSMutableString *genre,
                     NSMutableString *year,
                     NSMutableData *image  ,
                     NSMutableString *lyrics)
{
    AVURLAsset *mp3Asset = [[AVURLAsset alloc] initWithURL:audioFile options:nil];
    
    bool bArtist = false;
    bool bAlbum = false;
    bool bTitle = false;
    bool bGenre = false;
    bool bYear = false;
    bool bImage = false;
    
    if(image == nil) bImage = true;
    
    // Is valid mp3 format?
    if ( [mp3Asset availableMetadataFormats].count > 0)
    {
        // First find common meta data.
        for (AVMetadataItem *metadataItem in [mp3Asset commonMetadata])
        {
            NSString *commonKey = metadataItem.commonKey;
            
            if( !bArtist && [commonKey isEqualToString:AVMetadataCommonKeyArtist])
            {
                [artist setString:metadataItem.stringValue];
                bArtist = true;
            }
            else if (!bAlbum && [commonKey isEqualToString:AVMetadataCommonKeyAlbumName])
            {
                [album setString:metadataItem.stringValue];
                bAlbum = true;
            }
            else if (!bTitle && [commonKey isEqualToString:AVMetadataCommonKeyTitle])
            {
                [title setString:metadataItem.stringValue];
                
                bTitle = true;
            }
            else if (!bImage && [commonKey isEqualToString:AVMetadataCommonKeyArtwork])
            {
                if ([metadataItem.value isKindOfClass:[NSDictionary class]])
                    [image appendData: [(NSDictionary*)metadataItem.value objectForKey:@"data"]];
                else if([metadataItem.value isKindOfClass:[NSData class] ])
                    [image appendData: (NSData*)metadataItem.value];
                
                bImage = true;
            }
            
            if (bArtist && bAlbum && bTitle && bImage)
                break;
        }
        
        if(lyrics)
            [lyrics setString: mp3Asset.lyrics];

        bArtist = artist.length> 0;
        bAlbum = album.length > 0;
        bTitle = title.length > 0;
        bImage = image.length > 0;
        
        // Then find stand id3 tag info.
        for (AVMetadataItem *metadataItem in [mp3Asset metadataForFormat: AVMetadataFormatID3Metadata] )
        {
            NSString *key = metadataItem.key;
            
            if (!bTitle && [key isEqualToString: AVMetadataID3MetadataKeyTitleDescription] )
            {
                [title setString:metadataItem.stringValue];
                bTitle = true;
            }
            else if ( !album && [key isEqualToString: AVMetadataID3MetadataKeyAlbumTitle] )
            {
                [album setString: metadataItem.stringValue];
                bAlbum = true;
            }
            else
            if ( !bGenre && [key isEqualToString: AVMetadataID3MetadataKeyContentType] )
            {
                [genre setString: metadataItem.stringValue];
                bGenre = true;
            }
            else if (!bYear && [key isEqualToString: AVMetadataID3MetadataKeyYear] )
            {
                [year setString: metadataItem.stringValue];
                bYear = true;
            }
            else if (!bImage && [key isEqualToString: AVMetadataID3MetadataKeyAttachedPicture] )
            {
                [image appendData: (NSData*)metadataItem.value];
            }
            
            if ( bArtist && bAlbum && bTitle && bGenre && bYear && bImage)
                break;
        }
        
        
        
        //if no title find , use the file name.
        if ([title isEqualToString:@""]) {
            [title setString: audioFile.path.lastPathComponent.stringByDeletingPathExtension];
        }
        
        return TRUE;
    }
    
    
    return FALSE;
}
*/


NSData * getId3ImageFromAudio(NSURL *audioFile)
{
    NSData *result;
    
    AVURLAsset *mp3Asset = [[AVURLAsset alloc] initWithURL:audioFile options:nil];
    
    for (AVMetadataItem *metadataItem in [mp3Asset commonMetadata])
    {
        NSString *commonKey = metadataItem.commonKey;
        
        if ([commonKey isEqualToString:AVMetadataCommonKeyArtwork])
        {
            if ([metadataItem.value isKindOfClass:[NSDictionary class]])
                result = [(NSDictionary*)metadataItem.value objectForKey:@"data"];
            else if([metadataItem.value isKindOfClass:[NSData class] ])
                result = (NSData*)metadataItem.value;
        }
        
        if (result)
            break;
    }
    
    if(!result) {
        for (AVMetadataItem *metadataItem in [mp3Asset metadataForFormat: AVMetadataFormatID3Metadata] )
        {
            NSString *key = (NSString*)metadataItem.key;
            if (!result &&[key isKindOfClass:[NSString class]] && [key isEqualToString: AVMetadataID3MetadataKeyAttachedPicture] )
            {
                result = (NSData*)metadataItem.value;
                break;
            }
        }
    }
    
    return result;
}


NSString *getAudioLyrics(NSURL *audioFile)
{
    AVURLAsset *mp3Asset = [[AVURLAsset alloc] initWithURL:audioFile options:nil];
    return mp3Asset.lyrics;
}
