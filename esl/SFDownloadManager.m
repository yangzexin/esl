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

@interface SFFileWriter ()

@property (nonatomic, assign) float memoryCacheSizeInMegabyte;

@property (nonatomic, strong) NSMutableData *cachedData;

@end

@implementation SFFileWriter

- (void)dealloc
{
    [_fileHandle closeFile];
}

- (id)initWithFilePath:(NSString *)filePath memoryCacheSizeInMegabyte:(float)memoryCacheSizeInMegabyte
{
    self = [super init];
    
    self.filePath = filePath;
    self.memoryCacheSizeInMegabyte = memoryCacheSizeInMegabyte;
    
    return self;
}

- (unsigned long long)prepareForWriting
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:_filePath]) {
        [[NSFileManager defaultManager] createFileAtPath:_filePath contents:[NSData data] attributes:nil];
    }
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:_filePath];
    unsigned long long skipedBytes = [_fileHandle seekToEndOfFile];
    
    self.cachedData = [NSMutableData data];
    
    return skipedBytes;
}

- (void)_writeCachedData
{
    [_fileHandle writeData:_cachedData];
    [_cachedData setData:[NSData data]];
}

- (void)appendWithData:(NSData *)data
{
    [_cachedData appendData:data];
    if (_memoryCacheSizeInMegabyte * 1024 * 1024 < _cachedData.length) {
        [self _writeCachedData];
    }
}

- (void)closeFile
{
    if (_cachedData.length != 0) {
        [self _writeCachedData];
    }
    [_fileHandle closeFile];
}

@end

NSInteger const SFURLDownloaderErrorCodeResumingFail = -100001;

@interface SFURLDownloader () <NSURLConnectionDataDelegate>

@property (nonatomic, copy) NSString *URLString;

@property (nonatomic, strong) NSURLConnection *connection;

@property (nonatomic, strong) SFFileWriter *fileWriter;
@property (nonatomic, assign) unsigned long long contentLength;
@property (nonatomic, assign) unsigned long long numberOfBytesDownloaded;

@property (nonatomic, assign) BOOL finished;
@property (nonatomic, assign, getter = isDownloading) BOOL downloading;

@end

@implementation SFURLDownloader

- (id)initWithURLString:(NSString *)URLString
{
    self = [super init];
    
    self.URLString = URLString;
    self.finished = NO;
    
    return self;
}

- (NSMutableURLRequest *)_buildURLRequest
{
    return [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_URLString]];
}

- (NSString *)_tempFilePath
{
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *path = [cachePath stringByAppendingPathComponent:NSStringFromClass([self class])];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    path = [path stringByAppendingPathComponent:[_URLString stringByEncryptingUsingMD5]];
    
    return path;
}

- (NSString *)downloadingURLString
{
    return _URLString;
}

- (CGFloat)downloadedPercent
{
    float percent = ((double)_numberOfBytesDownloaded) / _contentLength;
    return percent;
}

- (void)start
{
    [self _startWithResume:NO];
}

- (void)resume
{
    [self _startWithResume:YES];
}

- (void)_openFileWriterWithDeleteExistsFile:(BOOL)deleteExistsFile
{
    NSString *tempFilePath = [self _tempFilePath];
    if (deleteExistsFile && [[NSFileManager defaultManager] fileExistsAtPath:tempFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:nil];
    }
    self.fileWriter = [[SFFileWriter alloc] initWithFilePath:tempFilePath memoryCacheSizeInMegabyte:1];
    self.numberOfBytesDownloaded = [_fileWriter prepareForWriting];
}

- (void)_startWithResume:(BOOL)resume
{
    if (!_downloading) {
        self.finished = NO;
        self.downloading = YES;
        
        [self _openFileWriterWithDeleteExistsFile:!resume];
        
        NSMutableURLRequest *request = [self _buildURLRequest];
        if (resume) {
            [request setValue:[NSString stringWithFormat:@"bytes=%llu-", _numberOfBytesDownloaded] forHTTPHeaderField:@"Range"];
        }
        self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    }
}

- (void)pause
{
    [self.connection cancel];
    [_fileWriter closeFile];
}

- (void)stop
{
    [self.connection cancel];
    [_fileWriter closeFile];
}

- (BOOL)_isSkipedBytesEqualsDownloadBytesWithHeaders:(NSDictionary *)headers
{
    BOOL equals = NO;
    
    NSString *contentRange = [headers objectForKey:@"Content-Range"];
    NSString *AcceptRanges = [headers objectForKey:@"Accept-Ranges"];
    contentRange = [contentRange stringByReplacingOccurrencesOfString:AcceptRanges withString:@""];
    contentRange = [contentRange stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSArray *attrs = [contentRange componentsSeparatedByString:@"-"];
    if (attrs.count != 0) {
        unsigned long long skipedBytes = [[attrs objectAtIndex:0] longLongValue];
        equals = skipedBytes == _numberOfBytesDownloaded;
    }
    
    return equals;
}

- (void)_notifyResumeFail
{
    if ([_delegate respondsToSelector:@selector(downloader:didFailWithError:)]) {
        [_delegate downloader:self didFailWithError:[NSError errorWithDomain:NSStringFromClass([self class])
                                                                        code:SFURLDownloaderErrorCodeResumingFail
                                                                    userInfo:@{NSLocalizedDescriptionKey : @"resumeing failed, skiped bytes not equals downloaded bytes"}]];
    }
}

#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
    self.contentLength = [[headers objectForKey:@"Content-Length"] longLongValue] + _numberOfBytesDownloaded;
    
    if (_numberOfBytesDownloaded != 0 && ![self _isSkipedBytesEqualsDownloadBytesWithHeaders:headers]) {
        [self _notifyResumeFail];
    } else {
        if ([_delegate respondsToSelector:@selector(downloaderDidStartDownloading:)]) {
            [_delegate downloaderDidStartDownloading:self];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_fileWriter appendWithData:data];
    self.numberOfBytesDownloaded += data.length;
    
    if ([_delegate respondsToSelector:@selector(downloader:progress:)]) {
        [_delegate downloader:self progress:[self downloadedPercent]];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.finished = YES;
    [_fileWriter closeFile];
    
    if ([_delegate respondsToSelector:@selector(downloaderDidFinishDownloading:filePath:)]) {
        [_delegate downloaderDidFinishDownloading:self filePath:[self _tempFilePath]];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.finished = YES;
    [_fileWriter closeFile];
    
    if ([_delegate respondsToSelector:@selector(downloader:didFailWithError:)]) {
        [_delegate downloader:self didFailWithError:error];
    }
}

#pragma mark - SFRepositionSupportedObject
- (BOOL)shouldRemoveFromObjectRepository
{
    return _finished && ![self isDownloading];
}

- (void)willRemoveFromObjectRepository
{
    [self stop];
}

@end

@interface SFDownloadItem : NSObject <NSCoding>

@property (nonatomic, copy) NSString *URLString;
@property (nonatomic, assign) float percent;
@property (nonatomic, assign) SFDownloadState state;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, strong) NSError *error;

@property (nonatomic, strong) SFURLDownloader *downloader;

+ (instancetype)downloadItemWithURLString:(NSString *)URLString;

@end

@implementation SFDownloadItem

+ (instancetype)downloadItemWithURLString:(NSString *)URLString
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

@end

@implementation SFDownloadManager

- (instancetype)initWithDownloadItemSerialization:(id<SFDownloadItemSerialization>)downloadItemSerialization
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
        item = [SFDownloadItem downloadItemWithURLString:URLString];
        [_keyURLStringValueDownloadItem setObject:item forKey:URLString];
    }
    if (item.state != SFDownloadStateDownloading || item.state == SFDownloadStateErrored) {
        SFURLDownloader *downloader = [[SFURLDownloader alloc] initWithURLString:URLString];
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
- (void)downloaderDidStartDownloading:(SFURLDownloader *)downloader
{
    if ([_delegate respondsToSelector:@selector(downloadManager:didStartDownloadingWithURLString:)]) {
        [_delegate downloadManager:self didStartDownloadingWithURLString:downloader.URLString];
    }
}

- (void)downloader:(SFURLDownloader *)downloader progress:(float)progress
{
    SFDownloadItem *item = [_keyURLStringValueDownloadItem objectForKey:downloader.URLString];
    item.percent = progress;
}

- (void)downloaderDidFinishDownloading:(SFURLDownloader *)downloader filePath:(NSString *)filePath
{
    SFDownloadItem *item = [_keyURLStringValueDownloadItem objectForKey:downloader.URLString];
    item.filePath = filePath;
    item.state = SFDownloadStateDownloaded;
    [self _save];
    
    if ([_delegate respondsToSelector:@selector(downloadManager:didFinishDownloadingWithURLString:)]) {
        [_delegate downloadManager:self didFinishDownloadingWithURLString:downloader.URLString];
    }
}

- (void)downloader:(SFURLDownloader *)downloader didFailWithError:(NSError *)error
{
    SFDownloadItem *item = [_keyURLStringValueDownloadItem objectForKey:downloader.URLString];
    item.error = error;
    item.state = SFDownloadStateErrored;
    [self _save];
    
    if ([_delegate respondsToSelector:@selector(downloadManager:didFailDownloadingWithURLString:error:)]) {
        [_delegate downloadManager:self didFailDownloadingWithURLString:downloader.URLString error:error];
    }
}

@end
