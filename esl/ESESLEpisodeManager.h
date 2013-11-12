//
//  ESSoundManager.h
//  esl
//
//  Created by yangzexin on 10/27/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESService.h"
#import "ESEpisodeManager.h"

@class ESEpisode;

@interface ESESLEpisodeManager : NSObject <ESEpisodeManager>

+ (instancetype)sharedManager;

- (void)addDownloadedEpisode:(ESEpisode *)episode;
- (void)removeDownloadedEpisode:(ESEpisode *)episode;
- (NSArray *)downloadedEpisodes;
- (void)exchangePositionWithSourceEpisode:(ESEpisode *)sourceEpisode destinationEpisode:(ESEpisode *)destinationEpisode;

@end
