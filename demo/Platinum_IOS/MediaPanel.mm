//
//  MediaPanel.m
//  demo
//
//  Created by liaogang on 15/6/30.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "MediaPanel.h"

const char * kStrPlayState[] = {
    "NO_MEDIA_PRESENT",
    "PLAYING",
    "STOPPED",
    "PAUSED_PLAYBACK"
};


@implementation MediaPanel

-(void)setVolume:(unsigned int)volume
{
    NSAssert(0 <= volume && volume <= 100, nil);
    _volume = volume;
}

@end

const char *dlna_second_to_stirng(int sec)
{
    static char arg[256];
    memset(arg, 0, 256 * sizeof(char) );
    
    if (sec > 0)
    {
        int v = sec;
        int h = v / (60*60);
        int m = (v - h * 60 * 60 ) / 60;
        int s = (v - m * 60 - h*60*60);
        
        assert( h >= 0 && s < 60 && m < 60);
        
        sprintf(arg, "%02d:%02d:%02d", h , m , s);
    }
    else
    {
        strcpy(arg, "00:00:00");
    }

    
    return arg;
}


int dlna_string_to_second(const char *format)
{
    int h=0,m=0,s=0;
    
    sscanf(format,"%d:%02d:%02d",&h,&m,&s);
    
    assert( h >= 0 && s < 60 && m < 60);

    return (h * 60 + m ) * 60 + s;
}
