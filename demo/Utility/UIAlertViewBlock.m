//
//  UIAlertViewBlock.m
//  GenieiPhoneiPod
//
//  Created by liaogang on 3/25/14.
//
//

#import "UIAlertViewBlock.h"

#ifndef __has_feature
#define __has_feature(x) 0
#endif

#if !__has_feature(objc_arc)
#error UIAlertViewBlock is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif


@interface UIAlertViewBlock()
@property (nonatomic,copy) UIAlertViewCompletedBlock m_BlockCancelled , m_BlockOK;
@end

@implementation UIAlertViewBlock

-(id)initWithTitle:(NSString *)title message:(NSString *)message
 cancelButtonTitle:(NSString *)cancelButtonTitle cancelledBlock:(UIAlertViewCompletedBlock)cancelledBlock
    okButtonTitles:(NSString *)okButtonTitles  okBlock:(UIAlertViewCompletedBlock)okBlock
{
#ifdef DEBUG
    NSAssert(!cancelButtonTitle ? !cancelledBlock : YES , @"no \"cancel\" button , should not have a  callback for it.");
    
    
    NSAssert(!okButtonTitles ? !okBlock : YES , @"no \"ok\" button ,should not have a  ok callback for it.");
#endif
    
    self=[super initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:okButtonTitles, nil];
    if(self){
        _m_BlockCancelled=cancelledBlock;
        _m_BlockOK = okBlock;
    }
    
    
    return self;
}


#pragma mark - UIAlertViewDelegate


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == self.cancelButtonIndex)
    {
        if(_m_BlockCancelled)
            _m_BlockCancelled(self);
    }
    else
    {
        if(_m_BlockOK)
            _m_BlockOK(self);
    }
}
@end
