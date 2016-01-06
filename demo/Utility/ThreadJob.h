//
//  ThreadJob.m
//  uPlayer
//
//  Created by liaogang on 15/2/16.
//  Copyright (c) 2015年 liaogang. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^JobBlock)();

typedef void (^JobBlockDone)();

void dojobInBkgnd(JobBlock job ,JobBlockDone done);
