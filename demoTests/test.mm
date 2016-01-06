//
//  test.h
//  demo
//
//  Created by liaogang on 15/9/21.
//  Copyright (c) 2015年 com.cs. All rights reserved.
//

#import "test.h"

#import "constDefines.h"
#import "constFunctions.h"

void testMain()
{
    printf("runnig some tests...\n");

    
    
    long long size;
    size = 1023ll;
    NSLog(@" %lld , %@ ",size,uintSizeDescription(size));
    size = 1024ll;
    NSLog(@" %lld , %@ ",size,uintSizeDescription(size));
    size = 1024ll*1024l;
    NSLog(@" %lld , %@ ",size,uintSizeDescription(size));
    size = 1024ll*size;
    NSLog(@" %lld , %@ ",size,uintSizeDescription(size));
    size = 1023ll*size;
    NSLog(@" %lld , %@ ",size,uintSizeDescription(size));
    size = 1023ll*size;
    NSLog(@" %lld , %@ ",size,uintSizeDescription(size));
    
    
    
    printf("size of long long: %lu, long: %lu , int: %lu \n\n",sizeof(long long),sizeof(long),sizeof(int));

    
    unsigned long a = -1;
    
    
    printf("a: %lu, size: %lu\n",a,sizeof(a));
    
    NSLog(@" %lld , %@ ",size,uintSizeDescription((long long)a));
    
    unsigned long long b = -1;
    
    b /= 10;
    
    NSLog(@" %lld , %@ ",size,uintSizeDescription((long long)b));
    
    
    
    
    int i = 20;
    while (i-->0) {
        printf("NSFoundationVersionNumber: %f\n", floor( NSFoundationVersionNumber) );
        printf("system version: %f\n" ,[[UIDevice currentDevice]systemVersion].floatValue );
    }
    
    
    
        
   
    
    {
    static NSDateFormatter* fmt = nil;
    if (!fmt) {
        fmt = [[NSDateFormatter alloc] init];
        fmt.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        fmt.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    }
    
        NSDate *date = [fmt dateFromString:@"2014-12-27T04:30:09Z"];
        NSString *s  = [fmt stringFromDate:date];
        NSString *aa = [fmt stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
        NSLog(@"%@\n%@",s,aa);
    }
    
    
    
    {

    
        NSString *a = UIKitLocalizedString(@"Yestoday");
        NSLog(@"%@",a);
        
        a = UIKitLocalizedString(@"Search");
        NSLog(@"%@",a);
        
        a = UIKitLocalizedString(@"Today");
        NSLog(@"%@",a);
        
        
        a = UIKitLocalizedString(@"The day before yesterday");
        NSLog(@"%@",a);
    }
    
    printf("tests end...\n\n\n\n\n\n\n");
}

