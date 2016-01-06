//
//  renderTableViewController.h
//  demo
//
//  Created by liaogang on 15/5/20.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface renderTableViewController : UITableViewController

/// hide uuid when is pop over view.
@property (nonatomic) bool hide_uuid;

+(void)showRenderPopover:(id)sender frame:(CGRect)frame;

@property (nonatomic,weak) UIViewController *viewControllerPresentThis;

@end
