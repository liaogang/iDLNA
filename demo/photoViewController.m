//
//  photoViewController.m
//  demo
//
//  Created by liaogang on 15/6/26.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "photoViewController.h"
#import "UIImageView+WebCache.h"

@interface photoViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *photo;
@end

@implementation photoViewController

-(void)showPhoto:(NSURL*)url
{
    NSLog(@"show photo: %@",url);
    
    [self.photo sd_setImageWithURL:url placeholderImage:nil options:SDWebImageDelayPlaceholder];
}

@end
