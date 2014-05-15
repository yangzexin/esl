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

@property (nonatomic, strong) LevelDB *keyURLStringValueSoundPath;

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
        return [NSKeyedArchiver archivedDataWithRootObject:object];
    }];
    [_keyURLStringValueError setDecoder:^id(LevelDBKey *key, NSData *data){
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }];
    
    self.keyURLStringValueSoundPath = [LevelDB databaseInLibraryWithName:@"keyURLValueSound"];
    [_keyURLStringValueSoundPath setEncoder:^NSData *(LevelDBKey *key, NSString *object){
        return [object dataUsingEncoding:NSUTF8StringEncoding];
    }];
    [_keyURLStringValueSoundPath setDecoder:^NSString *(LevelDBKey *key, NSData *data){
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }];
    
    return self;
}

- (SFDownloadState)stateForEpisode:(ESEpisode *)episode
{
    SFDownloadState state = [_downloadManager stateForURLString:episode.soundURLString];
    if (state == SFDownloadStateNotDowloaded) {
        NSString *soundPath = [_keyURLStringValueSoundPath objectForKey:episode.soundURLString];
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

- (void)removeEpisode:(ESEpisode *)episode
{
    NSString *soundFilePath = [_keyURLStringValueSoundPath objectForKey:episode.soundURLString];
    [[NSFileManager defaultManager] removeItemAtPath:soundFilePath error:nil];
    [_keyURLStringValueSoundPath removeObjectForKey:episode.soundURLString];
    [_downloadManager removeDownloadingWithURLString:episode.soundURLString];
}

- (void)pauseDownloadingEpisode:(ESEpisode *)episode
{
    [_downloadManager pauseDownloadingWithURLString:episode.soundURLString];
}

- (NSString *)soundFilePathForEpisode:(ESEpisode *)episode
{
    NSString *soundPath = [_keyURLStringValueSoundPath objectForKey:episode.soundURLString];
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
    
    [_keyURLStringValueSoundPath setObject:newSoundFilePath forKey:URLString];
}

@end
