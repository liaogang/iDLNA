//
//  constFunctions.m
//  demo
//
//  Created by liaogang on 15/9/17.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "constFunctions.h"
#import "constDefines.h"

NSString* uintSizeDescription(NPT_LargeSize size)
{
    return uintSizeDescription((long long)size);
}


NSString* uintSizeDescription(long long size)
{
    const double bytes_per_kb = 1024.0;
    const double bytes_per_mb = 1024.0 * bytes_per_kb;
    const double bytes_per_gb = 1024.0 * bytes_per_mb;
    
    
    NSString *unit;
    float value;
    if (size < bytes_per_kb) {
        value = size;
        unit = @"B";
    } else if (size < bytes_per_mb) {
        value = size / bytes_per_kb;
        unit = @"KB";
    } else if(size < bytes_per_gb){
        value = size / bytes_per_mb;
        unit = @"MB";
    }
    else
    {
        value = size / bytes_per_gb;
        unit = @"G";
    }
    
    
    return [NSString stringWithFormat:@"%.1f%@",value,unit];
}

NSString *secondDescription(NPT_UInt32 seconds)
{
    int minutes = seconds / 60;
    int hours = minutes / 60;
    
    int minute = ( seconds - hours * 60 )/60;
    int second = seconds - minutes * 60;
    
    if (hours == 0)
        return [NSString stringWithFormat:@"%02d:%02d",minute,second];
    
    return  [NSString stringWithFormat:@"%02d:%02d:%02d",hours,minute,second];
}

NSString *getCurrLanguagesOfDevice()
{
    NSString * code = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"][0];
    
    if ([code isEqualToString:@"zh-Hans" ])
    {
        return @"zh_CN";
    }
    else if([code isEqualToString:@"zh-Hant"] )
    {
        return @"zh_TW";
    }
    
    return code;
}


bool curDeviceIsPad()
{
    static bool bPad;
    static bool first = true;
    if (first) {
        first = false;
        bPad = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
    }
    
    return bPad;
}

NSString * UIKitLocalizedString(NSString *key)
{
    return [[NSBundle bundleWithIdentifier:@"com.apple.UIKit"] localizedStringForKey:key value:@"" table:nil];
}
