//
//  PlayerMessage.mm
//  uPlayer
//
//  Created by liaogang on 15/1/27.
//  Copyright (c) 2015年 liaogang. All rights reserved.
//

#import "PlayerMessage.h"

#import <AVFoundation/AVFoundation.h>

#import "MAAssert.h"

const char *arrEvent[] =
{
    "track_started",
    "track_stopped",
    "track_paused",
    "track_resumed",
    
    "track_state_changed",
    
    "track_selected",
    "track_progress_changed",
    "playerqueue_changed",
    "player_document_loaded",
    
    "play_error_happened",
    
    "tracks_changed",
    "list_changed",
    
    "importing_tracks_begin",
    "importing_tracks_end",
    "applicationWillTerminate",
    "to_reload_tracklist",
    "to_save_config",
    "to_reload_lyrics",
    "to_center_item",
    "to_play_selected_track",
    "to_show_playlist",
    
    "to_play_pause_resume",
    "to_stop",
    "track_stopped_playnext",
    "to_play_next",
    "to_play_prev",
    "to_play_random",
    "to_play_item",
    "to_love_item"
};

NSNotificationCenter *sCenter ;

void initPlayerMessage()
{
    sCenter = [[NSNotificationCenter alloc]init];
}

inline int getEventCount()
{
    return sizeof(arrEvent)/sizeof(arrEvent[1]);
}

NSString *eventIDtoString(EventID et)
{
    return [NSString stringWithUTF8String: arrEvent[et]];
}

const char *eventID2String(EventID et)
{
    return arrEvent[et];
}

void addObserverForEvent(id observer , SEL sel, EventID et)
{
    MAAssert( sCenter , @"sCenter is nil , call `initPlayerMessage` before `addObserver` .");
    
    [sCenter addObserver:observer selector:sel name: eventIDtoString(et) object:nil];
}

void removeObserverForEvent(id observer , SEL sel, EventID et)
{
    [sCenter removeObserver:observer name:eventIDtoString(et) object:nil];
}

void removeObserver(id observer)
{
    [sCenter removeObserver:observer];
}


void postEvent(EventID et , id object)
{
    [sCenter postNotificationName: eventIDtoString(et) object:object];
}

void postEventByString( NSString *strEvent , id object)
{
    [sCenter postNotificationName: strEvent object:object];
}
