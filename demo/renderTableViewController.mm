//
//  renderTableViewController.m
//  demo
//
//  Created by liaogang on 15/5/20.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "renderTableViewController.h"
#import "DlnaControlPoint.h"
#import "UIImageView+WebCache.h"
#import "DemoReachability.h"
#import "PltMicroMediaController.h"
#import "FPPopoverController.h"

@interface UITableViewCellRender : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *renderImage;
@property (weak, nonatomic) IBOutlet UILabel *renderTitle;
@property (weak, nonatomic) IBOutlet UILabel *renderModelDesc;

@end
@implementation UITableViewCellRender
@end


@interface renderTableViewController ()
{
    PLT_DeviceArray deviceArray;
}
@property (nonatomic,strong) DemoReachability* reachabilityForLocalWiFi;
@property (nonatomic,weak) UITableViewCell *selectedCell;
@property (nonatomic,strong) UIPopoverController *popOver;
@property (nonatomic,strong) FPPopoverController *fp;
@end


@implementation renderTableViewController
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+(void)showRenderPopover:(id)sender frame:(CGRect)frame
{
    UIStoryboard *sb =[UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    UINavigationController *nav2 = [sb instantiateViewControllerWithIdentifier:@"renderNav"];
    
    renderTableViewController *rvc = (renderTableViewController*)nav2.topViewController;
    

    UISplitViewController *splitvc = (UISplitViewController*)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    UITableViewCell *cell = sender;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        rvc.popOver = [[UIPopoverController alloc]initWithContentViewController: nav2];
        
        if( sender )
        {
            if ([sender isKindOfClass:[UIBarButtonItem class]]) {
                [rvc.popOver presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
            
            else
            {
                NSAssert([sender isKindOfClass:[UIView class]] , nil);
                
                UIView *viewSender = sender;
                
                CGRect rc2 = [splitvc.view convertRect:frame fromView:viewSender];
                
                [rvc.popOver presentPopoverFromRect:rc2 inView:splitvc.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
            
        }

        
    }
    else
    {
        FPPopoverController *fp = [[FPPopoverController alloc]initWithViewController:nav2.viewControllers.firstObject];
        rvc.fp = fp;
        rvc.hide_uuid = true;
        fp.contentSize = CGSizeMake( splitvc.view.bounds.size.width ,splitvc.view.bounds.size.height / 2.0 );
        
//        [fp presentPopoverFromView:cell.contentView];
        if ( frame.size.width > 0) {
            [fp presentPopoverFromPoint: frame.origin];
//            [fp presentPopoverFromView:sender];
        }
    }
}

-(void)refresh:(void*)data
{
    [self refresh];
    /*
    [self.tableView beginUpdates];
    
    if (data.added) {
        int index = deviceArray.GetItemCount();
        
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation: UITableViewRowAnimationFade];
    }
    else {
        
        int index = 0;
        // get index of target device.
        for ( auto i = deviceArray.GetFirstItem(); i ; ++i,++index) {
            PLT_DeviceDataReference device = *i;
            if (device->GetUUID() == (data.device)->GetUUID()) {
                break;
            }
        }
        
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation: UITableViewRowAnimationFade];
    }
    
    deviceArray = [DlnaControlPoint shared].pController->GetRenderDevices();
    
    [self.tableView endUpdates];
    
    [self.refreshControl endRefreshing];
     
     */
}

-(void)refresh
{
    deviceArray = [DlnaControlPoint shared].pController->GetRenderDevices();
    
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self refresh];
}

- (void)viewDidLoad {
    [super viewDidLoad];
   
    [[DlnaControlPoint shared] setCallback_renderListChanged:^{
        [self refresh];
    }];
    
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(localWiFiChanged:) name:kReachabilityChangedNotificationForDemo object:nil];
    self.reachabilityForLocalWiFi = [DemoReachability reachabilityForLocalWiFi];
    [self.reachabilityForLocalWiFi startNotifier];
    
    [[NSNotificationCenter defaultCenter]postNotificationName:kReachabilityChangedNotificationForDemo object:self.reachabilityForLocalWiFi];
    
    
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    //hi.tan: 让table view 的分割线占据整个屏幕
    [self.tableView setSeparatorInset:UIEdgeInsetsMake(0,0,0,0)];
    //hi.tan： 对没有数据的cell的分割线将其隐藏不显示
    [self setExtraCellLineHidden:self.tableView];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)localWiFiChanged:(NSNotification*)n
{
    [self refresh];
    
    
    DemoReachability *r = n.object;
    auto result = r.currentReachabilityStatus;
    
    static NSInteger lastStatus =  -1;
    
    static UILabel *label = nil;
    
    if (result != lastStatus)
    {
        if( result == DemoNotReachable)
        {
            if(!label)
            {
                label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 200, 40)];
                label.center=CGPointMake( self.tableView.bounds.size.width/2.0, self.tableView.bounds.size.height/2.0);
                label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
                label.textAlignment = NSTextAlignmentCenter;
                label.text=NSLocalizedString(@"Network not reachable", nil);
                [self.tableView addSubview:label];
            }
        }
        else
        {
            if (label) {
                [label removeFromSuperview];
                label = nil;
            }
        }
        
    }
    
    
    
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return deviceArray.GetItemCount();
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCellRender *cell = [tableView dequeueReusableCellWithIdentifier:@"renderTableCell" forIndexPath:indexPath];
    
    unsigned int row = (unsigned int)indexPath.row;
    
    PLT_DeviceDataReference device = *deviceArray.GetItem(row);
    
    if( ![DlnaControlPoint shared].pController->m_CurMediaRenderer.IsNull() && [DlnaControlPoint shared].pController->m_CurMediaRenderer->GetUUID() == device->GetUUID() )
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    cell.renderTitle.text = [NSString stringWithUTF8String: device->GetFriendlyName()];
    
    if (!self.hide_uuid)
        cell.renderModelDesc.text = [NSString stringWithUTF8String: device->GetModelDescription()];
    
    [cell.renderImage sd_setImageWithURL: [NSURL URLWithString:[NSString stringWithUTF8String:device->GetIconUrl()]] placeholderImage:[UIImage imageNamed:@"defaultrender"]];
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = (int)indexPath.row;
    
    [DlnaControlPoint shared].pController->selectMR(row);
    
    UITableViewCell *cell ;
   
    _selectedCell.accessoryType = UITableViewCellAccessoryNone;
    
    
    cell = [tableView cellForRowAtIndexPath:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    _selectedCell = cell;
    
    
    if (self.popOver) {
        [self.popOver dismissPopoverAnimated:YES];
        self.popOver = nil;
    }
    
    if (self.fp) {
        [self.fp dismissPopoverAnimated:YES];
    }
}

//hi.tan: 隐藏多余的分割线
- (void)setExtraCellLineHidden: (UITableView *)tableView

{
    
    UIView *view = [UIView new];
    
    view.backgroundColor = [UIColor clearColor];
    
    [tableView setTableFooterView:view];
    
    //[view release];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80.0;
}
@end
