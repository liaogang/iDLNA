//
//  UISlider+hideThumbWhenDisable.m
//  demo
//
//  Created by liaogang on 15/8/5.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "UISlider+hideThumbWhenDisable.h"

@implementation UISlider (hideThumbWhenDisable)

-(void)setSliderEnabled:(BOOL)e
{
    self.enabled=e;
    if (e == FALSE)
    {
        NSAssert([UIImage imageNamed:@"clear_thumb"], nil);
        [self setThumbImage:[UIImage imageNamed:@"clear_thumb"] forState:UIControlStateNormal];
    }
    else
    {
        [self setThumbImage:nil forState:UIControlStateNormal];
    }
}

@end
