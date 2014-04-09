//
//  EpisodeDetailViewModel.h
//  esl
//
//  Created by yangzexin on 4/3/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseViewModel.h"

@class ESEpisode;

@interface EpisodeDetailViewModel : BaseViewModel

@property (nonatomic, strong, readonly) ESEpisode *episode;

@property (nonatomic, strong, readonly) RACSignal *episodeDetailSignal;

@property (nonatomic, assign, readonly, getter = isLoadingEpisodeDetail) BOOL loadingEpisodeDetail;

@property (nonatomic, assign, readonly, getter = isSoundDownloaded) BOOL soundDownloaded;

@property (nonatomic, assign, readonly) float downloadPercent;

+ (instancetype)viewModelWithEpisode:(ESEpisode *)episode;

@end
