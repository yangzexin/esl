//
//  TrackListController.h
//  esl
//
//  Created by yangzexin on 10/25/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESTableViewController.h"
#import "ESEpisodeManager.h"

@interface ESNewEpisodesController : ESTableViewController

@property (nonatomic, strong) id<ESEpisodeManager> episodeManager;

@end
