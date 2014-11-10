//
//  SFDownloadManager.m
//  esl
//
//  Created by yangzexin on 5/1/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "SFDownloadManager.h"
#import "NSString+SFAddition.h"
#import "NSData+SFAddition.h"

@interface SFDownloadItem ()

@property (nonatomic, copy) NSString *URLString;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, assign) float percent;
@property (nonatomic, assign) SFDownloadState state;

@property (nonatomic, strong) id<SFURLDownloader> downloader;

@end

@implementation SFDownloadItem

+ (instancetype)itemWithURLString:(NSString *)URLString
{
    SFDownloadItem *item = [SFDownloadItem new];
    
    item.URLString = URLString;
    
    return item;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    self.URLString = [aDecoder decodeObjectForKey:@"URLString"];
    self.percent = [aDecoder decodeFloatForKey:@"percent"];
    self.state = [aDecoder decodeIntegerForKey:@"state"];
    if (_state == SFDownloadStateDownloading) {
        _state = SFDownloadStatePaused;
    }
    self.filePath = [aDecoder decodeObjectForKey:@"filePath"];
    self.error = [aDecoder decodeObjectForKey:@"error"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_URLString forKey:@"URLString"];
    [aCoder encodeFloat:_percent forKey:@"percent"];
    [aCoder encodeInteger:_state forKey:@"state"];
    [aCoder encodeObject:_filePath forKey:@"filePath"];
    [aCoder encodeObject:_error forKey:@"error"];
}

@end

@implementation SFDownloadItemUserDefaultsSerialization

- (NSDictionary *)keyURLStringValueDownloadItem
{
    NSDictionary *dictionary = nil;
    
    NSString *hexString = [[NSUserDefaults standardUserDefaults] objectForKey:@"keyURLStringValueDownloadItem"];
    if (hexString.length != 0) {
        NSData *data = [hexString dataByRestoringHexRepresentation];
        data = [data dataByPerformingDESOperation:kCCDecrypt key:NSStringFromClass([self class])];
        dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    
    return dictionary;
}

- (void)setKeyURLStringValueDownloadItem:(NSDictionary *)keyURLStringValueDownloadItem
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:keyURLStringValueDownloadItem];
    data = [data dataByPerformingDESOperation:kCCEncrypt key:NSStringFromClass([self class])];
    [[NSUserDefaults standardUserDefaults] setObject:[data hexRepresentation] forKey:@"keyURLStringValueDownloadItem"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

@interface SFDownloadManager () <SFURLDownloaderDelegate>

@property (nonatomic, strong) NSMutableDictionary *keyURLStringValueDownloadItem;
@property (nonatomic, copy)id<SFURLDownloader>(^downloaderBuilder)(NSString *URLString);

@end

@implementation SFDownloadManager

- (instancetype)initWithDownloaderBuilder:(id<SFURLDownloader>(^)(NSString *URLString))downloaderBuilder
{
    return [self initWithDownloadItemSerialization:nil downloaderBuilder:downloaderBuilder];
}

- (instancetype)initWithDownloadItemSerialization:(id<SFDownloadItemSerialization>)downloadItemSerialization
                                downloaderBuilder:(id<SFURLDownloader>(^)(NSString *URLString))downloaderBuilder
{
    self = [super init];
    
    if (downloadItemSerialization == nil) {
        downloadItemSerialization = [SFDownloadItemUserDefaultsSerialization new];
    }
    self.downloadItemSerialization = downloadItemSerialization;
    
    self.keyURLStringValueDownloadItem = [NSMutableDictionary dictionaryWithDictionary:[self.downloadItemSerialization keyURLStringValueDownloadItem]];
    
    return self;
}

- (void)_save
{
    [self.downloadItemSerialization setKeyURLStringValueDownloadItem:self.keyURLStringValueDownloadItem];
}

- (void)downloadWithURLString:(NSString *)URLString
{
    SFDownloadItem *item = [_keyURLStringValueDownloadItem objectForKey:URLString];
    if (item == nil) {
        item = [SFDownloadItem itemWithURLString:URLString];
        [_keyURLStringValueDownloadItem setObject:item forKey:URLString];
    }
    if (item.state != SFDownloadStateDownloading || item.state == SFDownloadStateErrored) {
        id<SFURLDownloader> downloader = self.downloaderBuilder(URLString);
        downloader.delegate = self;
        if (item.state == SFDownloadStateErrored || item.state == SFDownloadStatePaused) {
            [downloader resume];
        } else {
            [downloader start];
        }
        item.state = SFDownloadStateDownloading;
        item.downloader = downloader;
    }
    [self _save];
}

- (SFDownloadState)stateForURLString:(NSString *)URLString
{
    SFDownloadState state = SFDownloadStateNotDowloaded;
    
    SFDownloadItem *item = [_keyURLStringValueDownloadItem objectForKey:URLString];
    if (item) {
        state = item.state;
    }
    
    return state;
}

- (float)downloadedPercentForURLString:(NSString *)URLString
{
    SFDownloadItem *item = [_keyURLStringValueDownloadItem objectForKey:URLString];
    return item.percent;
}

- (NSString *)filePathWithURLString:(NSString *)URLString
{
    SFDownloadItem *item = [_keyURLStringValueDownloadItem objectForKey:URLString];
    return item.filePath;
}

- (void)pauseDownloadingWithURLString:(NSString *)URLString
{
    SFDownloadItem *item = [_keyURLStringValueDownloadItem objectForKey:URLString];
    item.state = SFDownloadStatePaused;
    [[item downloader] pause];
}

- (void)removeDownloadingWithURLString:(NSString *)URLString
{
    SFDownloadItem *item = [_keyURLStringValueDownloadItem objectForKey:URLString];
    [[item downloader] stop];
    [_keyURLStringValueDownloadItem removeObjectForKey:URLString];
    [[NSFileManager defaultManager] removeItemAtPath:item.filePath error:nil];
}

- (NSArray *)downloadingURLStrings
{
    return [_keyURLStringValueDownloadItem allKeys];
}

#pragma mark - SFURLDownloaderDelegate
- (void)downloaderDidStartDownloading:(id<SFURLDownloader>)downloader
{
    if ([_delegate respondsToSelector:@selector(downloadManager:didStartDownloadingWithURLString:)]) {
        [_delegate downloadManager:self didStartDownloadingWithURLString:downloader.downloadingURLString];
    }
}

- (void)downloader:(id<SFURLDownloader>)downloader progress:(float)progress
{
    SFDownloadItem *item = [_keyURLStringValueDownloadItem objectForKey:downloader.downloadingURLString];
    item.percent = progress;
}

- (void)downloaderDidFinishDownloading:(id<SFURLDownloader>)downloader filePath:(NSString *)filePath
{
    SFDownloadItem *item = [_keyURLStringValueDownloadItem objectForKey:downloader.downloadingURLString];
    item.filePath = filePath;
    item.state = SFDownloadStateDownloaded;
    [self _save];
    
    if ([_delegate respondsToSelector:@selector(downloadManager:didFinishDownloadingWithURLString:)]) {
        [_delegate downloadManager:self didFinishDownloadingWithURLString:downloader.downloadingURLString];
    }
}

- (void)downloader:(id<SFURLDownloader>)downloader didFailWithError:(NSError *)error
{
    SFDownloadItem *item = [_keyURLStringValueDownloadItem objectForKey:downloader.downloadingURLString];
    item.error = error;
    item.state = SFDownloadStateErrored;
    [self _save];
    
    if ([_delegate respondsToSelector:@selector(downloadManager:didFailDownloadingWithURLString:error:)]) {
        [_delegate downloadManager:self didFailDownloadingWithURLString:downloader.downloadingURLString error:error];
    }
}

@end
