//
//  UPnPEngine.h
//  demo
//
//  Created by geine on 6/16/15.
//  Copyright (c) 2015 com.cs. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 should call [[NSUserDefaults standardUserDefaults] synchronize] when applicationDidEnterBackground
 */
@interface UPnPEngine : NSObject

+ (instancetype)getEngine;

-(void)intendStartRootFileServer;

- (void)startUPnP;

- (void)stopUPnP;

- (BOOL)isRunning;

-(void)disable;
-(void)enable;
-(bool)isDisabled;
-(bool)isEnabled;

@end

extern NSString *kKeyDMS_enabled;

extern NSString *kNotifyDMSStopped;

extern NSString *kNotifyDMSStarted;
