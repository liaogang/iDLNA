//
//  PlayerTrack.h
//  uPlayer
//
//  Created by liaogang on 15/1/27.
//  Copyright (c) 2015年 liaogang. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class PlayerList;

@interface TrackInfo: NSObject
@property (nonatomic,strong) NSString *artist,*title,*album,*genre,*year;
@property (nonatomic,strong) NSString *path;

@property (nonatomic,strong) NSString *lyrics;
@property (nonatomic,strong) UIImage *image;
@end


@interface PlayerTrack : NSObject

-(NSInteger)getIndex;
@property (nonatomic,readonly,getter=getIndex) NSInteger index;

@property (nonatomic,strong) TrackInfo *info;

/// value not need to searialize.
@property (nonatomic,weak) PlayerList *list;

-(instancetype)init:(PlayerList*)list;

//-(void)markSelected;

@end




#if defined(__cplusplus)
extern "C" {
#endif /* defined(__cplusplus) */
   
    
    TrackInfo* getId3Info(NSString *filename);
    
    NSArray* enumAudioFiles(NSString* path);
    
    NSString* compressTitle(TrackInfo *info);
    
    
#if defined(__cplusplus)
}
#endif /* defined(__cplusplus) */
