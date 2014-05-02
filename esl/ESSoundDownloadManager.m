//
//  ESSoundDownloadManager.m
//  esl
//
//  Created by yangzexin on 4/4/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "ESSoundDownloadManager.h"

#import "ESEpisode.h"

#import "SFDownloadManager.h"

#import "SFDBCacheManager.h"
#import "SFBuildInCacheFilters.h"

#import "NSString+SFAddition.h"

#import <Objective-LevelDB/LevelDB.h>

#import "SFFoundation.h"

NSString *const ESSoundDownloadManagerDidFinishDownloadEpisodeNotification = @"ESSoundDownloadManagerDidFinishDownloadEpisodeNotification";

@interface ESSoundDownloadManager () <SFDownloadManagerDelegate>

@property (nonatomic, strong) SFDownloadManager *downloadManager;

@property (nonatomic, strong) LevelDB *keyURLStringValueEpisode;
@property (nonatomic, strong) LevelDB *keyURLStringValueError;

@property (nonatomic, strong) SFDBCacheManager *keyURLStringValueSoundPath;

@end

@implementation ESSoundDownloadManager

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
    
    self.downloadManager = [SFDownloadManager new];
    _downloadManager.delegate = self;
    
    self.keyURLStringValueEpisode = [LevelDB databaseInLibraryWithName:@"keyURLStringValueEpisode"];
    [_keyURLStringValueEpisode setEncoder:^NSData *(LevelDBKey *key, ESEpisode *object){
        NSDictionary *dictionary = [object dictionary];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
        return data;
    }];
    [_keyURLStringValueEpisode setDecoder:^id(LevelDBKey *key, NSData *data){
        NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        return [ESEpisode objectWithDictionary:dictionary];
    }];
    
    self.keyURLStringValueError = [LevelDB databaseInLibraryWithName:@"keyURLStringValueError"];
    [_keyURLStringValueError setEncoder:^NSData *(LevelDBKey *key, id object){
        return nil;
    }];
    [_keyURLStringValueError setDecoder:^id(LevelDBKey *key, NSData *data){
        return nil;
    }];
    
    self.keyURLStringValueSoundPath = [SFDBCacheManager cacheManagerInLibraryWithName:@"keyURLValueSound"];
    
    return self;
}

- (SFDownloadState)stateForEpisode:(ESEpisode *)episode
{
    SFDownloadState state = [_downloadManager stateForURLString:episode.soundURLString];
    if (state == SFDownloadStateNotDowloaded) {
        NSString *soundPath = [[NSString alloc] initWithData:[_keyURLStringValueSoundPath cachedDataWithIdentifier:episode.soundURLString filter:[SFBuildInCacheFilters foreverCacheFilter]] encoding:NSUTF8StringEncoding];
        if (soundPath.length != 0 && [[NSFileManager defaultManager] fileExistsAtPath:soundPath]) {
            state = SFDownloadStateDownloaded;
        }
    }
    return state;
}

- (void)downloadEpisode:(ESEpisode *)episode
{
    [_downloadManager downloadWithURLString:episode.soundURLString];
    [_keyURLStringValueEpisode setObject:episode forKey:episode.soundURLString];
}

- (float)downloadedPercentForEpisode:(ESEpisode *)episode
{
    return [_downloadManager downloadedPercentForURLString:episode.soundURLString];
}

- (NSString *)soundFilePathForEpisode:(ESEpisode *)episode
{
    NSString *soundPath = [_downloadManager filePathWithURLString:episode.soundURLString];
    if ((soundPath.length == 0 || ![[NSFileManager defaultManager] fileExistsAtPath:soundPath]) && [self stateForEpisode:episode] == SFDownloadStateDownloaded) {
        soundPath = [[NSString alloc] initWithData:[_keyURLStringValueSoundPath cachedDataWithIdentifier:episode.soundURLString filter:[SFBuildInCacheFilters foreverCacheFilter]] encoding:NSUTF8StringEncoding];
    }
    return soundPath;
}

- (NSArray *)downloadingEpisodes
{
    NSArray *downloadURLStrings = [_downloadManager downloadingURLStrings];
    NSMutableArray *downloadingEpisodes = [NSMutableArray array];
    for (NSString *URLString in downloadURLStrings) {
        [downloadingEpisodes addObject:[_keyURLStringValueEpisode objectForKey:URLString]];
    }
    return downloadingEpisodes;
}

- (NSError *)errorForEpisode:(ESEpisode *)episode
{
    return [_keyURLStringValueEpisode objectForKey:episode.soundURLString];
}

#pragma mark - SFDownloadManagerDelegate
- (void)downloadManager:(SFDownloadManager *)downloadManager didFailDownloadingWithURLString:(NSString *)URLString error:(NSError *)error
{
    [_keyURLStringValueError setObject:error forKey:URLString];
}

- (void)downloadManager:(SFDownloadManager *)downloadManager didStartDownloadingWithURLString:(NSString *)URLString
{
}

- (void)downloadManager:(SFDownloadManager *)downloadManager didFinishDownloadingWithURLString:(NSString *)URLString
{
    NSString *soundFilePath = [downloadManager filePathWithURLString:URLString];
    NSString *soundFolder = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"ESLSounds"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:soundFolder]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:soundFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *newSoundFilePath = [soundFolder stringByAppendingPathComponent:[URLString stringByEncryptingUsingMD5]];
    
    [[NSFileManager defaultManager] moveItemAtPath:soundFilePath toPath:newSoundFilePath error:nil];
    
    [_keyURLStringValueSoundPath storeCacheWithIdentifier:URLString data:[newSoundFilePath dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
