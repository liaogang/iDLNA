//
//  sourceDeviceController.mm
//  demo
//
//  Created by liaogang on 15/9/17.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "sourceDeviceController.h"
#import "fileBrowserTableViewController.h"
#import "UIImageView+WebCache.h"
#import "DemoReachability.h"
#import <Platinum/Platinum.h>
#import "DlnaControlPoint.h"
#import "constDefines.h"
#import "fileCollectionViewController.h"
#import "UITableViewCellMy.h"


@interface sourceDeviceController ()
{
    PLT_DeviceArray deviceArray;
    NPT_String currentBrowsingDeviceUUID;
}

@property (nonatomic,strong) DemoReachability* reachabilityForLocalWiFi;

@property (nonatomic,copy) CallbackDataDirty callbackDataDirty;
@end

@implementation sourceDeviceController


-(void)set_callback_data_dirty:(CallbackDataDirty)callback
{
    self.callbackDataDirty = callback;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)setNavigationController:(UINavigationController *)navigationController
{
    if (navigationController) {
        _navigationController = navigationController;
    }
}

-(instancetype)initWithDataDirtyCallback:(CallbackDataDirty)callback
{
    self = [super init];
    if (self) {
        self.callbackDataDirty = callback;
        
        
        

        
        
        currentBrowsingDeviceUUID = "";
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localWiFiChanged:) name:kReachabilityChangedNotificationForDemo object:nil];
        
        self.reachabilityForLocalWiFi = [DemoReachability reachabilityForLocalWiFi];
        [self.reachabilityForLocalWiFi startNotifier];
        
        [[NSNotificationCenter defaultCenter]postNotificationName:kReachabilityChangedNotificationForDemo object:self.reachabilityForLocalWiFi];
        

        
        [[DlnaControlPoint shared] setCallback_deviceListChanged:^{
            [self refresh];
        }];
        
        [self refresh];
       
    }
    
    
    
    return self;
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
                label.center=CGPointMake( self.parent.bounds.size.width/2.0, self.parent.bounds.size.height/2.0);
                label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
                label.textAlignment = NSTextAlignmentCenter;
                label.text=NSLocalizedString(@"Network not reachable", nil);
                
                [self.parent addSubview:label];
                
                
                [self.navigationController popToRootViewControllerAnimated:YES];
                [DlnaControlPoint shared].pController->PopDirectoryStackToRoot();
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
    
    
    // pop to root if the current browsing device is removed.
    if (currentBrowsingDeviceUUID != "") {
        bool finded = false;
        int count = deviceArray.GetItemCount();
        for (int i = 0; i < count; i++) {
            PLT_DeviceDataReference device = deviceArray[i];
            if (device->GetUUID() == currentBrowsingDeviceUUID) {
                finded = true;
                break;
            }
        }
        
        if (!finded) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyPopToRoot object:nil];
            [self.navigationController popToRootViewControllerAnimated:YES];
            [DlnaControlPoint shared].pController->PopDirectoryStackToRoot();
            currentBrowsingDeviceUUID = "";
        }
    }
    
    
    NSAssert(self.callbackDataDirty, nil);
    self.callbackDataDirty(source_sections_dlna);
}

#pragma mark - datasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return num_source_sections;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    printf("num_source_sections: %d\n",num_source_sections);
    return num_source_sections;
}

/*
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50;
}
*/


#pragma mark - view for Header
/*
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    int section = indexPath.section;
    
    UICollectionReusableViewPrivate* view =  [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"sourceSectionHeader" forIndexPath:indexPath];
    
    view.headerTitle.text = [NSString stringWithUTF8String: source_names[section]];
    view.headerActivityIndicator.hidden = true;
#ifdef DEBUG
    view.headerButton.tag = section;
#endif
    if (section == source_sections_dlna) {
        view.headerButton.hidden = YES;
    }
    else if( section == source_sections_tumblr)
    {
        view.headerButton.hidden = false;
        [self.tumblrController customCollectViewHeader:view];
    }
    else if( section == source_sections_onedrive)
    {
        view.headerButton.hidden = false;
        [self.oneDriveController customCollectViewHeader:view];
    }
    else
    {
        NSAssert(false, nil);
    }
    
    return view;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIHeaderViewController *headers[num_source_sections] = {0};
    for (int i = 0 ; i < num_source_sections; i++) {
        UIHeaderViewController *header = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"source_header_id"];
        headers[section] = header;
    }
    
    UIHeaderViewController *header = headers[section];
    
    // Why need this stuff?
    header.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    header.headerTitle.text = [NSString stringWithUTF8String: source_names[section]];
    header.headerAddButtton.tag = section;
    if (section == source_sections_dlna) {
        header.headerAddButtton.hidden = YES;
    }
    else if(section == source_sections_tumblr)
    {
        [self.tumblrController customTableViewHeader:header];
    }
    else if( section == source_sections_onedrive)
    {
        [self.oneDriveController customTableViewHeader:header];
    }
    
    return header.view;
}
*/


-(NSInteger)numberOfItemsInSection:(NSInteger)section tableView:(UITableView*)tableView collectionView:(UICollectionView*)collectionView
{
    if (section == source_sections_dlna) {
        return deviceArray.GetItemCount();
    }
    
    NSAssert(false, nil);
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self numberOfItemsInSection:section tableView:tableView collectionView:nil];
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self numberOfItemsInSection:section tableView:nil collectionView:nil];
}

#pragma mark - 


#pragma mark - cell for row

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    if (section == source_sections_dlna)
    {
        int row = (int)indexPath.row;
        
        UICollectionViewCellDetail *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"detailCell" forIndexPath:indexPath];
        
        PLT_DeviceDataReference device = deviceArray[row];
        
        NSString *iconURL = [NSString stringWithUTF8String: device->GetIconUrl()];
        [cell.cellImage sd_setImageWithURL:[NSURL URLWithString: iconURL] placeholderImage:[UIImage imageNamed:@"nearby_device_thumbicon_default.png"]];
        
        cell.cellTitle.text = [NSString stringWithUTF8String: device->GetFriendlyName()];
        
        cell.cellDetail.text = [NSString stringWithUTF8String: device->GetModelDescription()];
        
        return cell;
    }
   
    
    
    NSAssert(false, nil);
    return nil;
 
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = indexPath.section;
    if (section == source_sections_dlna)
    {
        int row = (int)indexPath.row;
        
        NSString *idn = @"deviceListCell";
        
        UITableViewCellSource *cell = [tableView dequeueReusableCellWithIdentifier:idn forIndexPath:indexPath];
        
        PLT_DeviceDataReference device = deviceArray[row];
        
        NSString *iconURL = [NSString stringWithUTF8String: device->GetIconUrl()];
        [cell.cellImage sd_setImageWithURL:[NSURL URLWithString: iconURL] placeholderImage:[UIImage imageNamed:@"nearby_device_thumbicon_default.png"]];
        
        cell.cellText.text = [NSString stringWithUTF8String: device->GetFriendlyName()];
        
        cell.cellDetailText.text = [NSString stringWithUTF8String: device->GetModelDescription()];
        
        return cell;
    }

    
    
    
    NSAssert(false, nil);
    return nil;
}


#pragma mark - didSelect AtIndexPath
-(void)didSelectItemAtIndexPath:(NSIndexPath*)indexPath tableiView:(UITableView*)tableView collectionView:(UICollectionView*)collectionView
{
    int row = (int)indexPath.row;
    NSInteger section = indexPath.section;
    if (section == source_sections_dlna)
    {
        PLT_DeviceDataReference device = deviceArray[row];
        
        currentBrowsingDeviceUUID = device->GetUUID();
        
        [DlnaControlPoint shared].pController->ChooseDeviceWithUUID( currentBrowsingDeviceUUID );
        
        
        fileCollectionViewController *fileCtrl =  [fileCollectionViewController instanceFromStoryboard];
        
        fileCtrl.title = [NSString stringWithUTF8String: device->GetFriendlyName() ];
        [self.navigationController pushViewController:fileCtrl animated:YES];
        
        
        return;
    }

    
    NSAssert(false, nil);
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self didSelectItemAtIndexPath:indexPath tableiView:nil collectionView:collectionView];
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self didSelectItemAtIndexPath:indexPath tableiView:tableView collectionView:nil];
}

#pragma mark -


@end



