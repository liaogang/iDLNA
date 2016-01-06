//
//  fileBrowserTableViewController.m
//  demo
//
//  Created by liaogang on 15/5/20.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "fileBrowserTableViewController.h"
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
#import "constFunctions.h"


@interface CellData : NSObject
+(instancetype)cellDataWithImageURL:(NSURL*)imageURL placeholder:(NSString*)placeholder title:(NSString *)title detail:(NSString*)detail;
@property (nonatomic,strong) NSURL *imageURL;
@property (nonatomic,strong) NSString *title;
@property (nonatomic,strong) NSString *detail;
@property (nonatomic,strong) NSString *placeholder;
@end





NSString* uintSizeDescription(NPT_LargeSize size);
NSString *secondDescription(NPT_UInt32 seconds);

@interface UITableViewCellMusic : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *musicImageView;
@property (weak, nonatomic) IBOutlet UILabel *musicTitle;
@property (weak, nonatomic) IBOutlet UILabel *musicDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *musicSubTitle;
@end

@interface fileBrowserTableViewController ()
{
    PLT_MediaObjectListReference files;
    int selected;
    NSMutableDictionary *ThumbStore;
    dispatch_queue_t DownloadThumbnailQueue;
}
+ (UIImage *)imageResize :(UIImage*)img andResizeTo:(CGSize)newSize;
@property (nonatomic) int rowHeight;


/// data for photo browser
@property (nonatomic,strong) NSMutableArray *urlPhotos;

@end

@implementation fileBrowserTableViewController

static NSString *const key_send_to_renderer_synchronously_when_browse_photo_suppressed = @"send_to_renderer_synchronously_when_browse_photo_suppressed";
static NSString *const key_send_to_renderer_synchronously_when_browse_photo = @"send_to_renderer_synchronously_when_browse_photo";

-(void)willMoveToParentViewController:(UIViewController *)parent
{
    // View is disappearing because it was popped from the stack
    //退回上级时,调用cdup,再刷新数据调用ls.
    if (parent == nil)
    {
        [DlnaControlPoint shared].pController->HandleCmd_cdup();
        [[SDWebImageManager sharedManager] cancelAll];
    }
}

-(void)dealloc
{
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    ThumbStore = [[NSMutableDictionary alloc] initWithCapacity:0];
    DownloadThumbnailQueue = dispatch_queue_create("Get Photo Thumbnail", NULL);
}

-(void)popRender:(id)sender
{
    [renderTableViewController showRenderPopover:sender frame:CGRectNull];
}


- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.urlPhotos = [NSMutableArray array];
    
    selected = -1;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(popRender:)];
    
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];

    [self.refreshControl beginRefreshing];
    
    //[self performSelector:@selector(refresh) withObject:nil afterDelay:0.3];
    
    NSAssert( [UIImage imageNamed:@"folder"] , nil);
    NSAssert( [UIImage imageNamed:@"null"] , nil);
    NSAssert( [UIImage imageNamed:@"video"] , nil);
    NSAssert( [UIImage imageNamed:@"music"] , nil);
    
    //hi.tan: 让table view 的分割线占据整个屏幕
    [self.tableView setSeparatorInset:UIEdgeInsetsMake(0,0,0,0)];
    //hi.tan： 对没有数据的cell的分割线将其隐藏不显示
    [self setExtraCellLineHidden:self.tableView];
    
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // must refresh the data with ls().
    if (!self.isMovingToParentViewController) {
        // refresh data with ls() may block the thread ,
        // if dms do not response message.
        [self performSelector:@selector(refresh) withObject:nil afterDelay:0];
    }
}


-(void)refresh
{
    __weak fileBrowserTableViewController* weakSelf = self;
    
    dojobInBkgnd(^{
        fileBrowserTableViewController* strongSelf = weakSelf;
        strongSelf->files = [DlnaControlPoint shared].pController->ls();
    }, ^{
        [weakSelf.tableView reloadData];
        [weakSelf.refreshControl endRefreshing];
    });
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    printf("didReceiveMemoryWarning\n");
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return files.IsNull()?0:files->GetItemCount();
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    int row = (int)indexPath.row;
    
    PLT_MediaObject *data;
    auto it = files->GetItem(row);
    data= *it;
    
   
    if (data->IsContainer())
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rdFileBrowserCellFolder" forIndexPath:indexPath];
        cell.textLabel.text = [NSString stringWithUTF8String: data->m_Title];
        
        auto childCount = ((PLT_MediaContainer*)data)->m_ChildrenCount;
        if (childCount == -1)
            cell.detailTextLabel.text = nil;
        else
            cell.detailTextLabel.text = [NSString stringWithFormat: NSLocalizedString(@"%d items",nl) , childCount ];
        
        self.rowHeight = cell.contentView.bounds.size.height;
        
        return cell;
    }
    else
    {
        if (data->m_Resources.GetItemCount() > 0) {
            auto beg = data->m_Resources.GetFirstItem();
            
            enum{
                type_normal,
                type_photo,
                type_video,
                type_music,
            } mediaType = type_normal;
            
            
            if (data->m_ObjectClass.type.Compare(szObjectClassTypeImagePhoto,true) == 0 )
            {
                mediaType = type_photo;
            }
            else if( data->m_ObjectClass.type.Compare(szObjectClassTypeVideo,true) == 0)
            {
                mediaType = type_video;
            }
            else if( data->m_ObjectClass.type.Compare(szObjectClassTypeAudioMusicTrack,true) == 0 ||
                    data->m_ObjectClass.type.Compare(szObjectClassTypeAudioBroadcast,true) == 0 )
            {
                mediaType = type_music;
            }
            else
            {
                // Tread `rmvb` as video.
                for (int i = 0; i < data->m_Resources.GetItemCount(); i++) {
                    PLT_MediaItemResource *r = data->m_Resources.GetItem(i);
                    NPT_String contentType = r->m_ProtocolInfo.GetContentType();
                    if (contentType.Compare("application/vnd.rn-realmedia-vbr",true) == 0) {
                        mediaType = type_video;
                        break;
                    }
                }
            }
            


            
            
            if (mediaType == type_video) {
                
                
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rdFileBrowserCell" forIndexPath:indexPath];
                self.rowHeight = cell.contentView.bounds.size.height;
                cell.textLabel.text = [NSString stringWithUTF8String: data->m_Title];
                cell.imageView.image = nil;
                cell.detailTextLabel.text = nil;

                
                //video
                cell.imageView.image = [UIImage imageNamed:@"null"];
                
                cell.accessoryType = (row == selected ?UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
                NSURL *sourceMovieURL = [NSURL URLWithString:[NSString stringWithUTF8String: beg->m_Uri]];
                
                    if (beg->m_Size != -1)
                        cell.detailTextLabel.text = uintSizeDescription( beg->m_Size );
                    
                    dispatch_async(DownloadThumbnailQueue, ^{
                        UIImage *img;
                        if ([ThumbStore objectForKey:[NSNumber numberWithInt:row]]) {
                            img = [ThumbStore objectForKey:[NSNumber numberWithInt:row]];
                        } else {
                
                            AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:sourceMovieURL options:nil];
                            AVAssetImageGenerator* generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:sourceAsset];
                            CGImageRef frameRef = [generator copyCGImageAtTime:CMTimeMake(3,1) actualTime:nil error:nil];
                            UIImage* tmpImg = [[UIImage alloc] initWithCGImage:frameRef];
                            img = [fileBrowserTableViewController imageResize:tmpImg andResizeTo:CGSizeMake(40, 40)];
                            [ThumbStore setObject:img forKey:[NSNumber numberWithInt:row]];
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            // create a copy of the cell to avoid keeping a strong pointer to "cell" since that one may have been reused by the time the block is ready to update it.
                            UITableViewCell *cellToUpdate = [self.tableView cellForRowAtIndexPath:indexPath];
                            if (cellToUpdate != nil) {
                                [cellToUpdate.imageView setImage:img];
                                [cellToUpdate setNeedsLayout];
                            }
                        });
                    });
                    

                
                
                return cell;
                
            }
            else if(mediaType == type_music)
            {
                // music
                auto duration = beg->m_Duration;
                
                if( data->m_ObjectClass.type.Compare("object.item.audioItem.audioBroadcast",true) == 0)
                {
                    // is a normal file.
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rdFileBrowserCell" forIndexPath:indexPath];
                    self.rowHeight = cell.contentView.bounds.size.height;
                    cell.textLabel.text = [NSString stringWithUTF8String: data->m_Title];
                    if (beg->m_Size != -1)
                        cell.detailTextLabel.text = uintSizeDescription( beg->m_Size );
                    cell.accessoryType = (row == selected ?UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
                    cell.imageView.image = [UIImage imageNamed: @"audioBroadcast2" ];
                    
                    
                    return cell;
                }
                else
                {
                    NSString * artist;
                    NSString * album ;
                    NSString* album_art_uri;
                    
                    // get artist
                    auto artists = data->m_People.artists;
                    if (artists.GetItemCount() > 0) {
                        auto beg = artists.GetFirstItem();
                        PLT_PersonRole role = *beg;
                        artist = [NSString stringWithUTF8String: role.name];
                        
                    }
                    
                    // get album info.
                    album = [NSString stringWithUTF8String:data->m_Affiliation.album];
                    
                    
                    // get album art icon uri
                    auto album_arts = data->m_ExtraInfo.album_arts;
                    int count = album_arts.GetItemCount();
                    if (count > 0) {
                        auto beg = album_arts.GetFirstItem();
                        PLT_AlbumArtInfo album_art = *beg;
                        album_art_uri = [NSString stringWithUTF8String:album_art.uri];
                    }
                    
                    
                    
                    
                    
                    if (duration == -1 && artist.length == 0  && album.length == 0 ) {
                        
                        // is a normal file.
                        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rdFileBrowserCell" forIndexPath:indexPath];
                        self.rowHeight = cell.contentView.bounds.size.height;
                        cell.textLabel.text = [NSString stringWithUTF8String: data->m_Title];
                        if (beg->m_Size != -1)
                            cell.detailTextLabel.text = uintSizeDescription( beg->m_Size );
                        cell.accessoryType = (row == selected ?UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
                        cell.imageView.image = [UIImage imageNamed: @"default_thumbimg_music.png" ];
                        
                        CGSize itemSize = CGSizeMake(64, 64);
                        UIGraphicsBeginImageContext(itemSize);
                        CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
                        [cell.imageView.image drawInRect:imageRect];
                        cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
                        UIGraphicsEndImageContext();
                        
                        return cell;
                    }
                    else
                    {
                        UITableViewCellMusic * cell = [tableView dequeueReusableCellWithIdentifier:@"rdFileBrowserCellMusic" forIndexPath:indexPath];;
                        self.rowHeight = cell.contentView.bounds.size.height;
                        cell.musicTitle.text = [NSString stringWithUTF8String: data->m_Title];
                        cell.musicImageView.image = nil;
                        cell.musicDetailLabel.text = nil;
                        cell.accessoryType = (row == selected ?UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
                        
                        
                        if (artist == nil)
                            artist = @"";
                        if (album == nil)
                            album = @"";
                        
                        
                         if (duration != -1)
                             cell.musicDetailLabel.text = secondDescription (duration );
                         else
                         {
                             if (beg->m_Size != -1)
                                 cell.musicDetailLabel.text = uintSizeDescription( beg->m_Size );
                         }
                        
                        cell.musicSubTitle.text = [NSString stringWithFormat:@"%@ %@",artist,album];
                        
                        [cell.musicImageView sd_setImageWithURL:[NSURL URLWithString: album_art_uri] placeholderImage:[UIImage imageNamed:@"default_thumbimg_music.png"]];
                        
                        CGSize itemSize = CGSizeMake(64, 64);
                        UIGraphicsBeginImageContext(itemSize);
                        CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
                        [cell.musicImageView.image drawInRect:imageRect];
                        cell.musicImageView.image = UIGraphicsGetImageFromCurrentImageContext();
                        UIGraphicsEndImageContext();
                        
                        return cell;
                    }
                    
                }
                
                
            }
            else if(mediaType == type_photo)
            {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rdFileBrowserCellPhoto" forIndexPath:indexPath];
                self.rowHeight = cell.contentView.bounds.size.height;
                cell.textLabel.text = [NSString stringWithUTF8String: data->m_Title];
                cell.imageView.image = nil;
                cell.detailTextLabel.text = nil;
                
                if (beg->m_Size != -1)
                    cell.detailTextLabel.text = uintSizeDescription( beg->m_Size );
                
                cell.accessoryType = (row == selected ?UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
                
                // Old system or device? Do not load large images ( 300 KB).
                float systemVersion = [UIDevice currentDevice].systemVersion.floatValue;
                if ( systemVersion <= 7.0 && beg->m_Size > 300 * 1024.0 )
                    cell.imageView.image = [UIImage imageNamed:@"null"];
                else
                {
                    if ( beg->m_Size < 800 * 1024.0 )
                    {
                        [cell.imageView sd_setImageWithURL:[NSURL URLWithString: [NSString stringWithUTF8String: beg->m_Uri ]] placeholderImage:[UIImage imageNamed:@"null"]];
                    }
                    else if (beg->m_Size < 1000 * 1024.0)
                    {
                        __weak UITableViewCell *weakcell = cell;
                        weakcell.imageView.image = [UIImage imageNamed:@"null"];
                        [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString: [NSString stringWithUTF8String: beg->m_Uri ]] options:SDWebImageDownloaderUseNSURLCache progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                            
                            if (image && finished ) {
                                image = [image imageByScalingAndCroppingForSize:CGSizeMake(32, 32)];
                                
//                                image = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:weakcell.imageView.bounds.size interpolationQuality:kCGInterpolationLow];
                                weakcell.imageView.image = image;
                                [weakcell.imageView setNeedsDisplay];
                            }
                            
                        }];
                        
                    }
                    else
                    {
                        cell.imageView.image = [UIImage imageNamed:@"null"];
                    }
                }
                
                return cell;
                
            }
            else
            {
                // is a normal file.
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rdFileBrowserCell" forIndexPath:indexPath];
                self.rowHeight = cell.contentView.bounds.size.height;
                cell.textLabel.text = [NSString stringWithUTF8String: data->m_Title];
                
                if (beg->m_Size != -1)
                    cell.detailTextLabel.text = uintSizeDescription( beg->m_Size );
                cell.accessoryType = (row == selected ?UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
                
                return cell;
            }
            
        }
        else
        {
            printf("!  data->m_Resources.GetItemCount() > 0 \n");
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rdFileBrowserCell" forIndexPath:indexPath];
            self.rowHeight = cell.contentView.bounds.size.height;
            return cell;
        }

    }

    
    NSAssert(false, nil);
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if( files.IsNull() == FALSE && self.rowHeight > 0)
    {
        int rowsPerScreen = [UIScreen mainScreen].bounds.size.height/ self.rowHeight;
        
        int count = files->GetItemCount();
        
        if (count > rowsPerScreen * 2.5 )
        {
            return tableView.sectionFooterHeight;
        }
    }
    
    
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if( files.IsNull() == FALSE && self.rowHeight > 0)
    {
        int rowsPerScreen = [UIScreen mainScreen].bounds.size.height/ self.rowHeight;
        
        int count = files->GetItemCount();
        
        if (count > rowsPerScreen * 2.5 )
        {
            UILabel *label = [[UILabel alloc]init];
            
            int folderCount = 0;
            int normalCount = 0;
            
            PLT_MediaObject *data;
            for (int i = 0; i < count; i++) {
                auto it = files->GetItem(i);
                data= *it;
                
                if (data->IsContainer())
                    folderCount++;
                else
                    normalCount++;
            }
           
            NSAssert(folderCount + normalCount == count, nil);
            
            if(normalCount == 0)
                label.text = [NSString stringWithFormat:NSLocalizedString(@"%d Folders", nil),folderCount];
            else if(folderCount == 0)
                label.text = [NSString stringWithFormat:NSLocalizedString(@"%d Items", nil),normalCount];
            else
                label.text = [NSString stringWithFormat:NSLocalizedString(@"%d Items,%d Folders", nil),normalCount,folderCount];
            
            
            label.textAlignment = NSTextAlignmentCenter;
            
            return label;
        }
    }
    
    
    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = (int)indexPath.row;
    
    PLT_MediaObject *data;
    auto it = files->GetItem(row);
    data= *it;
    
    if (data->IsContainer())
    {
        char t[256] = "cd ";
        strncpy(t + sizeof("cd ") - 1, data->m_ObjectID, data->m_ObjectID.GetLength());
        
        [DlnaControlPoint shared].pController->HandleCmd_cd(t);
        
        __block PLT_MediaObjectListReference tmpfiles;
        dojobInBkgnd(^{
            tmpfiles = [DlnaControlPoint shared].pController->ls();
        }, ^{
            
           
            if (!tmpfiles.IsNull()) {
                int count = tmpfiles->GetItemCount();
                
                NSMutableArray *cellDatas = [NSMutableArray arrayWithCapacity:count];
            
                for ( int i =0; i< count ; i++) {
                    auto it2 = tmpfiles->GetItem( i );
                    PLT_MediaObject *data2 = *it2;
                    

                    if (data2->m_ObjectClass.type.Compare("object.item.imageItem.photo",true) == 0 )
                    {
                        if (data2->m_Resources.GetItemCount() > 0) {
                            auto beg = data2->m_Resources.GetFirstItem();
                            if (beg) {
                                CellData *cellData = [CellData cellDataWithImageURL:[NSURL URLWithString:[NSString stringWithUTF8String:beg->m_Uri]] placeholder:@"null" title:nil detail:nil];
                                [cellDatas addObject:cellData];
                                
                                [self.urlPhotos addObject: [NSURL URLWithString:[NSString stringWithUTF8String:beg->m_Uri]]];
                            }
                        }
                    }
                    else if( data2->m_ObjectClass.type.Compare("object.item.audioItem.musicTrack",true) == 0 )
                    {
                        if (data2->m_Resources.GetItemCount() > 0) {
                            auto beg = data2->m_Resources.GetFirstItem();
                            if (beg) {
                                
                                CellData *cellData = [CellData cellDataWithImageURL:[NSURL URLWithString:[NSString stringWithUTF8String:beg->m_Uri]] placeholder:@"music" title:[NSString stringWithUTF8String:data2->m_Title] detail:nil];
                                [cellDatas addObject:cellData];
                                
                                [self.urlPhotos addObject: [NSURL URLWithString:[NSString stringWithUTF8String:beg->m_Uri]]];
                            }
                        }
                    }
                    else if( data2->m_ObjectClass.type.Compare("object.item.videoItem",true) == 0 )
                    {
                        if (data2->m_Resources.GetItemCount() > 0) {
                            auto beg = data2->m_Resources.GetFirstItem();
                            if (beg) {
                                
                                CellData *cellData = [CellData cellDataWithImageURL:[NSURL URLWithString:[NSString stringWithUTF8String:beg->m_Uri]] placeholder:@"video" title:[NSString stringWithUTF8String:data2->m_Title] detail:nil];
                                [cellDatas addObject:cellData];
                                
                                [self.urlPhotos addObject: [NSURL URLWithString:[NSString stringWithUTF8String:beg->m_Uri]]];
                            }
                        }
                    }
                
                

                    
            }
             
                
//
                /*
                 else
                 {
                 fileBrowserTableViewController *fb = [sb instantiateViewControllerWithIdentifier:@"IDFileBrowserTableViewController"];
                 
                 fb.title = [NSString stringWithUTF8String: data->m_Title];
                 
                 [self.navigationController pushViewController:fb animated:YES];
                 }*/
                
            }
        });
        
    }
    else
    {
        UITableViewCell *cell ;
        
        cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selected inSection:0]];
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        
        cell = [tableView cellForRowAtIndexPath:indexPath];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        selected = row;
        
        if( [DlnaControlPoint shared].pController->openIndex(selected) )
        {
            // show a popover of renderer list, for user to choose.
            PLT_DeviceDataReference device;
            [DlnaControlPoint shared].pController->GetCurMediaRenderer(device);
            if (device.IsNull())
                [renderTableViewController showRenderPopover:self.view frame:cell.frame];
            
        }
        else
        {
            [[[UIAlertViewBlock alloc]initWithTitle:@"Can not play the file" message:@"The render do not support the resource type in the sink" cancelButtonTitle:nil cancelledBlock:nil okButtonTitles:@"OK" okBlock:nil] show];
        }
        
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


+ (UIImage *)imageResize :(UIImage*)img andResizeTo:(CGSize)newSize
{
    CGFloat scale = [[UIScreen mainScreen]scale];
    /*You can remove the below comment if you dont want to scale the image in retina   device .Dont forget to comment UIGraphicsBeginImageContextWithOptions*/
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, scale);
    [img drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end





@implementation UITableViewCellMusic

@end

enum cell_type
{
    type_simple,
    type_basic,
    type_detail,
};


@interface CellData ()
@property (nonatomic) enum cell_type type;
@end


@implementation CellData

+(instancetype)cellDataWithImageURL:(NSURL*)imageURL placeholder:(NSString*)placeholder title:(NSString *)title detail:(NSString*)detail
{
    CellData *d = [[CellData alloc]init];
    d.imageURL = imageURL;
    d.title = title;
    d.detail = detail;
    d.placeholder = placeholder;
    
    d.type = title ? (detail ? type_detail : type_basic) : type_simple ;
    
    return d;
}

@end
