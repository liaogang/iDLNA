//
//  sourceDeviceTableViewController.m
//  demo
//
//  Created by liaogang on 15/5/19.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "sourceDeviceViewController.h"
#import "sourceDeviceController.h"


@interface sourceDeviceTableViewController ()
@property (nonatomic,strong) sourceDeviceController *innerController;
@end

@implementation sourceDeviceTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak typeof(self) weakSelf = self;
    self.innerController = [[sourceDeviceController alloc]initWithDataDirtyCallback:^(int section){
        [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
    self.innerController.navigationController = self.navigationController;
    self.innerController.parent = self.tableView;
    self.tableView.dataSource = self.innerController;
    self.tableView.delegate = self.innerController;

}

@end

@interface sourceDeviceCollectionViewController ()
<UIGestureRecognizerDelegate>
@property (nonatomic,strong) sourceDeviceController *innerController;
@property (nonatomic, strong) UIButton *deleteButton;
@end

@implementation  sourceDeviceCollectionViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    static bool sViewLoaded = false;
    
    __weak typeof(self) weakSelf = self;
    self.innerController = [[sourceDeviceController alloc]initWithDataDirtyCallback:^(int section){
        
        // is view load complete?
        if (weakSelf.isViewLoaded && sViewLoaded )
        {
            [weakSelf.collectionView reloadData];
//            [weakSelf.collectionView reloadSections:[NSIndexSet indexSetWithIndex:section]];
        }
        
    }];
    self.innerController.navigationController = self.navigationController;
    self.innerController.parent = self.collectionView;
    self.collectionView.dataSource = self.innerController;
    self.collectionView.delegate = self.innerController;
    
    

    
    
    self.collectionView.alwaysBounceVertical = YES;
    
    sViewLoaded = true;
}



@end
