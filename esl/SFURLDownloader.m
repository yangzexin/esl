//
//  SFURLDownloader.m
//  esl
//
//  Created by yangzexin on 11/10/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "SFURLDownloader.h"
#import "SFFileWriter.h"
#import "NSString+SFAddition.h"

NSInteger const SFURLDownloaderErrorCodeResumingFail = -100001;

@interface SFSimpleURLDownloader () <NSURLConnectionDataDelegate>

@property (nonatomic, copy) NSString *URLString;

@property (nonatomic, strong) NSURLConnection *connection;

@property (nonatomic, strong) SFFileWriter *fileWriter;
@property (nonatomic, assign) unsigned long long contentLength;
@property (nonatomic, assign) unsigned long long numberOfBytesDownloaded;

@property (nonatomic, assign) BOOL finished;
@property (nonatomic, assign, getter = isDownloading) BOOL downloading;

@end

@implementation SFSimpleURLDownloader

@synthesize delegate;

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
    if (AcceptRanges) {
        contentRange = [contentRange stringByReplacingOccurrencesOfString:AcceptRanges withString:@""];
    }
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
    if ([self.delegate respondsToSelector:@selector(downloader:didFailWithError:)]) {
        [self.delegate downloader:self didFailWithError:[NSError errorWithDomain:NSStringFromClass([self class])
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
        if ([self.delegate respondsToSelector:@selector(downloaderDidStartDownloading:)]) {
            [self.delegate downloaderDidStartDownloading:self];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_fileWriter appendWithData:data];
    self.numberOfBytesDownloaded += data.length;
    
    if ([self.delegate respondsToSelector:@selector(downloader:progress:)]) {
        [self.delegate downloader:self progress:[self downloadedPercent]];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.finished = YES;
    [_fileWriter closeFile];
    
    if ([self.delegate respondsToSelector:@selector(downloaderDidFinishDownloading:filePath:)]) {
        [self.delegate downloaderDidFinishDownloading:self filePath:[self _tempFilePath]];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.finished = YES;
    [_fileWriter closeFile];
    
    if ([self.delegate respondsToSelector:@selector(downloader:didFailWithError:)]) {
        [self.delegate downloader:self didFailWithError:error];
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
