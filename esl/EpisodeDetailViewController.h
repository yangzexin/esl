//
//  EpisodeDetailViewController.h
//  esl
//
//  Created by yangzexin on 4/3/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESTableViewController.h"

@class ESEpisode;

@interface EpisodeDetailViewController : ESViewController

+ (instancetype)controllerWithEpisode:(ESEpisode *)episode;

@end
