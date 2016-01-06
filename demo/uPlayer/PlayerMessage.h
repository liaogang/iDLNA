//
//  PlayerMessage.h
//  uPlayer
//
//  Created by liaogang on 15/1/27.
//  Copyright (c) 2015年 liaogang. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    EventID_track_started = 0, // param: ProgressInfo *info
    EventID_track_stopped ,
    EventID_track_paused ,
    EventID_track_resumed ,
    
    EventID_track_state_changed,
    
    EventID_track_selected ,
    
    /// param : ProgressInfo *info.
    EventID_track_progress_changed ,
    EventID_playerqueue_changed ,
    
    /// 使配置生效 , loaded failed , or successed.
    EventID_player_document_loaded ,
    
    /// @param: PlayerError *error;
    EventID_play_error_happened,
    
    /// A PlayerList's track number changed. @param: PlayerList *list;
    EventID_tracks_changed,
    
    /// playerlist added or removed. @param: none.
    EventID_list_changed,
    
    EventID_importing_tracks_begin,
    EventID_importing_tracks_end,
    EventID_applicationWillTerminate, // save layout config
    /// param: PlayerList* list , if list is nil , then go to the playing item.
    /// else reload the list at list.topitem. and list is selected.
    EventID_to_reload_tracklist ,
    EventID_to_save_config,
    EventID_to_reload_lyrics,
    EventID_to_center_item,
    EventID_to_play_selected_track,
    EventID_to_show_playlist,
    
    EventID_to_play_pause_resume,
    EventID_to_stop,
    EventID_track_stopped_playnext , // play next by track ended.
    EventID_to_play_next, // play next by user
    EventID_to_play_prev,
    EventID_to_play_random,
    EventID_to_play_item, // PlayerTrack* item;
    EventID_to_love_item // PlayerTrack* item; nil to love the playing item
} EventID;





#if defined(__cplusplus)
extern "C" {
#endif /* defined(__cplusplus) */

    void initPlayerMessage();
    
    inline int getEventCount();
    
    const char *eventID2String(EventID et);
    
    void addObserverForEvent(id observer , SEL sel, EventID et);
    
    void removeObserverForEvent(id observer , SEL sel, EventID et);
    
    void removeObserver(id observer);
    
    void postEvent(EventID et , id object);
    
    void postEventByString( NSString *strEvent , id object);
    
#if defined(__cplusplus)
}
#endif /* defined(__cplusplus) */
