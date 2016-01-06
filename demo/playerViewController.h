//
//  playerViewController.h
//  demo
//
//  Created by liaogang on 15/5/20.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MediaRendererDelegate.h"

@interface playerViewController : UIViewController
<MediaRendererDelegate>

-(void)tryPresentSelf:(UIViewController*)parent;

@end
