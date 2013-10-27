//
//  ESSoundManager.m
//  esl
//
//  Created by yangzexin on 10/27/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESSoundManager.h"
#import "SFFileCacheManager.h"
#import "ESRequestProxyWrapper.h"
#import "ESHTTPRequest.h"
#import "ESServiceSession.h"
#import "NSString+SFAddition.h"
#import "SFSharedCache.h"

@interface ESSoundManager ()

@property (nonatomic, retain) SFFileCacheManager *cacheManager;

@end

@implementation ESSoundManager

+ (instancetype)sharedManager
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self class] new];
    });
    return instance;
}

- (id)init
{
    self = [super init];
    
    _cacheManager = [SFFileCacheManager fileCacheManagerWithFolderPath:[self _cachePath]];
    
    return self;
}

- (NSString *)_cachePath
{
    NSString *path = [NSString stringWithFormat:@"%@/Documents/", NSHomeDirectory()];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path] == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

+ (id<ESService>)soundWithURLString:(NSString *)URLString progressTracker:(id<ESProgressTracker>)progressTracker
{
    ESHTTPRequest *request = [ESHTTPRequest requestWithURLString:URLString];
    [request setResponseDataWrapper:^id(NSData * data) {
        NSString *identifier = [URLString stringByEncryptingUsingMD5];
        [[ESSoundManager sharedManager].cacheManager storeCacheWithIdentifier:identifier data:data];
        NSString *cachedDataFilePath = [[ESSoundManager sharedManager].cacheManager cachedDataFilePathWithIdentifier:identifier];
        return cachedDataFilePath;
    }];
    [request setRequestProgressDidChange:^(float percent) {
        [progressTracker progressUpdatingWithPercent:percent];
    }];
    ESRequestProxyWrapper *wrappedRequest = [ESRequestProxyWrapper wrapperWithRequestProxy:request resultGetter:^id(NSDictionary *parameters) {
        id result = nil;
        NSString *identifier = [URLString stringByEncryptingUsingMD5];
        NSData *data = [[ESSoundManager sharedManager].cacheManager cachedDataWithIdentifier:identifier filter:[SFSharedCache foreverCacheFilter]];
        if (data != nil) {
            NSString *cachedDataFilePath = [[ESSoundManager sharedManager].cacheManager cachedDataFilePathWithIdentifier:identifier];
            result = cachedDataFilePath;
        }
        return result;
    }];
    ESServiceSession *session = [ESServiceSession sessionWithRequestProxy:wrappedRequest];
    
    return session;
}

@end
