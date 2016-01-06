//
//  PlayerTrack.m
//  uPlayer
//
//  Created by liaogang on 15/1/27.
//  Copyright (c) 2015年 liaogang. All rights reserved.
//


#import "PlayerTrack.h"
//#import "PlayerList.h"


@interface TrackInfo()
@end

@implementation TrackInfo
@end



@implementation PlayerTrack

/*
-(NSInteger)getIndex
{
    return [self.list getIndex:self];
}
*/

-(instancetype)init
{
    NSAssert(false, nil);
    return nil;
}

-(instancetype)init:(PlayerList*)list
{
    self =[ super init];
    if (self) {
        self.list=list;
    }
    return self;
}

/*
-(void)markSelected
{
    _list.selectIndex = (int) self.index;
}
*/

@end

NSString* compressTitle(TrackInfo *info)
{
    if (info.artist.length > 0)
        return  [NSString stringWithFormat:@"%@ - %@", info.artist, info.title];
    else
        return  info.title;
}
