//
//  PlayerEngine.h
//  uPlayer
//
//  Created by liaogang on 15/1/27.
//  Copyright (c) 2015年 liaogang. All rights reserved.
//

#import "PlayerTypeDefines.h"

@class PlayerTrack;

@interface PlayerEngine : NSObject

+(instancetype)shared;

///Whether or not the Player is playing not paused.
@property (nonatomic, readonly) BOOL isPlaying;

/**The volume level of the player.
 * This property is persistent.
 */
@property float volume;

-(BOOL)playURL:(NSURL *)url;
-(BOOL)playURL:(NSURL *)url pauseAfterInit:(BOOL)pfi;

-(enum PlayState)getPlayState;

-(bool)isPaused;

-(bool)isPending;

-(bool)isStopped;

-(void)playPause;

-(void)seekToTime:(NSTimeInterval)time;

-(NSTimeInterval)currentTime;

-(NSTimeInterval)totalTime;

-(void)stop;

/// save info and stop.
-(struct PlayStateTime)close;

@end






@interface ProgressInfo : NSObject
@property (nonatomic) double current,
total;
@end
