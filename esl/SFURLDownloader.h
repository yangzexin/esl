//
//  SFURLDownloader.h
//  esl
//
//  Created by yangzexin on 11/10/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SFURLDownloaderDelegate;

@protocol SFURLDownloader <SFDepositable>

@property (nonatomic, weak) id<SFURLDownloaderDelegate> delegate;

- (NSString *)downloadingURLString;

- (void)start;
- (void)resume;
- (void)pause;
- (void)stop;
- (BOOL)isDownloading;
- (CGFloat)downloadedPercent;

@end

@protocol SFURLDownloaderDelegate <NSObject>

@optional
- (void)downloaderDidStartDownloading:(id<SFURLDownloader>)downloader;
- (void)downloader:(id<SFURLDownloader>)downloader progress:(float)progress;
- (void)downloaderDidFinishDownloading:(id<SFURLDownloader>)downloader filePath:(NSString *)filePath;
- (void)downloader:(id<SFURLDownloader>)downloader didFailWithError:(NSError *)error;

@end

OBJC_EXPORT NSInteger const SFURLDownloaderErrorCodeResumingFail;

@interface SFSimpleURLDownloader : NSObject <SFURLDownloader>

- (id)initWithURLString:(NSString *)URLString;

@end
