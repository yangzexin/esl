//
//  SFCacheFilterFactory.m
//  SimpleFramework
//
//  Created by yangzexin on 10/31/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "SFBuildInCacheFilters.h"
#import "SFCacheUtils.h"
#import "NSDate+SFAddition.h"

@interface SFBlockedCacheFilter ()

@property (nonatomic, copy) BOOL(^cacheValidator)(id<SFCache> cache);

@end

@implementation SFBlockedCacheFilter

- (BOOL)isCacheValid:(id<SFCache>)cache
{
    BOOL valid = NO;
    if (self.cacheValidator != nil) {
        valid = self.cacheValidator(cache);
    }
    return valid;
}

+ (instancetype)blockedCacheFilterWithValidator:(BOOL(^)(id<SFCache>))cacheValidator
{
    SFBlockedCacheFilter *filter = [SFBlockedCacheFilter new];
    filter.cacheValidator = cacheValidator;
    return filter;
}

@end

@implementation SFBuildInCacheFilters

+ (id<SFCacheFilter>)foreverCacheFilter
{
    return [SFBlockedCacheFilter blockedCacheFilterWithValidator:^BOOL(id<SFCache> cache) {
        return YES;
    }];
}

+ (id<SFCacheFilter>)memoryCacheFilter
{
    return [SFBlockedCacheFilter blockedCacheFilterWithValidator:^BOOL(id<SFCache> cache) {
        return [[cache applicationIdentifier] isEqualToString:[SFCacheUtils applicationIdentifier]];
    }];
}

+ (id<SFCacheFilter>)dayCacheFilterWithNumberOfDays:(NSInteger)numberOfDays
{
    return [SFBlockedCacheFilter blockedCacheFilterWithValidator:^BOOL(id<SFCache> cache) {
        NSInteger days = [[cache createDate] numberOfDayIntervalsWithDate:[NSDate new] usingZeroHourDate:YES];
        return days < numberOfDays;
    }];
}

+ (id<SFCacheFilter>)hourCacheFilterWithNumberOfHours:(float)numberOfHours
{
    return [SFBlockedCacheFilter blockedCacheFilterWithValidator:^BOOL(id<SFCache> cache) {
        NSDate *nowDate = [NSDate new];
        NSTimeInterval timeInterval = [nowDate timeIntervalSinceDate:[cache createDate]];
        float hours = timeInterval / 3600;
        return hours > 0 && hours <= numberOfHours;
    }];
}

+ (id<SFCacheFilter>)minuteCacheFilterWithNumberOfMinutes:(float)numberOfMinutes
{
    return [self hourCacheFilterWithNumberOfHours:numberOfMinutes / 60.0f];
}

+ (id<SFCacheFilter>)secondCacheFilterWithNumberOfSeconds:(float)numberOfSeconds
{
    return [self minuteCacheFilterWithNumberOfMinutes:numberOfSeconds / 60.0f];
}

@end
