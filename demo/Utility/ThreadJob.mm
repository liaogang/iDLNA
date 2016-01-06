//
//  ThreadJob.m
//  uPlayer
//
//  Created by liaogang on 15/2/16.
//  Copyright (c) 2015年 liaogang. All rights reserved.
//

#import "ThreadJob.h"

typedef void (^JobBlock)();
typedef void (^JobBlockDone)();


void dojobInBkgnd(JobBlock job ,JobBlockDone done)
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        job();
        if (done)
            dispatch_async(dispatch_get_main_queue(), ^{
                done();
            });
    });
    
}
