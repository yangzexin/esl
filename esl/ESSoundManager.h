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

@interface ESSoundManager : NSObject

@property (nonatomic, readonly) NSArray *downloadingEpisodes;

+ (instancetype)sharedManager;

- (BOOL)isEpisodeDownloading:(ESEpisode *)episode;
- (CGFloat)downloadingPercentWithEpisode:(ESEpisode *)episode;
- (id<ESService>)downloadSoundWithEpisode:(ESEpisode *)episode progressTracker:(id<ESProgressTracker>)progressTracker;

@end
