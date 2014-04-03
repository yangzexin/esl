//
//  EpisodeDetailViewController.h
//  esl
//
//  Created by yangzexin on 4/3/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESTableViewController.h"

@class EpisodeDetailViewModel;

@interface EpisodeDetailViewController : ESViewController

+ (instancetype)controllerWithViewModel:(EpisodeDetailViewModel *)viewModel;

@end
