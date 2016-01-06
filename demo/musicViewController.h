//
//  musicViewController.h
//  demo
//
//  Created by liaogang on 15/6/26.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface musicViewController : UIViewController

/// pause or resume
-(void)playPause;

-(void)playMedia:(NSURL*)url title:(NSString*)title artist:(NSString*)artist album:(NSString*)album album_uri:(NSString*)album_uri;

/// seek to some seconds.
-(void)seek:(float)sec;

-(void)stop;

@end
