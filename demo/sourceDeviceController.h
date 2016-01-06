//
//  sourceDeviceController.h
//  demo
//
//  Created by liaogang on 15/9/17.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "constDefines.h"


@interface sourceDeviceController : NSObject
< UITableViewDataSource,
UITableViewDelegate,
UICollectionViewDataSource,
UICollectionViewDelegate 
>

-(instancetype)initWithDataDirtyCallback:(CallbackDataDirty)callback;

@property (nonatomic,weak) UINavigationController *navigationController;
@property (nonatomic,weak) UIView *parent;

//-(void)set_callback_data_dirty:(CallbackDataDirty)callback;

@end



