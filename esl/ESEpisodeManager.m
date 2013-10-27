//
//  ESSoundManager.m
//  esl
//
//  Created by yangzexin on 10/27/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESEpisodeManager.h"
#import "SFFileCacheManager.h"
#import "ESRequestProxyWrapper.h"
#import "ESHTTPRequest.h"
#import "ESServiceSession.h"
#import "NSString+SFAddition.h"
#import "SFSharedCache.h"
#import "ESEpisode.h"
#import "SFObject2Dict.h"
#import "SFDict2Object.h"

NSString *const downloadedEpisodesCacheIdentifier = @"downloaded_episodes";

@interface ESEpisodeManager ()

@property (nonatomic, strong) SFFileCacheManager *cacheManager;

@end

@implementation ESEpisodeManager

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

- (void)_saveDownloadedEpisodes:(NSArray *)downloadedEpisodes
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:downloadedEpisodes];
    [self.cacheManager storeCacheWithIdentifier:downloadedEpisodesCacheIdentifier data:data];
}

- (NSMutableArray *)_downloadedEpisodes
{
    NSData *dataOfDownloadedEpisodes = [self.cacheManager cachedDataWithIdentifier:downloadedEpisodesCacheIdentifier filter:[SFSharedCache foreverCacheFilter]];
    NSMutableArray *downloadedEpisodes = nil;
    if (dataOfDownloadedEpisodes.length != 0) {
        downloadedEpisodes = [NSKeyedUnarchiver unarchiveObjectWithData:dataOfDownloadedEpisodes];
    } else {
        downloadedEpisodes = [NSMutableArray array];
    }
    return downloadedEpisodes;
}

- (void)addDownloadedEpisode:(ESEpisode *)episode
{
    NSMutableArray *downloadedEpisodes = [self _downloadedEpisodes];
    
    BOOL exists = NO;
    for (NSDictionary *dict in downloadedEpisodes) {
        NSString *uid = [dict objectForKey:@"uid"];
        if ([uid isEqualToString:episode.uid]) {
            exists = YES;
            break;
        }
    }
    if (exists == NO) {
        NSDictionary *dict = [[SFObject2Dict object2Dict] dictionaryWithObject:episode];
        [downloadedEpisodes addObject:dict];
        [self _saveDownloadedEpisodes:downloadedEpisodes];
    }
}

- (void)reomoveDownloadedEpisode:(ESEpisode *)episode
{
    NSMutableArray *downloadedEpisodes = [self _downloadedEpisodes];
    
    NSInteger index = -1;
    for (NSInteger i = 0; i < downloadedEpisodes.count; ++i) {
        NSDictionary *dict = [downloadedEpisodes objectAtIndex:i];
        NSString *uid = [dict objectForKey:@"uid"];
        if ([uid isEqualToString:episode.uid]) {
            index = i;
            break;
        }
    }
    if (index != -1) {
        [downloadedEpisodes removeObjectAtIndex:index];
        [self _saveDownloadedEpisodes:downloadedEpisodes];
    }
}

- (NSArray *)downloadedEpisodes
{
    NSArray *downloadedEpisides = [self _downloadedEpisodes];
    NSArray *episides = [[SFDict2Object dict2ObjectWithObjectMapping:
                          [SFObjectMapping objectMappingWithObjectClass:[ESEpisode class]]] objectsWithDictionaries:downloadedEpisides];
    
    return episides;
}

- (BOOL)isEpisodeDownloaded:(ESEpisode *)episode
{
    BOOL downloaded = NO;
    downloaded = [self.cacheManager isCacheExistsWithIdentifier:[episode.soundURLString stringByEncryptingUsingMD5]];
    return downloaded;
}

- (id<ESService>)downloadSoundWithEpisode:(ESEpisode *)episode progressTracker:(id<ESProgressTracker>)progressTracker
{
    NSString *URLString = episode.soundURLString;
    ESHTTPRequest *request = [ESHTTPRequest requestWithURLString:URLString];
    [request setResponseDataWrapper:^id(NSData * data) {
        NSString *identifier = [URLString stringByEncryptingUsingMD5];
        [self.cacheManager storeCacheWithIdentifier:identifier data:data];
        NSString *cachedDataFilePath = [self.cacheManager cachedDataFilePathWithIdentifier:identifier];
        return cachedDataFilePath;
    }];
    __weak typeof(progressTracker) weakProgressTracker = progressTracker;
    [request setRequestProgressDidChange:^(float percent) {
        [weakProgressTracker progressUpdatingWithPercent:percent];
    }];
    ESRequestProxyWrapper *wrappedRequest = [ESRequestProxyWrapper wrapperWithRequestProxy:request resultGetter:^id(NSDictionary *parameters) {
        id result = nil;
        NSString *identifier = [URLString stringByEncryptingUsingMD5];
        NSData *data = [self.cacheManager cachedDataWithIdentifier:identifier filter:[SFSharedCache foreverCacheFilter]];
        if (data != nil) {
            NSString *cachedDataFilePath = [self.cacheManager cachedDataFilePathWithIdentifier:identifier];
            result = cachedDataFilePath;
        }
        return result;
    }];
    ESServiceSession *session = [ESServiceSession sessionWithRequestProxy:wrappedRequest];
    __weak typeof(self) weakSelf = self;
    [session setSessionDidFinishHandler:^(id resultObject, NSError *error) {
        if (error == nil) {
            [weakSelf addDownloadedEpisode:episode];
        }
    }];
    return session;
}

@end
