//
//  SFCacheFilterFactory.h
//  SimpleFramework
//
//  Created by yangzexin on 10/31/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFCacheManager.h"

@interface SFBlockedCacheFilter : NSObject <SFCacheFilter>

+ (instancetype)blockedCacheFilterWithValidator:(BOOL(^)(id<SFCache>))cacheValidator;

@end

@interface SFBuildInCacheFilters : NSObject

+ (id<SFCacheFilter>)foreverCacheFilter;
+ (id<SFCacheFilter>)memoryCacheFilter;
+ (id<SFCacheFilter>)dayCacheFilterWithNumberOfDays:(NSInteger)numberOfDays;
+ (id<SFCacheFilter>)hourCacheFilterWithNumberOfHours:(float)numberOfHours;
+ (id<SFCacheFilter>)minuteCacheFilterWithNumberOfMinutes:(float)numberOfMinutes;
+ (id<SFCacheFilter>)secondCacheFilterWithNumberOfSeconds:(float)numberOfSeconds;

@end
