//
//  UITableViewCellMy.h
//  demo
//
//  Created by liaogang on 15/9/17.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableViewCellSource : UITableViewCell
@property (nonatomic,strong) IBOutlet UIImageView *cellImage;
@property (nonatomic,strong) IBOutlet UILabel *cellText;
@property (nonatomic,strong) IBOutlet UILabel *cellDetailText;
@end

@interface UICollectionViewCellDetail : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *cellImage;
@property (weak, nonatomic) IBOutlet UILabel *cellTitle;
@property (weak, nonatomic) IBOutlet UILabel *cellDetail;
@property (weak, nonatomic) IBOutlet UIView *cellBackground;

@end

@interface UICollectionReusableViewPrivate : UICollectionReusableView
@property (weak, nonatomic) IBOutlet UILabel *headerTitle;

// Set hidden/show to stopAnimating/startAnimating
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *headerActivityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *headerButton;
@end


@interface UIHeaderViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *headerTitle;
@property (weak, nonatomic) IBOutlet UIButton *headerAddButtton;
@end



