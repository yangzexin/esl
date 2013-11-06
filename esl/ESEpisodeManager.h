//
//  ESEpisodeManager.h
//  esl
//
//  Created by yangzexin on 11/6/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ESEpisode;
@protocol ESService;

@protocol ESProgressTracker <NSObject>

- (void)progressUpdatingWithPercent:(float)percent;

@end

@protocol ESEpisodeManager <NSObject>

- (BOOL)isEpisodeDownloaded:(ESEpisode *)episode;
- (id<ESService>)episodes;
- (id<ESService>)newestEpisodes;
- (id<ESService>)soundPathWithEpisode:(ESEpisode *)episode;
- (id<ESService>)soundPathWithEpisode:(ESEpisode *)episode progressTracker:(id<ESProgressTracker>)progressTracker;

@end
