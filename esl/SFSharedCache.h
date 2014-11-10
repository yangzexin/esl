//
//  SFSharedCacheStorage.h
//  
//
//  Created by yangzexin on 10/16/13.
//  Copyright (c) 2013 __MyCompany__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFFileCache.h"

@protocol SFSharedCacheDelegate <SFCacheDecorator, SFJSONOperation>

@end

@interface SFSharedCache : NSObject <SFCacheManager>

@property (nonatomic, assign) id<SFSharedCacheDelegate> delegate;

+ (instancetype)sharedFileCache;

- (NSString *)cachedStringWithIdentifier:(NSString *)identifier filter:(id<SFCacheFilter>)filter;
- (void)cachedStringWithIdentifier:(NSString *)identifier filter:(id<SFCacheFilter>)filter completion:(void(^)(NSString *cacheString))completion;

- (void)storeCacheWithIdentifier:(NSString *)identifier string:(NSString *)string;

@end