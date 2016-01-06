//
//  sourceDeviceTableViewController.m
//  demo
//
//  Created by liaogang on 15/5/19.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "sourceDeviceTableViewController.h"
#import "fileBrowserTableViewController.h"
#import "UIImageView+WebCache.h"
#import "Reachability.h"
#import <Platinum/Platinum.h>
#import "DlnaControlPoint.h"


@interface sourceDeviceTableViewController ()
{
    PLT_DeviceArray deviceArray;
}

@property (nonatomic,strong) Reachability* reachabilityForLocalWiFi;

@end

@implementation sourceDeviceTableViewController

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localWiFiChanged:) name:kReachabilityChangedNotification object:nil];
    
    self.reachabilityForLocalWiFi = [Reachability reachabilityForLocalWiFi];
    [self.reachabilityForLocalWiFi startNotifier];
    
    [[NSNotificationCenter defaultCenter]postNotificationName:kReachabilityChangedNotification object:self.reachabilityForLocalWiFi];
    
    
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    [[DlnaControlPoint shared] setCallback_deviceListChanged:^{
        [self refresh];
    }];
    
    [self refresh];
    
    //hi.tan: 让table view 的分割线占据整个屏幕
    [self.tableView setSeparatorInset:UIEdgeInsetsMake(0,0,0,0)];
    //hi.tan： 对没有数据的cell的分割线将其隐藏不显示
    [self setExtraCellLineHidden:self.tableView];
}

-(void)localWiFiChanged:(NSNotification*)n
{
    [self refresh];
    
    Reachability *r = n.object;
    auto result = r.currentReachabilityStatus;
    
    static NSInteger lastStatus =  -1;
    static UILabel *label = nil;
    
    if (result != lastStatus)
    {
        if( result == NotReachable)
        {
            if(!label)
            {
                label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 200, 40)];
                label.center=CGPointMake( self.tableView.bounds.size.width/2.0, self.tableView.bounds.size.height/2.0);
                label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
                label.textAlignment = NSTextAlignmentCenter;
                label.text=NSLocalizedString(@"Network not reachable", nil);
                
                [self.tableView addSubview:label];
                
                
                [self.navigationController popToRootViewControllerAnimated:YES];
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
    
    deviceArray = [DlnaControlPoint shared].pController->GetServerDevices();
    
    [self.tableView endUpdates];
    
    [self.refreshControl endRefreshing];
     */
}


-(void)refresh
{
    deviceArray = [DlnaControlPoint shared].pController->GetServerDevices();
    
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return deviceArray.GetItemCount();
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    int row = (int)indexPath.row;
    
    NSString *idn = @"deviceListCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:idn forIndexPath:indexPath];
    
    PLT_DeviceDataReference device = deviceArray[row];
    
    //hi.tan:刚开始采用默认图片会撑满整个cell表格
    UIImage *defaultIcon = [UIImage imageNamed:@"nearby_device_thumbicon_default.png"];
    UIImage * icon = nil;
    UIGraphicsBeginImageContext(CGSizeMake(64.0f, 64.0f));
    CGRect rec = CGRectMake(0, 0, 64.0f, 64.0f);
    [defaultIcon drawInRect:rec];
    icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    cell.imageView.frame.size = CGSizeMake(64, 64);
    
    NSString *iconURL = [NSString stringWithUTF8String: device->GetIconUrl()];
    [cell.imageView sd_setImageWithURL:[NSURL URLWithString: iconURL] placeholderImage:[UIImage imageNamed:@" "]];
    
    cell.textLabel.text = [NSString stringWithUTF8String: device->GetFriendlyName()];
    
    cell.detailTextLabel.text = [NSString stringWithUTF8String: device->GetType()];//device->GetUUID()];
    
    
    CGSize itemSize = CGSizeMake(64, 64);
    UIGraphicsBeginImageContext(itemSize);
    CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
    [cell.imageView.image drawInRect:imageRect];
    cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = (int)indexPath.row;
    
    PLT_DeviceDataReference device = deviceArray[row];
    
    [DlnaControlPoint shared].pController->ChooseDeviceWithUUID( device->GetUUID() );
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80.0;
}


//hi.tan: 隐藏多余的分割线
- (void)setExtraCellLineHidden: (UITableView *)tableView

{
    
    UIView *view = [UIView new];
    
    view.backgroundColor = [UIColor clearColor];
    
    [tableView setTableFooterView:view];
    
    //[view release];
    
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    int row = (int)[self.tableView indexPathForSelectedRow].row;
    
    fileBrowserTableViewController *fileCtrl =  [segue destinationViewController];
    
    PLT_DeviceDataReference device = deviceArray[row];
    fileCtrl.title = [NSString stringWithUTF8String: device->GetFriendlyName() ];
}

@end
