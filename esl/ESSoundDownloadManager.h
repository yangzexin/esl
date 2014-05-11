//
//  ESSoundDownloadManager.h
//  esl
//
//  Created by yangzexin on 4/4/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SFDownloadManager.h"

@class ESEpisode;

OBJC_EXPORT NSString *const ESSoundDownloadManagerDidFinishDownloadEpisodeNotification;

@interface ESSoundDownloadManager : NSObject

+ (instancetype)sharedManager;

- (SFDownloadState)stateForEpisode:(ESEpisode *)episode;
- (void)downloadEpisode:(ESEpisode *)episode;
- (float)downloadedPercentForEpisode:(ESEpisode *)episode;
- (void)removeEpisode:(ESEpisode *)episode;
- (void)pauseDownloadingEpisode:(ESEpisode *)episode;
- (NSString *)soundFilePathForEpisode:(ESEpisode *)episode;
- (NSArray *)downloadingEpisodes;
- (NSError *)errorForEpisode:(ESEpisode *)episode;

@end
