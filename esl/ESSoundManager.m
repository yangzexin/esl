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
#import "ESEpisode.h"

@interface ESSoundManager ()

@property (nonatomic, strong) SFFileCacheManager *cacheManager;
@property (nonatomic, strong) NSMutableArray *downloadingEpisodes;
@property (nonatomic, strong) NSMutableArray *downloadEpisodeServices;
@property (nonatomic, strong) NSMutableDictionary *keyEpisodeUidValueDownloadingPercent;

@end

@implementation ESSoundManager {
    NSMutableArray *downloadingEpisodes;
}

@synthesize downloadingEpisodes = downloadingEpisodes;

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
    downloadingEpisodes = [NSMutableArray array];
    _downloadEpisodeServices = [NSMutableArray array];
    _keyEpisodeUidValueDownloadingPercent = [NSMutableDictionary dictionary];
    
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

- (NSInteger)_indexOfDownloadingEpisode:(ESEpisode *)episode
{
    NSUInteger index = NSNotFound;
    NSArray *enumeratingEpisodes = [NSArray arrayWithArray:self.downloadingEpisodes];
    for (NSInteger i = 0; i < enumeratingEpisodes.count; ++i) {
        ESEpisode *downloadingEpisode = [enumeratingEpisodes objectAtIndex:i];
        if ([downloadingEpisode.uid isEqualToString:episode.uid]) {
            index = i;
            break;
        }
    }
    return index;
}

- (BOOL)isEpisodeDownloading:(ESEpisode *)episode
{
    return [self _indexOfDownloadingEpisode:episode] != NSNotFound;
}

- (CGFloat)downloadingPercentWithEpisode:(ESEpisode *)episode
{
    NSNumber *percent = [self.keyEpisodeUidValueDownloadingPercent objectForKey:episode.uid];
    if (percent) {
        return percent.floatValue;
    }
    return 0.0f;
}

- (void)_removeDownloadingEpisode:(ESEpisode *)episode
{
    NSUInteger index = [self _indexOfDownloadingEpisode:episode];
    if (index != NSNotFound) {
        [downloadingEpisodes removeObjectAtIndex:index];
    }
    [self.keyEpisodeUidValueDownloadingPercent removeObjectForKey:episode.uid];
}

- (void)_addNewDownloadEpisode:(ESEpisode *)episode
{
    [self _removeDownloadingEpisode:episode];
    [downloadingEpisodes addObject:episode];
    [self.keyEpisodeUidValueDownloadingPercent setObject:[NSNumber numberWithFloat:0.0f] forKey:episode.uid];
}

- (void)_finishDownloadingEpisode:(ESEpisode *)episode
{
    [self _removeDownloadingEpisode:episode];
}

- (void)_downloadingPercentDidChangeForEpisode:(ESEpisode *)episode percent:(float)percent
{
    [self.keyEpisodeUidValueDownloadingPercent setObject:[NSNumber numberWithFloat:percent] forKey:episode.uid];
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
    [request setRequestProgressDidChange:^(float percent) {
        [progressTracker progressUpdatingWithPercent:percent];
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
    __weak typeof(session) weakSession = session;
    [session setSessionWillStartHandler:^{
        [weakSelf.downloadEpisodeServices addObject:weakSession];
    }];
    [session setSessionDidFinishHandler:^(id resultObject, NSError *error) {
        [weakSelf.downloadEpisodeServices removeObject:weakSession];
    }];
    
    
    return session;
}

@end
