//
//  SFSingleThreadHandler.m
//  esl
//
//  Created by yangzexin on 11/10/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "SFSingleThreadHandler.h"
#import "SFFileFragment.h"

@interface SFSingleThreadHandler () <SFSkipableURLDownloaderDelegate>

@property (nonatomic, strong) id<SFSkipableURLDownloader> URLDownloader;
@property (nonatomic, strong) SFFileFragment *fragment;
@property (nonatomic, strong) id<SFPreparedFileWritable> fileWritable;

@property (nonatomic, assign, getter=isExecuting) BOOL executing;

@end

@implementation SFSingleThreadHandler

+ (instancetype)handlerWithSkipableURLDownloader:(id<SFSkipableURLDownloader>)skipableURLDownloader fileWritable:(id<SFPreparedFileWritable>)fileWritable
{
    SFSingleThreadHandler *handler = [SFSingleThreadHandler new];
    handler.URLDownloader = skipableURLDownloader;
    handler.fileWritable = fileWritable;
    
    return handler;
}

- (void)startWithFragment:(SFFileFragment *)fragment
{
    self.fragment = fragment;
    
    [self.URLDownloader cancel];
    [self.URLDownloader setDelegate:self];
    [self.URLDownloader startWithURLString:self.fragment.URLString offset:self.fragment.offset];
    self.executing = YES;
}

- (void)_cancelURLDownloaderAndClearDelegate
{
    [self.URLDownloader cancel];
    [self.URLDownloader setDelegate:nil];
}

- (void)cancel
{
    self.executing = NO;
    [self _cancelURLDownloaderAndClearDelegate];
    self.delegate = nil;
}

#pragma mark - SFSkipableURLDownloaderDelegate
- (void)skipableURLDownloader:(id<SFSkipableURLDownloader>)skipableURLDownloader didReceiveResponse:(NSURLResponse *)response contentLength:(unsigned long long)contentLength skipable:(BOOL)skipable
{
    if (!skipable || contentLength == 0) {
        self.fragment.uncuttable = YES;
    }
    [self.delegate singleThreadHandler:self didReceiveResponse:response contentLength:contentLength skipable:skipable];
}

- (void)skipableURLDownloader:(id<SFSkipableURLDownloader>)skipableURLDownloader didDownloadData:(NSData *)data
{
    unsigned long long downloadedSize  = self.fragment.downloadedSize + data.length;
//    NSLog(@"%lld->%lld, %lld-%lld", self.fragment.offset, self.fragment.offset + self.fragment.size, self.fragment.offset + downloadedSize, self.fragment.offset + self.fragment.size);
    NSInteger numberOfDatasOutOfBounds = -1;
    if (self.fragment.size != 0 && downloadedSize > self.fragment.size) {
        numberOfDatasOutOfBounds = (NSInteger)(downloadedSize - self.fragment.size);
    }
    [self.fileWritable writeData:[data subdataWithRange:NSMakeRange(0, data.length - (numberOfDatasOutOfBounds < 0 ? 0 : numberOfDatasOutOfBounds))]
                          offset:[self.fragment writingOffset]];
    if (numberOfDatasOutOfBounds >= 0) {
        [self.fragment setDidFinish];
        [self.delegate singleThreadHandler:self didFinishDownloadingFragment:self.fragment];
        [self _cancelURLDownloaderAndClearDelegate];
    } else {
        [self.fragment increaseDownloadedSize:data.length];
    }
}

- (void)skipableURLDownloaderDidFinishDownloading:(id<SFSkipableURLDownloader>)skipableURLDownloader
{
    self.executing = NO;
    [self.fragment setDidFinish];
    [self.delegate singleThreadHandler:self didFinishDownloadingFragment:self.fragment];
}

- (void)skipableURLDownloader:(id<SFSkipableURLDownloader>)skipableURLDownloader didFailWithError:(NSError *)error
{
    self.executing = NO;
    [self.fragment setDidFailWithCurrentDownloadedSize];
    [self.delegate singleThreadHandler:self didFailDownloadingFragment:self.fragment];
}

@end
