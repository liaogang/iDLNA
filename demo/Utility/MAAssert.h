/*
 MASSert.h
 */

#import <Foundation/Foundation.h>

#ifndef  _MASSert_h_
#define _MASSert_h_

#ifdef DEBUG
extern const char *__crashreporter_info__;
asm(".desc _crashreporter_info, 0x10");

#define MAAssert(expression, ...) \
do { \
if(!(expression)) { \
NSString *__MAAssert_temp_string = [NSString stringWithFormat: @"Assertion failure: %s in %s on line %s:%d. %@", #expression, __func__, __FILE__, __LINE__, [NSString stringWithFormat: @"" __VA_ARGS__]]; \
NSLog(@"%@", __MAAssert_temp_string); \
__crashreporter_info__ = [__MAAssert_temp_string UTF8String]; \
abort(); \
} \
} while(0)
#else
#define MAAssert(expression, ...)
#endif





#endif//_MASSert_h_





