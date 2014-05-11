//
//  EpisodeDetailViewModel.h
//  esl
//
//  Created by yangzexin on 4/3/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseViewModel.h"

#import "ESSoundDownloadManager.h"

@class ESEpisode;

@interface EpisodeDetailViewModel : BaseViewModel

@property (nonatomic, strong, readonly) ESEpisode *episode;

@property (nonatomic, strong, readonly) RACSignal *episodeDetailSignal;

@property (nonatomic, strong, readonly) RACSignal *downloadSignal;

@property (nonatomic, assign, readonly, getter = isLoadingEpisodeDetail) BOOL loadingEpisodeDetail;

@property (nonatomic, assign, readonly) SFDownloadState downloadState;

@property (nonatomic, assign, readonly) float downloadPercent;

@property (nonatomic, assign, readonly) BOOL soundPlaying;
@property (nonatomic, readonly) BOOL playingCurrentEpisode;

@property (nonatomic, assign) NSTimeInterval currentTime;
@property (nonatomic, readonly) NSTimeInterval totalTime;

+ (instancetype)viewModelWithEpisode:(ESEpisode *)episode;

- (void)playSound;
- (void)pauseSound;

- (void)redownload;

- (void)jumpToTime:(NSTimeInterval)time;

@end
