//
//  SFCacheUtils.m
//  
//
//  Created by yangzexin on 10/16/13.
//  Copyright (c) 2013 __MyCompany__. All rights reserved.
//

#import "SFCacheUtils.h"

@implementation SFCacheUtils

+ (NSString *)applicationIdentifier
{
    return [NSString stringWithFormat:@"%p", [UIApplication sharedApplication]];
}

@end
