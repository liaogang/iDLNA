//
//  SDImageCacheThumbnail.m
//  demo
//
//  Created by liaogang on 15/9/28.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDImageCacheThumbnail.h"
#import "UIImageView+WebCache.h"  // sdwebimage

@implementation photoCache

+(SDImageCache *)sharedCache
{
    static SDImageCache *imageCache = nil;
    
    if (imageCache == nil) {
        NSString *const myNamespace  = @"thumbnail_cache";
        imageCache = [[SDImageCache alloc]initWithNamespace: myNamespace];
        
        //we cache compressed images only,so:
        imageCache.shouldDecompressImages = NO;
    }
    
    return imageCache;
}

@end