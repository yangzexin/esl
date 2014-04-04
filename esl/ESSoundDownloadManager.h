//
//  ESSoundDownloadManager.h
//  esl
//
//  Created by yangzexin on 4/4/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ESEpisode;

typedef NS_ENUM(NSUInteger, ESSoundDownloadState) {
    ESSoundDownloadStateNotDownloaded,
    ESSoundDownloadStateDownloading,
    ESSoundDownloadStateDownloaded,
};

OBJC_EXPORT NSString *const ESSoundDownloadManagerDidFinishDownloadEpisodeNotification;

@interface ESSoundDownloadManager : NSObject

+ (instancetype)sharedManager;

- (ESSoundDownloadState)stateForEpisode:(ESEpisode *)episode;
- (void)downloadEpisode:(ESEpisode *)episode;
- (float)downloadedPercentForEpisode:(ESEpisode *)episode;
- (NSString *)soundFilePathForEpisode:(ESEpisode *)episode;

@end
