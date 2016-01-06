//
//  UITableViewCellMy.h
//  demo
//
//  Created by liaogang on 15/9/17.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "UITableViewCellMy.h"

@implementation UITableViewCellSource
@end



@implementation UICollectionViewCellDetail
-(void)setHighlighted:(BOOL)highlighted
{
    [self.contentView sendSubviewToBack: self.cellBackground];
    
    if (highlighted)
        self.cellBackground.hidden = false;
    else
        self.cellBackground.hidden = true;
}
@end

@implementation UIHeaderViewController
@end


@implementation UICollectionReusableViewPrivate

@end

