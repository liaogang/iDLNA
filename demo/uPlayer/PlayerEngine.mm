//
//  PlayerEngine.mm
//  uPlayer
//
//  Created by liaogang on 15/1/27.
//  Copyright (c) 2015年 liaogang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "PlayerEngine.h"
#import "PlayerMessage.h"
#import "IDZTrace.h"
#import "IDZOggVorbisFileDecoder.h"
#import "IDZAudioPlayer.h"
#import "IDZAQAudioPlayer.h"

@interface PlayerEngine ()
<IDZAudioPlayerDelegate>
{
    PlayState _state;
    BOOL _playTimeEnded;
    dispatch_source_t	_timer;
}

@property (nonatomic,strong) AVPlayer *player;

@property (nonatomic,strong) AVAudioPlayer *audioPlayer;

@property (nonatomic) bool isOgg;

@property (nonatomic,strong) id<IDZAudioPlayer> oggPlayer;

@end

@implementation PlayerEngine

+(instancetype)shared
{
    static PlayerEngine *e = nil;
    if (!e) {
        e = [[PlayerEngine alloc]init];
    }
    
    return e;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        
        _playTimeEnded = TRUE;
        
        _state = playstate_stopped;
        
        self.player = [[AVPlayer alloc]init];
        self.player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
 
//        addObserverForEvent(self, @selector(playNext), EventID_track_stopped_playnext);
        
//        addObserverForEvent(self, @selector(playNext), EventID_to_play_next);
        
//        addObserverForEvent(self, @selector(needResumePlayAtBoot), EventID_player_document_loaded);
       
        addObserverForEvent(self, @selector(stop), EventID_to_stop);
        
        addObserverForEvent(self, @selector(playPause), EventID_to_play_pause_resume);
        
//        addObserverForEvent(self, @selector(playRandom), EventID_to_play_random);
        
        
        
        NSNotificationCenter *d =[NSNotificationCenter defaultCenter];
        
        [d addObserver:self selector:@selector(DidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        
        // Update the UI 5 times per second
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, NSEC_PER_SEC / 2, NSEC_PER_SEC / 3);
        
        dispatch_source_set_event_handler(_timer, ^{
            
                if ( [self getPlayState] == playstate_playing)
                {
                    ProgressInfo *info=[[ProgressInfo alloc]init];
                    info.current =  [self currentTime];
                    info.total = [self totalTime];
                    
                    if( !isnan(info.current) && !isnan(info.total) )
                        postEvent(EventID_track_progress_changed, info);
                    
                }
        });
        
        // Start the timer
        dispatch_resume(_timer);
    }
    
    return self;
}

-(void)DidPlayToEndTime:(NSNotification*)n
{
    _playTimeEnded = TRUE;
    
    [self stopInner];
    
    postEvent(EventID_track_stopped_playnext, nil);
    
    /*
    if( player().document.trackSongsWhenPlayStarted)
        postEvent(EventID_to_reload_tracklist, player().playing);
     */
}

-(void)playNext
{
    /*
    PlayerDocument *d = player().document;
    PlayerQueue *queue = d.playerQueue;
    
    PlayerTrack *trackQueue = [queue pop] ;
    if ( trackQueue )
    {
        playTrack(trackQueue);
    }
    else
    {
        PlayerTrack *track = player().playing;
        PlayerList *list = track.list;
        
        assert(list);
        
        int index = (int)track.index;
        int count = (int)[list count];
        int indexNext =-1;
        PlayOrder order = (PlayOrder)d.playOrder;
        
        if (order == playorder_single) {
            [self stop];
        }
        else if (order == playorder_default)
        {
            indexNext = index +1;
        }
        else if(order == playorder_random)
        {
            static int s=0;
            if(s++==0)
                srand((uint )time(NULL));
            
            indexNext =rand() % (count) - 1;
        }else if(order == playorder_repeat_single)
        {
            playTrack(track);
            return;
            
        }else if(order == playorder_repeat_list)
        {
            indexNext = index + 1;
            if (indexNext == count - 1)
                indexNext = 0;
        }
        
        
        track = nil;
        if ( indexNext >= 0 && indexNext < [list count] )
            track = [list getItem: indexNext ];
        
        playTrack(track);
    }
    */
}

-(void)dealloc
{
    removeObserver(self);
}

-(PlayState)getPlayState
{
    if ( _playTimeEnded || _player.currentItem == nil )
    {
        return playstate_stopped;
    }
    else
    {
        if (_player.rate == 0.0)
        {
            return playstate_paused;
        }
        else
        {
            return playstate_playing;
        }
    }
}

-(BOOL)isPlaying
{    if (self.isOgg) {
        return [self.oggPlayer isPlaying];
    }
    
    return  (_player.currentItem != nil) && (_player.rate == 1.0) ;
}

-(bool)isPaused
{    if (self.isOgg) {
        return ![self.oggPlayer isPlaying];
    }
    
    return _player.rate == 0.0;
}

-(bool)isStopped
{
    if (self.isOgg) {
        return  ![self.oggPlayer isPlaying];
    }
    
    return _player.currentItem == nil;
}

-(bool)isPending
{
    return _state == playstate_pending;
}

-(void)playRandom
{/*
    PlayerDocument *d = player().document;
    
    PlayerTrack *track = player().playing;
    
    PlayerList *list = track.list;
    
    if (!list)
        list = d.playerlList.selectItem ;
    
    assert(list);
    
    int count = (int)[list count];
    
    static int s=0;
    if(s++==0)
        srand((uint )time(NULL));
    
    int indexNext =rand() % (count) - 1;
    
    PlayerTrack* next = nil;
    
    if ( indexNext > 0 && indexNext < [list count] )
        next = [list getItem: indexNext ];
    
    playTrack(next);
    
    if( player().document.trackSongsWhenPlayStarted)
        postEvent(EventID_to_reload_tracklist, next );
  */
}

-(void)playPause
{
    if (self.isPlaying) {
            if (self.isOgg) {
        [self.oggPlayer pause];
    }else
        [_player pause];
        _state = playstate_paused ;
        postEvent(EventID_track_paused, nil);
    }
    else if (self.isPaused)
    {
        if (self.isOgg)
            [self.oggPlayer play];
        else
            [_player play];
        
        
        _state = playstate_playing ;
        _playTimeEnded = FALSE;
        postEvent(EventID_track_resumed, nil);
    }
    
    
    postEvent(EventID_track_state_changed, nil);
}


-(void)seekToTime:(NSTimeInterval)time
{
    if (self.isOgg) {
        self.oggPlayer.currentTime = time;
    }
    else
        [_player seekToTime: CMTimeMakeWithSeconds( time , 1) ];
}

-(NSTimeInterval)currentTime
{
    if (self.isOgg) {
        return [self.oggPlayer currentTime];
    }
    
   	CMTime time = _player.currentTime;
    
    return CMTimeGetSeconds(time);
}

-(NSTimeInterval)totalTime
{
    NSTimeInterval result;
    if (self.isOgg) {
        result = [self.oggPlayer duration];
        
    }
   else
    result = CMTimeGetSeconds(_player.currentItem.duration);
    
    if (isnan(result) )
        return 0.;
    
    return result;
}

-(BOOL)playURL:(NSURL *)url pauseAfterInit:(BOOL)pfi
{
    _player  = [AVPlayer playerWithURL:url];
    
    postEvent(EventID_track_stopped, nil);
    
    if (pfi == false)
        [_player play];
   
    
    /*
    if (!self.audioPlayer) {
        self.audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:url error:nil];
        [self.audioPlayer prepareToPlay];
        [self.audioPlayer play];
    }
    */
    
    _playTimeEnded = FALSE;
    
    ProgressInfo *info = [[ProgressInfo alloc]init];
    info.total = [self totalTime];
    postEvent(EventID_track_started, info);
    
    postEvent(EventID_track_state_changed, nil);
    
    return 1;
}



-(BOOL)playURL:(NSURL *)url
{
    return [self playURL:url pauseAfterInit:false];
}

-(void)stopInner
{    if (self.isOgg) {
        [self.oggPlayer stop];
    }
else{
    [_player pause];
    [_player replaceCurrentItemWithPlayerItem:nil];
}
    
    postEvent(EventID_track_stopped, nil);
    postEvent(EventID_track_state_changed, nil);
}


-(void)stop
{
    if ([self getPlayState] == playstate_stopped) {
        return;
    }
    
    if (self.isOgg) {
        [self.oggPlayer stop];
    }
    else
    {
        [_player pause];
        [_player replaceCurrentItemWithPlayerItem:nil];
    }
    //player().playing = nil;
    
    postEvent(EventID_track_stopped, nil);
    postEvent(EventID_track_state_changed, nil);
}

-(PlayStateTime)close
{
    PlayStateTime st;
    st.time =[self currentTime];
    st.state = [self getPlayState];
    st.volume = self.volume;
    [self stopInner];
    return st;
}

- (void)setVolume:(float)volume
{
    _player.volume = volume;
}

- (float)volume
{
    return  _player.volume;
}

#pragma mark - IDZAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(id<IDZAudioPlayer>)player successfully:(BOOL)flag
{
    NSLog(@"%s successfully=%@", __PRETTY_FUNCTION__, flag ? @"YES"  : @"NO");
    //[self stopTimer];
    //[self updateDisplay];
}

- (void)audioPlayerDecodeErrorDidOccur:(id<IDZAudioPlayer>)player error:(NSError *)error
{
    NSLog(@"%s error=%@", __PRETTY_FUNCTION__, error);
    //[self stopTimer];
    //[self updateDisplay];
}

@end



@implementation ProgressInfo



@end


int getNext(enum PlayOrder order , int curr , int lower , int upper)
{
    if (order == playorder_single)
    {
        return lower - 1;
    }
    else if (order == playorder_default)
    {
        if (curr + 1 == upper)
            return lower - 1;
        else
            return curr +1;
    }
    else if(order == playorder_random)
    {
        static int s=0;
        if(s++==0)
            srand((uint )time(NULL));
        
        return rand() % (upper - lower) + lower - 1;
    }
    else if(order == playorder_repeat_single)
    {
        return curr;
    }
    else if(order == playorder_repeat_list)
    {
        if (curr +1 == upper)
            return lower;
        else
            return curr +1;
    }
    else if(order == playorder_reverse)
    {
        return getPrev(lower, curr, upper);
    }
    
    
    assert(false);
    return -1;
}

int getPrev(int lower,int curr,int upper)
{
    return (curr == lower) ? upper : curr - 1;
}

