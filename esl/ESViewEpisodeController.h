//
//  ESViewEpisodeController.h
//  esl
//
//  Created by yangzexin on 10/27/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESLinearController.h"
#import "ESEpisodeManager.h"

@class ESEpisode;

@interface ESViewEpisodeController : ESLinearController

@property (nonatomic, strong) id<ESEpisodeManager> episodeManager;

+ (instancetype)viewEpisodeControllerWithEpisode:(ESEpisode *)episode;

@end
