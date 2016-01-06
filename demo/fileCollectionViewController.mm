//
//  fileCollectionViewController.m
//  demo
//
//  Created by liaogang on 15/9/17.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "fileCollectionViewController.h"
#import "UIImageView+WebCache.h"  // sdwebimage
#import "UIAlertViewBlock.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVAsset.h>
#import "PltMicroMediaController.h"
#import "DlnaControlPoint.h"
#import "renderTableViewController.h"
#import "UIImage+Resize.h"
#import "UIImage+UIImageExt.h"
#import "ThreadJob.h"
#import "constDefines.h"
#import "constFunctions.h"
#import "UITableViewCellMy.h"
#import <CoreFoundation/CoreFoundation.h>
#import "SDImageCacheThumbnail.h"


@interface UICollectionViewCellSimple : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *cellImage;
@property (weak, nonatomic) UILabel *cellTitle;
@property (weak, nonatomic) UILabel *cellDetail;
@end


@interface UICollectionViewCellBasic : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *cellImage;
@property (weak, nonatomic) IBOutlet UILabel *cellTitle;
@property (weak, nonatomic) UILabel *cellDetail;
@end



bool compareNSDate(NSDate* a, NSDate* b)
{
    NSDateComponents *componentsA = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:a];
    NSDateComponents *componentsB = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:b];
    return [componentsA day] == [componentsB day] &&
    [componentsA month] == [componentsB month] &&
    [componentsA year] == [componentsB year];
}

enum MediaType
{
    Unknown,
    Video,
    Folder,
    Photo,
    Music,
    Normal
};


@interface MediaObjectWrapper : NSObject
-(instancetype)initWith:(PLT_MediaObject*)inner;
-(NSDate*)get_date;

/// i.e. 1900年02月12号 12:22:11
-(NSString*)get_date_time_string;
/// i.e. 1900年02月12号
-(NSString*)get_date_string;

-(PLT_MediaObject*)get_inner;
@end



@interface fileCollectionViewController ()
{
    PLT_MediaObjectListReference files;
    SortType _sort_type;
    
   
    int selected;
    int hasNoPhotoItem; // all photos?

    
    PlayState2 playStateNow;
}

/**
 true, 有文件夹，不分组显示.
 false,没有文件夹，按时间排序，分组显示。
 */
@property (nonatomic) bool sorted;

@property (nonatomic,strong) NSMutableArray *arrSortListDate,*arrSortListAddr;

// date string to array
@property (nonatomic,strong) NSMutableDictionary *mapDate,*mapAddr;

/// data for photo browser
@property (nonatomic,strong) NSMutableArray *urlPhotos;

/** layout larger , in levels,
 */
@property (nonatomic,strong) UICollectionViewFlowLayout *layout0,*layout1,*layout2,*layoutCurr;

@property (nonatomic,weak) UICollectionReusableViewPrivate *footView;

@property (nonatomic,strong) UIRefreshControl *refreshControl;

@end

@implementation fileCollectionViewController

+(instancetype)instanceFromStoryboard
{
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil]instantiateViewControllerWithIdentifier:@"IDFileBrowserCollectionViewController"];
}

-(void)willMoveToParentViewController:(UIViewController *)parent
{
    // View is disappearing because it was popped from the stack
    //退回上级时,调用cdup,再刷新数据调用ls.
    if (parent == nil)
    {
        [DlnaControlPoint shared].pController->HandleCmd_cdup();
        
        
        [[SDWebImageManager sharedManager] cancelAll];
        
        [[SDImageCache sharedImageCache] clearMemory];
        
        [[photoCache sharedCache] clearMemory];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.arrSortListDate = [NSMutableArray array];
    self.arrSortListAddr =[NSMutableArray array];
    self.mapAddr = [NSMutableDictionary dictionary];
    self.mapDate = [NSMutableDictionary dictionary];
    
    _sort_type = SortType_Date;
    
    
    selected = -1;
    
    //layout0 , 20,20
    self.layoutCurr = self.collectionViewLayout;
    self.layout0 = self.layoutCurr;
    
    self.layout1 = [[UICollectionViewFlowLayout alloc]init];
    self.layout1.itemSize = CGSizeMake(80, 80);
    self.layout1.minimumLineSpacing = 4.;
    self.layout1.minimumInteritemSpacing = 4.;
    self.layout1.sectionInset = UIEdgeInsetsMake(4., 10., 1., 1.);
    
    
    self.layout2 = [[UICollectionViewFlowLayout alloc]init];
    
    if (curDeviceIsPad()) {
        self.layout2.itemSize = CGSizeMake(142, 142);
    }
    else
    {
        self.layout2.itemSize = CGSizeMake(100, 100);
    }
    
    self.layout2.minimumLineSpacing = 4.;
    self.layout2.minimumInteritemSpacing = 4.;
    self.layout2.sectionInset = UIEdgeInsetsMake(4., 10., 1., 1.);

    
    // pinch gesture
    UIPinchGestureRecognizer *reg = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(pinched:)];
    [self.collectionView addGestureRecognizer:reg];
    
    
    // refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlAction) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.refreshControl];
    [self.refreshControl beginRefreshing];
    
    
    // can not change refresh's color to white,use UIActivityIndicatorView instead
    UIActivityIndicatorView *a = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self.refreshControl addSubview: a];
    a.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    a.center = self.refreshControl.center;
    [a startAnimating];
    
    
    NSAssert( [UIImage imageNamed:@"folder"] , nil);
    NSAssert( [UIImage imageNamed:@"null"] , nil);
    NSAssert( [UIImage imageNamed:@"video"] , nil);
    NSAssert( [UIImage imageNamed:@"music"] , nil);
    
    [self refresh];
}


-(void)refreshControlAction
{
    
}


/// show larger layout, return zoomed
-(bool)zoom_in
{
    if (self.sorted) {
        if (self.layoutCurr == self.layout0) {
            [self.collectionView setCollectionViewLayout:self.layout1 animated:YES];
            self.layoutCurr = self.layout1;
            return true;
        }
        else if (self.layoutCurr == self.layout1) {
            [self.collectionView setCollectionViewLayout:self.layout2 animated:YES];
            self.layoutCurr = self.layout2;
            self.footView.hidden = false;
            return true;
        }
        else
        {
            NSAssert(self.layoutCurr == self.layout2, nil);
            return false;
        }
    }
    return false;
}

/// show smaller layout,return zoomed
-(bool)zoom_out
{
    if (self.sorted) {
        if (self.layoutCurr == self.layout2) {
            [self.collectionView setCollectionViewLayout:self.layout1 animated:YES];
            self.layoutCurr = self.layout1;
            return true;
        }
        else if (self.layoutCurr == self.layout1) {
            [self.collectionView setCollectionViewLayout:self.layout0 animated:YES];
            self.layoutCurr = self.layout0;
            return true;
        }
        else
        {
            NSAssert(self.layoutCurr == self.layout0, nil);
            return false;
            
        }
    }
    
    return false;
}

-(void)pinched:(UIPinchGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        if(gesture.scale > 1)
        {
            [self zoom_in];
        }
        else{
            [self zoom_out];
        }
    }


}

-(void)viewWillLayoutSubviews
{
    [self.collectionView setCollectionViewLayout:self.layout2];
}

-(void)sort_data:(SortType)sort_type
{
    self.sorted = false;
    
    int c = 0;
    bool hasItem = false;
    if (!files.IsNull())
    {
        c = files->GetItemCount();
        hasItem = c > 0;
    }
    
    
    if (hasItem)
    {
        bool hasFolder = false;
        for (int i = 0 ; i < c; i++)
        {
            auto it = files->GetItem(i);
            PLT_MediaObject *data = *it;

            if (data->IsContainer()) {
                hasFolder = true;
                break;
            }
        }
        
        
        self.layoutCurr = self.layout2;
        
//        [self.collectionView setCollectionViewLayout:self.layout2];
        if (hasFolder)
        {
//            [self.collectionView setCollectionViewLayout:self.layout2];
        }
        else{
            self.sorted = true;
            
            
            for (int i = 0 ; i < c; i++)
            {
                auto it = files->GetItem(i);
                PLT_MediaObject *data = *it;
                
                MediaObjectWrapper *w = [[MediaObjectWrapper alloc]initWith:data];
                [w get_date];
                
                NSString *dateString = [w get_date_string];

                // find one
                NSMutableArray *arr = self.mapDate[dateString];
                if (arr == nil) {
                    NSMutableArray *arr = [NSMutableArray arrayWithObjects:w, nil];
                    [self.arrSortListDate addObject:arr];
                    self.mapDate[dateString]= arr;
                }
                else
                    [arr addObject:w];
                
                
                
            }
        }
        
        
        
        
    }
    else
    {
        UILabel *label = [[UILabel alloc]initWithFrame:self.collectionView.bounds];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor lightTextColor];
        label.text = NSLocalizedString(@"No items",nil);
        CGFloat h =  self.navigationController.navigationBar.frame.size.height;
        label.center =   CGPointMake(self.collectionView.center.x, self.collectionView.center.y - h - h);
        [self.collectionView addSubview:label];
        
        
        
    }
    
}


-(void)refresh
{
    __weak fileCollectionViewController *weakSelf = self;
    
    dojobInBkgnd(^{
        fileCollectionViewController* strongSelf = weakSelf;
        strongSelf->files = [DlnaControlPoint shared].pController->ls();
        
    }, ^{
        
        [weakSelf sort_data:_sort_type];
        
        [weakSelf.refreshControl endRefreshing];
        [weakSelf.refreshControl removeFromSuperview];
        weakSelf.refreshControl = nil;
        [weakSelf.collectionView reloadData];
    });
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    [[SDImageCache sharedImageCache] clearMemory];
        
    [[photoCache sharedCache] clearMemory];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    if (self.sorted)
        return self.arrSortListDate.count + 1;
    else
        return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger count;
    if (self.sorted) {
        if (section < self.arrSortListDate.count) {
            NSArray *arr = self.arrSortListDate[section];
            count = arr.count;
        }
        else
        {
            // this is the statistics section.
            return 0;
        }
    }
    else
        count = files.IsNull()?0:files->GetItemCount();
    
    return count;
}

/*
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
//    self.layout1.
//    UICollectionViewDelegateFlowLayout
    //UIImage *image = [imageArray objectAtIndex:indexPath.row];
    //You may want to create a divider to scale the size by the way..
    //return CGSizeMake(image.size.width, image.size.height);
    
    return CGSizeMake(50, 50);
}
*/

#pragma mark - custom cells

-(void)customCells:(UICollectionViewCell *)cell_ forItemAtIndexPath:(NSIndexPath *)indexPath loadImageImmediately:(bool)loadImageImmediately
{
    UICollectionViewCellDetail *cell = (UICollectionViewCellDetail *)cell_;
    
    int row = (int)indexPath.row;
    
    PLT_MediaObject *data;
    if (self.sorted) {
        NSArray *array = self.arrSortListDate[indexPath.section];
        MediaObjectWrapper *w = array[row];
        data = [w get_inner];
    }
    else
    {
        auto it = files->GetItem(row);
        data = *it;
    }
    
    
    UIImage *image;
    NSURL *imageURL ;
    NSString *title;
    NSString *detail;
    
    
    title = [NSString stringWithUTF8String: data->m_Title];
    
   
    MediaType media_type;
    
    if (data->IsContainer())
    {
        hasNoPhotoItem = true;
        
        media_type =Folder;
        
        image = [UIImage imageNamed:@"folder"];
        
        auto childCount = ((PLT_MediaContainer*)data)->m_ChildrenCount;
        
        if (childCount == -1)
            detail = nil;
        else
            detail = [NSString stringWithFormat: NSLocalizedString(@"%d items",nl) , childCount ];
    }
    else
    {
        if (data->m_ObjectClass.type.Compare(szObjectClassTypeImagePhoto,true) == 0 )
        {
            
            media_type = Photo;
            
            image = [UIImage imageNamed:@"photoplaceholder"];
            
            if (data->m_Resources.GetItemCount() > 0) {
                auto beg = data->m_Resources.GetFirstItem();
                imageURL = [NSURL URLWithString:[NSString stringWithUTF8String: beg->m_Uri]];
            }
            
        
        }
        else if( data->m_ObjectClass.type.Compare(szObjectClassTypeVideo,true) == 0)
        {
            media_type = Video;
            
            image = [UIImage imageNamed:@"video"];
        }
        else if( data->m_ObjectClass.type.Compare(szObjectClassTypeAudioMusicTrack,true) == 0 || data->m_ObjectClass.type.Compare(szObjectClassTypeAudioBroadcast,true) == 0 )
        {
            media_type = Music;
            //music
            
            image = [UIImage imageNamed:@"music"];
            
            // get album art icon uri
            auto album_arts = data->m_ExtraInfo.album_arts;
            int count = album_arts.GetItemCount();
            if (count > 0) {
                auto beg = album_arts.GetFirstItem();
                PLT_AlbumArtInfo album_art = *beg;
                imageURL = [NSURL URLWithString: [NSString stringWithUTF8String:album_art.uri] ];
            }

            
            if (data->m_Resources.GetItemCount() > 0) {
                auto beg = data->m_Resources.GetFirstItem();
                auto duration = beg->m_Duration;
                if (duration != -1)
                    detail = secondDescription (duration );
                else
                {
                    if (beg->m_Size != -1)
                        detail = uintSizeDescription( beg->m_Size );
                }
            }
            
            
        }
        else
        {
            // a normal file
            media_type = Normal;
            
            image = [UIImage imageNamed:@"file"];
            
            if (data->m_Resources.GetItemCount() > 0) {
                auto beg = data->m_Resources.GetFirstItem();
                if ( beg->m_Size != -1)
                    detail = uintSizeDescription( beg->m_Size );
            }
            
        }
    }

    
//    NSAssert([cell isKindOfClass:[UICollectionViewCellSimple class]] ||
//             [cell isKindOfClass:[UICollectionViewCellBasic class]] ||
//             [cell isKindOfClass:[UICollectionViewCellDetail class]] , nil);

    
//    if (media_type == Photo)
    if (imageURL == nil) {
        [cell.cellImage setImage:image];
    }
    else
    {
        // Load the image from local cache,or download and compress it ,
        // then cache thus, in special namespace
        
        __weak UICollectionViewCellDetail *weakcell = cell;
        
        SDImageCache *imageCache = [photoCache sharedCache];
        
        [imageCache queryDiskCacheForKey: imageURL.absoluteString done:^(UIImage *cache_image, SDImageCacheType cacheType) {
            
            if (cache_image) {
                weakcell.cellImage.image = cache_image;
            }
            else
            {
                bool handled = false;
                
//                if (media_type == Photo)
                {
//                    if ( loadImageImmediately)
                    {
                        handled = true;
                        
                        weakcell.cellImage.image = image;
                        
                        fileCollectionViewController* weakself =self;
                        [[SDWebImageManager sharedManager] downloadImageWithURL:imageURL options: SDWebImageLowPriority /*SDWebImageRetryFailed*/ /*| SDWebImageHighPriority*/ progress:nil completed:^(UIImage *sd_image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                            
                            if (sd_image && finished && weakcell ) {
                                
                                __block UIImage* sd_image2 = sd_image;
                                dojobInBkgnd(^{
                                    sd_image2 = [sd_image imageByScalingAndCroppingForSize:weakself.layout2.itemSize ];
                                    
                                    //cache the compressed image.
                                    SDImageCache *imageCache = [photoCache sharedCache];
                                    [imageCache storeImage:sd_image2 forKey:imageURL.absoluteString];
                                }, ^{
                                    weakcell.cellImage.image = sd_image2;
                                    [weakcell.cellImage setNeedsDisplay];
                                });
                                
                                
                            }
                            
                            if (error) {
                                NSLog(@"download url: %@",imageURL);
                                NSLog(@"error,%@",error);
                            }
                            
                        }];
                        
                    }
                }
                
                if (!handled) {
//                    if (!loadImageImmediately)
//                        [weakcell.cellImage setImage:image];
//                    else
                        [weakcell.cellImage sd_setImageWithURL:imageURL placeholderImage:image];
//                    weakcell.cellImage.image = image;
                }
                
            }
        }];
        
    }
    
    
//    else if( media_type == Music )
//        [cell.cellImage sd_setImageWithURL:imageURL placeholderImage:image];
//    else
//        [cell.cellImage setImage:image];
    
    
//    if ( loadImageImmediately)
//    {
//    }else
//    {
        cell.cellTitle.text = title;
        cell.cellDetail.text = detail;
//    }
    
}

//-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    [self customCells:cell forItemAtIndexPath:indexPath loadImageImmediately:true];
//}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString * const reuseIdentifierSimple = @"simpleCell";
    static NSString * const reuseIdentifierBasic = @"basicCell";
    static NSString * const reuseIdentifierDetail = @"detailCell";
    NSString * reuseIdentifier;
    
    
    int row = (int)indexPath.row;

    PLT_MediaObject *data;
    if (self.sorted) {
        NSArray *array = self.arrSortListDate[indexPath.section];
        MediaObjectWrapper *w = array[row];
        data = [w get_inner];
    }
    else
    {
        auto it = files->GetItem(row);
        data = *it;
    }
    
    if (data->IsContainer())
    {
        hasNoPhotoItem = true;
        
        reuseIdentifier = reuseIdentifierDetail;
    }
    else
    {
        if (data->m_ObjectClass.type.Compare(szObjectClassTypeImagePhoto,true) == 0 )
        {
            reuseIdentifier = reuseIdentifierSimple;
        }
        else if( data->m_ObjectClass.type.Compare(szObjectClassTypeVideo,true) == 0)
        {
            reuseIdentifier = reuseIdentifierBasic;
        }
        else if( data->m_ObjectClass.type.Compare(szObjectClassTypeAudioMusicTrack,true) == 0 || data->m_ObjectClass.type.Compare(szObjectClassTypeAudioBroadcast,true) == 0 )
        {
            //music
            reuseIdentifier = reuseIdentifierDetail;
        }
        else
        {
            // a normal file
            reuseIdentifier = reuseIdentifierDetail;
        }
    }
    
    
    UICollectionViewCellDetail *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    [self customCells:cell forItemAtIndexPath:indexPath loadImageImmediately:true];
    

    return cell;
}


-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (self.sorted) {
        const int sectionHeight = 50;
        return CGSizeMake(self.collectionView.bounds.size.width, sectionHeight);
    }else {
        // folders tree do not need section headers
        return CGSizeMake(1, 1);
    }
}


#pragma mark - View For Header
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    int section = indexPath.section;
    
    UICollectionReusableViewPrivate* view =  [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"sourceSectionHeader" forIndexPath:indexPath];
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        if (self.sorted) {

            if (indexPath.section == self.arrSortListDate.count)
            {
                self.footView = view;
                
                if( self.collectionView.contentSize.height > CGRectGetHeight(self.collectionView.bounds) )
                {
                    view.headerTitle.text = [NSString stringWithFormat: NSLocalizedString(@"%d items",nil) , files->GetItemCount()];
                }else
                    view.headerTitle.text = nil;
                
                view.headerTitle.textAlignment = NSTextAlignmentCenter;
                view.headerTitle.textColor = [UIColor lightGrayColor];
                view.backgroundColor = [UIColor clearColor];
                view.headerButton.hidden = true;
            }
            else
            {
                NSArray *arr = self.arrSortListDate[section];
                MediaObjectWrapper *w = arr.firstObject;
                view.headerTitle.text = [w get_date_string];
                view.headerTitle.textAlignment = NSTextAlignmentLeft;
                view.headerTitle.textColor = [UILabel appearance].textColor;
                view.backgroundColor = [UILabel appearance].backgroundColor;
                
                view.headerActivityIndicator.hidden = true;
                view.headerButton.hidden = YES;
            }
            
            return view;
        }}
    
    

    view.backgroundColor = [UIColor clearColor];
    view.headerTitle.text = @"";
    
    return view;
}


#pragma mark <UICollectionViewDelegate>

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    int row = (int)indexPath.row;
    
    int index = 0;
    
    PLT_MediaObject *data;
    if (self.sorted) {
        NSArray *array = self.arrSortListDate[indexPath.section];
        MediaObjectWrapper *w = array[row];
        data = [w get_inner];
        
        
        int s = indexPath.section -1 ;
        for (; s >= 0; s--) {
            NSArray *a = self.arrSortListDate[s];
            index  += a.count;
        }
        
        index+= indexPath.row;
    }
    else
    {
        auto it = files->GetItem(row);
        index = row;
        data = *it;
    }
    
    
    
    if (data->IsContainer())
    {
        char t[256] = "cd ";
        strncpy(t + sizeof("cd ") - 1, data->m_ObjectID, data->m_ObjectID.GetLength());
        
        [DlnaControlPoint shared].pController->HandleCmd_cd(t);
        
        fileCollectionViewController *fc = [fileCollectionViewController instanceFromStoryboard];
        
        fc.navigationItem.title = [NSString stringWithUTF8String: data->m_Title];
        
        [self.navigationController pushViewController:fc animated:YES];
    }
    else
    {
        UICollectionViewCell *cell ;
        cell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:selected inSection:0]];
        cell = [self.collectionView cellForItemAtIndexPath:indexPath];
        selected = row;
        
        if( [DlnaControlPoint shared].pController->openIndex(selected) )
        {
            // show a popover of renderer list, for user to choose.
            PLT_DeviceDataReference device;
            [DlnaControlPoint shared].pController->GetCurMediaRenderer(device);
            if (device.IsNull())
            {
                CGRect f = cell.frame;
                f.origin.y = f.origin.y - self.collectionView.contentOffset.y;
                [renderTableViewController showRenderPopover:self.view frame:f];
            }
        }
        else
        {
            [[[UIAlertViewBlock alloc]initWithTitle:@"Can not play the file" message:@"The render do not support the resource type in the sink" cancelButtonTitle:nil cancelledBlock:nil okButtonTitles:@"OK" okBlock:nil] show];
        }
        
    }
    
}











-(void)isAllPhotos
{
    
}





@end

@implementation UICollectionViewCellSimple
@end
@implementation UICollectionViewCellBasic
@end



@interface MediaObjectWrapper ()
{
    PLT_MediaObject *inner;
}
@property (nonatomic,strong) NSDate *date;
@property (nonatomic,strong) NSString *dateTimeString,*dateString;
@end

@implementation MediaObjectWrapper
-(instancetype)initWith:(PLT_MediaObject*)inner_
{
    self = [super init];
    if (self) {
        self->inner = inner_;
    }
    return self;
}



-(void)loadDate
{
    
    NSString *r = [NSString stringWithUTF8String:inner->m_Date];
    if (r.length == 0)
    {
        self.dateString = NSLocalizedString(@"unknown date",nil);
        self.dateTimeString = NSLocalizedString(@"unknown date",nil);
    }
    else
    {
        
        static NSDateFormatter* fmtIn = nil;
        static NSDateFormatter *fmtOut = nil;
        static NSDateFormatter *fmtOut2 = nil;
        
        if (!fmtIn)
        {
            
            /**
             dc:date
             http://www.lyberty.com/meta/iso_8601.htm
             */
            
            fmtIn = [[NSDateFormatter alloc] init];
            fmtIn.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
            
            NSString *currLanguage =  getCurrLanguagesOfDevice();
            
            fmtOut = [[NSDateFormatter alloc] init];
            fmtOut.locale = [[NSLocale alloc] initWithLocaleIdentifier: currLanguage];
            fmtOut.dateStyle = NSDateFormatterMediumStyle;
            fmtOut.timeStyle = NSDateFormatterNoStyle;
            
            
            fmtOut2 = [[NSDateFormatter alloc] init];
            fmtOut2.locale = [[NSLocale alloc] initWithLocaleIdentifier: currLanguage];
            fmtOut2.dateStyle = NSDateFormatterMediumStyle;
            fmtOut2.timeStyle = NSDateFormatterMediumStyle;
            
            NSAssert(fmtOut2.locale, nil);
        }
        
        
        
        
        self.date = [fmtIn dateFromString:r];
        
        NSDateComponents *componentsToday = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate date]];
        
        NSInteger day = [componentsToday day];
        NSInteger month = [componentsToday month];
        NSInteger year = [componentsToday year];
        
        NSDateComponents *c = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:self.date];
        
        NSInteger day2 = [c day];
        NSInteger month2 = [c month];
        NSInteger year2 = [c year];
        
        
        bool added = false;
        if (year == year2 && month == month2) {
            if (day == day2) {
                self.dateTimeString  = self.dateString = NSLocalizedString( @"Today" ,nil );
                added = true;
            }
            else if(day - day2 == 1)
            {
                self.dateTimeString =self.dateString = NSLocalizedString( @"Yestoday" ,nil );
                added = true;
            }
            else if(day - day2 == 2)
            {
                self.dateTimeString =self.dateString = NSLocalizedString( @"The day before yesterday" ,nil );
                added = true;
            }
        }
        
        if (added == false)
        {
            self.dateString = [fmtOut stringFromDate:self.date];
            self.dateTimeString = [fmtOut stringFromDate:self.date];
            
            
            if(!self.dateString)
                self.dateString = @"";
            
            if (!self.dateTimeString)
                self.dateTimeString = @"";
        }
    }
    
}

-(NSString *)get_date_time_string
{
    if (!self.date)
        [self loadDate];
    
    return self.dateTimeString;
}

-(NSString*)get_date_string
{
    if (!self.date)
        [self loadDate];
    
    return self.dateString;
}

-(NSDate*)get_date
{
    if (!self.date)
        [self loadDate];
 
    return self.date;
}

-(PLT_MediaObject *)get_inner
{
    return inner;
}

@end


