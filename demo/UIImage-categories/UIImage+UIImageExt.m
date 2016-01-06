//
//  UIImage+UIImageExt.m
//  GenieiPhoneiPod
//
//  Created by pingxian.liang on 13-2-28.
//
//

#import "UIImage+UIImageExt.h"

@implementation UIImage (UIImageExt)

- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize
{
    UIImage *sourceImage = self;
    UIImage *newImage = nil;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    UIGraphicsBeginImageContext(targetSize); // this will crop
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = targetWidth;
    thumbnailRect.size.height = targetHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil)
        NSLog(@"could not scale image");
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}
@end


