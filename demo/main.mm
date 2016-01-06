//
//  main.m
//  demo
//
//  Created by liaogang on 15/5/18.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

#ifdef DEBUG
#import "test.h"
#endif

int main(int argc, char * argv[]) {
    
#ifdef DEBUG
    testMain();
#endif
    
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
