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

#import "AppDelegate+SharedUtils.h"

#import "SFFoundation.h"

NSString *const ESSoundDownloadManagerDidFinishDownloadEpisodeNotification = @"ESSoundDownloadManagerDidFinishDownloadEpisodeNotification";

@interface ESDownloadItemSerialization : NSObject <SFDownloadItemSerialization>

@end

@implementation ESDownloadItemSerialization

- (id)init
{
    self = [super init];
    
    return self;
}

- (void)setKeyURLStringValueDownloadItem:(NSDictionary *)keyURLStringValueDownloadItem
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:keyURLStringValueDownloadItem];
    [data writeToFile:[[AppDelegate configurationPath] stringByAppendingPathComponent:@"keyURLStringValueDownloadItem"] atomically:NO];
}

- (NSDictionary *)keyURLStringValueDownloadItem
{
    NSDictionary *dictionary = nil;
    
    NSData *data = [NSData dataWithContentsOfFile:[[AppDelegate configurationPath] stringByAppendingPathComponent:@"keyURLStringValueDownloadItem"]];
    if (data.length != 0) {
        dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    return dictionary;
}

@end

@interface ESSoundDownloadManager () <SFDownloadManagerDelegate>

@property (nonatomic, strong) SFDownloadManager *downloadManager;

@property (nonatomic, strong) LevelDB *keyURLStringValueEpisode;
@property (nonatomic, strong) LevelDB *keyURLStringValueError;

@property (nonatomic, strong) LevelDB *keyURLStringValueSoundFileName;

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
    
    self.downloadManager = [[SFDownloadManager alloc] initWithDownloadItemSerialization:[ESDownloadItemSerialization new] downloaderBuilder:^id<SFURLDownloader>(NSString *URLString) {
        return [[SFSimpleURLDownloader alloc] initWithURLString:URLString];
    }];
    _downloadManager.delegate = self;
    
    self.keyURLStringValueEpisode = [AppDelegate levelDBWithName:@"keyURLStringValueEpisode"];
    [_keyURLStringValueEpisode setEncoder:^NSData *(LevelDBKey *key, ESEpisode *object){
        NSDictionary *dictionary = [object dictionary];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
        return data;
    }];
    [_keyURLStringValueEpisode setDecoder:^id(LevelDBKey *key, NSData *data){
        NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        return [ESEpisode objectFromDictionary:dictionary];
    }];
    
    self.keyURLStringValueError = [AppDelegate levelDBWithName:@"keyURLStringValueError"];
    [_keyURLStringValueError setEncoder:^NSData *(LevelDBKey *key, id object){
        return [NSKeyedArchiver archivedDataWithRootObject:object];
    }];
    [_keyURLStringValueError setDecoder:^id(LevelDBKey *key, NSData *data){
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }];
    
    self.keyURLStringValueSoundFileName = [AppDelegate levelDBWithName:@"keyURLStringValueSoundFileName"];
    [_keyURLStringValueSoundFileName setEncoder:^NSData *(LevelDBKey *key, NSString *object){
        return [object dataUsingEncoding:NSUTF8StringEncoding];
    }];
    [_keyURLStringValueSoundFileName setDecoder:^NSString *(LevelDBKey *key, NSData *data){
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }];
    
    return self;
}

- (SFDownloadState)stateForEpisode:(ESEpisode *)episode
{
    SFDownloadState state = [_downloadManager stateForURLString:episode.soundURLString];
    if (state == SFDownloadStateNotDowloaded) {
        NSString *soundPath = [_keyURLStringValueSoundFileName objectForKey:episode.soundURLString];
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
    NSString *soundFilePath = [_keyURLStringValueSoundFileName objectForKey:episode.soundURLString];
    [[NSFileManager defaultManager] removeItemAtPath:soundFilePath error:nil];
    [_keyURLStringValueSoundFileName removeObjectForKey:episode.soundURLString];
    [_downloadManager removeDownloadingWithURLString:episode.soundURLString];
}

- (void)pauseDownloadingEpisode:(ESEpisode *)episode
{
    [_downloadManager pauseDownloadingWithURLString:episode.soundURLString];
}

- (NSString *)soundFilePathForEpisode:(ESEpisode *)episode
{
    NSString *soundFileName = [_keyURLStringValueSoundFileName objectForKey:episode.soundURLString];
    return [[self _soundFolder] stringByAppendingPathComponent:soundFileName];
}

- (NSArray *)downloadingEpisodes
{
    NSArray *downloadURLStrings = [_downloadManager downloadingURLStrings];
    NSMutableArray *downloadingEpisodes = [NSMutableArray array];
    for (NSString *URLString in downloadURLStrings) {
        ESEpisode *episode = [_keyURLStringValueEpisode objectForKey:URLString];
        SFDownloadState state = [self stateForEpisode:episode];
        if (state != SFDownloadStateDownloaded) {
            episode.sort += 10000;
        }
        [downloadingEpisodes addObject:episode];
    }
    [downloadingEpisodes sortUsingComparator:^NSComparisonResult(ESEpisode *obj1, ESEpisode *obj2) {
        return obj1.sort > obj2.sort ? NSOrderedAscending : NSOrderedDescending;
    }];
    return downloadingEpisodes;
}

- (NSError *)errorForEpisode:(ESEpisode *)episode
{
    return [_keyURLStringValueEpisode objectForKey:episode.soundURLString];
}

- (NSString *)_soundFolder
{
    NSString *soundFolder = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"ESLSounds.docset"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:soundFolder]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:soundFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return soundFolder;
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
    NSString *soundFolder = [self _soundFolder];
    NSString *soundFileName = [URLString stringByEncryptingUsingMD5];
    NSString *newSoundFilePath = [soundFolder stringByAppendingPathComponent:soundFileName];
    
    [[NSFileManager defaultManager] moveItemAtPath:soundFilePath toPath:newSoundFilePath error:nil];
    
    [_keyURLStringValueSoundFileName setObject:soundFileName forKey:URLString];
}

@end
