//
//  UIAlertViewBlock.h
//  GenieiPhoneiPod
//
//  Created by liaogang on 3/25/14.
//
//

#import <UIKit/UIKit.h>

@class UIAlertViewBlock;

typedef void(^UIAlertViewCompletedBlock)(UIAlertViewBlock *);

@interface UIAlertViewBlock : UIAlertView <UIAlertViewDelegate>

-(id)initWithTitle:(NSString *)title message:(NSString *)message
 cancelButtonTitle:(NSString *)cancelButtonTitle cancelledBlock:(UIAlertViewCompletedBlock)cancelledBlock
    okButtonTitles:(NSString *)okButtonTitles  okBlock:(UIAlertViewCompletedBlock)okBlock;

@end
