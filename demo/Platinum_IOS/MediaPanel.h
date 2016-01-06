//
//  MediaPanel.h
//  demo
//
//  Created by liaogang on 15/6/30.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import <Foundation/Foundation.h>

enum PlayState2
{
    PlayState_unknown = 0,
    PlayState_playing,
    PlayState_stopped,
    PlayState_paused,
};

/// @see http://upnp.org/specs/av/UPnP-av-AVTransport-v1-Service.pdf ,Table 1.1
extern const char * kStrPlayState[];


/**
 表示DMPlayer状态
 */
@interface MediaPanel : NSObject

/**
 volume level is defined as an integer number between 0 and 100.
 @see <<DLNA Architecture>>17.2.7
 */
@property (nonatomic,assign) unsigned int volume;

/// "1"静音,"0"没有静音
@property (nonatomic,assign) BOOL mute;

/** Time Format : H+:MM:SS[.F+] or H+:MM:SS[.F0/F1]
    @see http://www.upnp.org/specs/av/UPnP-av-AVTransport-v3-Service-20101231.pdf  2.2.15
    `AbsoluteTimePosition` is not used in the DLNA context. So use `RelativeTimePosition` instead.
    @see <<DLNA architecture>> 14.2.2 and 14.2.24
 
 */
@property (nonatomic,strong) NSString *trackPosition,*trackDuration;

@property (nonatomic) enum PlayState2 playState;

@end

int dlna_string_to_second(const char *format);

const char *dlna_second_to_stirng(int sec);

