//
//  SFDownloadManager.h
//  esl
//
//  Created by yangzexin on 5/1/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SFObjectRepository.h"

@interface SFFileWriter : NSObject

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, strong) NSFileHandle *fileHandle;

- (id)initWithFilePath:(NSString *)filePath memoryCacheSizeInMegabyte:(float)memoryCacheSizeInMegabyte;
- (unsigned long long)prepareForWriting;
- (void)appendWithData:(NSData *)data;
- (void)closeFile;

@end

@class SFURLDownloader;

@protocol SFURLDownloaderDelegate <NSObject>

@optional
- (void)downloaderDidStartDownloading:(SFURLDownloader *)downloader;
- (void)downloader:(SFURLDownloader *)downloader progress:(float)progress;
- (void)downloaderDidFinishDownloading:(SFURLDownloader *)downloader filePath:(NSString *)filePath;
- (void)downloader:(SFURLDownloader *)downloader didFailWithError:(NSError *)error;

@end

OBJC_EXPORT NSInteger const SFURLDownloaderErrorCodeResumingFail;

@interface SFURLDownloader : NSObject <SFRepositionSupportedObject>

@property (nonatomic, readonly) NSString *downloadingURLString;
@property (nonatomic, assign, readonly) unsigned long long numberOfBytesDownloaded;
@property (nonatomic, assign, readonly) unsigned long long contentLength;

@property (nonatomic, weak) id<SFURLDownloaderDelegate> delegate;

- (id)initWithURLString:(NSString *)URLString;
- (void)start;
- (void)resume;
- (void)pause;
- (void)stop;
- (BOOL)isDownloading;
- (CGFloat)downloadedPercent;

@end

typedef NS_ENUM(NSUInteger, SFDownloadState) {
    SFDownloadStateNotDowloaded,
    SFDownloadStateDownloading,
    SFDownloadStateDownloaded,
    SFDownloadStateErrored,
    SFDownloadStatePaused,
};

@interface SFDownloadItem : NSObject <NSCoding>

@property (nonatomic, copy, readonly) NSString *URLString;
@property (nonatomic, assign, readonly) float percent;
@property (nonatomic, assign, readonly) SFDownloadState state;
@property (nonatomic, copy, readonly) NSString *filePath;
@property (nonatomic, strong, readonly) NSError *error;

@property (nonatomic, strong, readonly) SFURLDownloader *downloader;

+ (instancetype)downloadItemWithURLString:(NSString *)URLString;

@end

@class SFDownloadManager;

@protocol SFDownloadManagerDelegate <NSObject>

@optional
- (void)downloadManager:(SFDownloadManager *)downloadManager didStartDownloadingWithURLString:(NSString *)URLString;
- (void)downloadManager:(SFDownloadManager *)downloadManager didFinishDownloadingWithURLString:(NSString *)URLString;
- (void)downloadManager:(SFDownloadManager *)downloadManager didFailDownloadingWithURLString:(NSString *)URLString error:(NSError *)error;

@end

@protocol SFDownloadItemSerialization <NSObject>

- (NSDictionary *)keyURLStringValueDownloadItem;
- (void)setKeyURLStringValueDownloadItem:(NSDictionary *)keyURLStringValueDownloadItem;

@end

@interface SFDownloadItemUserDefaultsSerialization : NSObject <SFDownloadItemSerialization>

@end

@interface SFDownloadManager : NSObject

@property (nonatomic, assign) id<SFDownloadManagerDelegate> delegate;

@property (nonatomic, strong) id<SFDownloadItemSerialization> downloadItemSerialization;

- (instancetype)initWithDownloadItemSerialization:(id<SFDownloadItemSerialization>)downloadItemSerialization;

- (void)downloadWithURLString:(NSString *)URLString;

- (SFDownloadState)stateForURLString:(NSString *)URLString;
- (float)downloadedPercentForURLString:(NSString *)URLString;
- (NSString *)filePathWithURLString:(NSString *)URLString;
- (NSArray *)downloadingURLStrings;
- (void)pauseDownloadingWithURLString:(NSString *)URLString;
- (void)removeDownloadingWithURLString:(NSString *)URLString;

@end
