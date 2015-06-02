//
//  SFDownloadManager.h
//  esl
//
//  Created by yangzexin on 5/1/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SFDepositable.h"
#import "SFURLDownloader.h"

typedef NS_ENUM(NSUInteger, SFDownloadState) {
    SFDownloadStateNotDowloaded,
    SFDownloadStateDownloading,
    SFDownloadStateDownloaded,
    SFDownloadStateErrored,
    SFDownloadStatePaused,
};

@interface SFDownloadItem : NSObject <NSCoding>

@property (nonatomic, copy, readonly) NSString *URLString;

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

- (instancetype)initWithDownloaderBuilder:(id<SFURLDownloader>(^)(NSString *URLString))downloaderBuilder;

- (instancetype)initWithDownloadItemSerialization:(id<SFDownloadItemSerialization>)downloadItemSerialization
                                downloaderBuilder:(id<SFURLDownloader>(^)(NSString *URLString))downloaderBuilder;

- (void)downloadWithURLString:(NSString *)URLString;

- (SFDownloadState)stateForURLString:(NSString *)URLString;
- (float)downloadedPercentForURLString:(NSString *)URLString;
- (NSString *)filePathWithURLString:(NSString *)URLString;
- (NSArray *)downloadingURLStrings;
- (void)pauseDownloadingWithURLString:(NSString *)URLString;
- (void)removeDownloadingWithURLString:(NSString *)URLString;

@end
