//
//  ESSoundManager.h
//  esl
//
//  Created by yangzexin on 10/27/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESService.h"

@class ESEpisode;

@protocol ESProgressTracker <NSObject>

- (void)progressUpdatingWithPercent:(float)percent;

@end

OBJC_EXPORT NSString *ESEpisodeSoundDidDownloadNotification;

@interface ESEpisodeManager : NSObject

+ (instancetype)sharedManager;

- (void)addDownloadedEpisode:(ESEpisode *)episode;
- (void)reomoveDownloadedEpisode:(ESEpisode *)episode;
- (NSArray *)downloadedEpisodes;
- (BOOL)isEpisodeDownloaded:(ESEpisode *)episode;

- (id<ESService>)cachedSoundWithEpisode:(ESEpisode *)episode;
- (id<ESService>)downloadSoundWithEpisode:(ESEpisode *)episode progressTracker:(id<ESProgressTracker>)progressTracker;

@end
