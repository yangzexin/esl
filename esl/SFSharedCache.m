//
//  SFSharedCacheStorage.m
//  Htinns
//
//  Created by yangzexin on 10/16/13.
//  Copyright (c) 2013 __MyCompany__. All rights reserved.
//

#import "SFSharedCache.h"
#import "SFFileCacheManager.h"
#import "SFCacheUtils.h"

@interface SFSharedCache ()

@property (nonatomic, strong) SFFileCacheManager *cacheManager;

@end

@implementation SFSharedCache

+ (instancetype)sharedFileCache
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (id)init
{
    self = [super init];
    
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    self.cacheManager = [SFFileCacheManager fileCacheManagerWithFolderPath:[cachesPath stringByAppendingPathComponent:@"SharedFileCache"]];
    
    return self;
}

- (void)setDelegate:(id<SFSharedCacheDelegate>)delegate
{
    _delegate = delegate;
    self.cacheManager.cacheDecorator = delegate;
    self.cacheManager.JSONOperation = delegate;
}

- (NSData *)cachedDataWithIdentifier:(NSString *)identifier filter:(id<SFCacheFilter>)filter
{
    return [self.cacheManager cachedDataWithIdentifier:identifier filter:filter];
}

- (void)storeCacheWithIdentifier:(NSString *)identifier data:(NSData *)data
{
    [self.cacheManager storeCacheWithIdentifier:identifier data:data];
}

- (void)clearCacheWithIdentifier:(NSString *)identifier
{
    [self.cacheManager clearCacheWithIdentifier:identifier];
}

- (BOOL)isCacheExistsWithIdentifier:(NSString *)identifier
{
    return [self.cacheManager isCacheExistsWithIdentifier:identifier];
}

- (NSString *)cachedStringWithIdentifier:(NSString *)identifier filter:(id<SFCacheFilter>)filter
{
    NSString *cachedString = nil;
    NSData *cacheData = [self cachedDataWithIdentifier:identifier filter:filter];
    if (cacheData != nil) {
        cachedString = [[NSString alloc] initWithData:cacheData encoding:NSUTF8StringEncoding];
    }
    return cachedString;
}

- (void)cachedStringWithIdentifier:(NSString *)identifier filter:(id<SFCacheFilter>)filter completion:(void(^)(NSString *cacheString))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *cacheString = [self cachedStringWithIdentifier:identifier filter:filter];
        if (completion != nil) {
            completion(cacheString);
        }
    });
}

- (void)storeCacheWithIdentifier:(NSString *)identifier string:(NSString *)string
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    [self storeCacheWithIdentifier:identifier data:data];
}

@end
