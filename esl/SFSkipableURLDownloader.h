//
//  SFSkipableURLDownloader.h
//  esl
//
//  Created by yangzexin on 11/10/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

@protocol SFSkipableURLDownloader;

@protocol SFSkipableURLDownloaderDelegate <NSObject>

- (void)skipableURLDownloader:(id<SFSkipableURLDownloader>)skipableURLDownloader didReceiveResponse:(NSURLResponse *)response contentLength:(unsigned long long)contentLength skipable:(BOOL)skipable;
- (void)skipableURLDownloader:(id<SFSkipableURLDownloader>)skipableURLDownloader didDownloadData:(NSData *)data;
- (void)skipableURLDownloaderDidFinishDownloading:(id<SFSkipableURLDownloader>)skipableURLDownloader;
- (void)skipableURLDownloader:(id<SFSkipableURLDownloader>)skipableURLDownloader didFailWithError:(NSError *)error;

@end

@protocol SFSkipableURLDownloader <NSObject>

@property (nonatomic, assign) id<SFSkipableURLDownloaderDelegate> delegate;

- (void)startWithURLString:(NSString *)URLString offset:(unsigned long long)offset;
- (void)cancel;

@end
