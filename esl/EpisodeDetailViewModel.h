//
//  EpisodeDetailViewModel.h
//  esl
//
//  Created by yangzexin on 4/3/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ESEpisode;

@interface EpisodeDetailViewModel : NSObject

@property (nonatomic, strong, readonly) ESEpisode *episode;

@property (nonatomic, strong, readonly) RACSignal *episodeDetailSignal;

+ (instancetype)viewModelWithEpisode:(ESEpisode *)episode;

@end
