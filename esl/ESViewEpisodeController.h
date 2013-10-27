//
//  ESViewEpisodeController.h
//  esl
//
//  Created by yangzexin on 10/27/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESLinearController.h"

@class ESEpisode;

@interface ESViewEpisodeController : ESLinearController

+ (instancetype)viewEpisodeControllerWithEpisode:(ESEpisode *)episode;

@end
