//
//  SFMultiThreadURLDownloader.m
//  esl
//
//  Created by yangzexin on 11/10/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "SFMultiThreadURLDownloader.h"
#import "SFSingleThreadHandler.h"
#import "SFFileFragment.h"
#import "SFMultiThreadDownloadingContext.h"
#import "SFURLConnectionSkipableURLDownloader.h"

@interface SFMultiThreadURLDownloader () <SFSingleThreadHandlerDelegate, SFMultiThreadDownloadingContextDelegate>

@property (nonatomic, copy) NSString *URLString;
@property (nonatomic, assign, getter=isDownloading) BOOL downloading;

@property (nonatomic, strong) id<SFPreparedFileWritable> fileWriter;

@property (nonatomic, strong) SFMultiThreadDownloadingContext *context;
@property (nonatomic, strong) NSArray *singleThreadHandlers;

@end

@implementation SFMultiThreadURLDownloader

@synthesize delegate;

- (id)initWithURLString:(NSString *)URLString fileWritable:(id<SFPreparedFileWritable>)fileWritable
{
    self = [super init];
    
    self.URLString = URLString;
    self.fileWriter = fileWritable;
    
    return self;
}

- (NSString *)downloadingURLString
{
    return self.URLString;
}

- (void)start
{
    self.singleThreadHandlers = @[
                                  [SFSingleThreadHandler handlerWithSkipableURLDownloader:[SFURLConnectionSkipableURLDownloader new] fileWritable:self.fileWriter]
                                  , [SFSingleThreadHandler handlerWithSkipableURLDownloader:[SFURLConnectionSkipableURLDownloader new] fileWritable:self.fileWriter]
                                  ];
    self.context = [[SFMultiThreadDownloadingContext alloc] initWithURLString:self.URLString];
    self.context.delegate = self;
    
    [self _tryDownloading];
}

- (void)_tryDownloading
{
    SFSingleThreadHandler *usableHandler = nil;
    for (SFSingleThreadHandler *tmpHandler in self.singleThreadHandlers) {
        if (![tmpHandler isExecuting]) {
            usableHandler = tmpHandler;
            break;
        }
    }
    SFFileFragment *fragment = [self.context nextFragment];
    if ([self.context isFinished]) {
        return;
    }
    if (usableHandler) {
        usableHandler.delegate = self;
        [usableHandler startWithFragment:fragment];
    }
}

- (void)resume
{
}

- (void)pause
{
}

- (void)stop
{
}

- (CGFloat)downloadedPercent
{
    return .0f;
}

- (void)willRemoveFromObjectRepository
{
}

- (BOOL)shouldRemoveFromObjectRepository
{
    return NO;
}

#pragma mark - SFMultiThreadDownloadingContextDelegate
- (void)multiThreadDownloadingContextDidFinishDownloading:(SFMultiThreadDownloadingContext *)multiThreadDownloadingContext
{
    [self.fileWriter close];
    NSLog(@"multiThreadDownloadingContextDidFinishDownloading:%@", multiThreadDownloadingContext.URLString);
}

#pragma mark - SFSingleThreadHandlerDelegate
- (void)singleThreadHandler:(SFSingleThreadHandler *)singleThreadHandler didReceiveResponse:(NSURLResponse *)response contentLength:(unsigned long long)contentLength skipable:(BOOL)skipable
{
    [self.context.mainFragment setContentLength:contentLength];
    self.context.mainFragment.uncuttable = !skipable;
    [self.fileWriter preparingForFileWritingWithFileSize:contentLength];
    
    [self _tryDownloading];
}

- (void)singleThreadHandler:(SFSingleThreadHandler *)singleThreadHandler didFinishDownloadingFragment:(SFFileFragment *)fragment
{
    NSLog(@"didFinishDownloadingFragment:%lld-%lld", fragment.offset, fragment.offset + fragment.size);
    [self.context fragmentDidFinish:fragment];
    [self _tryDownloading];
}

- (void)singleThreadHandler:(SFSingleThreadHandler *)singleThreadHandler didFailDownloadingFragment:(SFFileFragment *)fragment
{
    NSLog(@"didFailDownloadingFragment:%lld-%lld", fragment.offset, fragment.offset + fragment.size);
    [self.context fragmentDidFail:fragment];
    [self _tryDownloading];
}

@end
