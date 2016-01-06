//
//  constFunctions.m
//  demo
//
//  Created by liaogang on 15/9/17.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Platinum/Platinum.h>


NSString* uintSizeDescription(NPT_LargeSize size);
NSString *secondDescription(NPT_UInt32 seconds);

NSString* uintSizeDescription(long long size);

/**return the current languages iso code.
 * but zh_CN for simple chinese
 *     zh_TW for traditional
 */
NSString *getCurrLanguagesOfDevice();

/**
 @return true if is UserInterface Idiom is Pad
 */
bool curDeviceIsPad();


NSString * UIKitLocalizedString(NSString *key);


