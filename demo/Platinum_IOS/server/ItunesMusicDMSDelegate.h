//
//  ItunesMusicDMSDelegate.h
//  demo
//
//  Created by geine on 6/17/15.
//  Copyright (c) 2015 com.cs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Platinum/Platinum.h>
#import "PltMediaServerObjectMy.h"

const char* getRootIdMusic();
int getRootIdMusicLen();

@interface ItunesMusicDMSDelegate : NSObject <PLT_MediaServerDelegateObject>

@property(nonatomic, retain)NSArray *albumsArray;

@end
