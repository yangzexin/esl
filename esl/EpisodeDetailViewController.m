//
//  EpisodeDetailViewController.m
//  esl
//
//  Created by yangzexin on 4/3/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "EpisodeDetailViewController.h"
#import "ESEpisode.h"

@interface EpisodeDetailViewController ()

@property (nonatomic, strong) ESEpisode *episode;

@end

@implementation EpisodeDetailViewController

+ (instancetype)controllerWithEpisode:(ESEpisode *)episode
{
    EpisodeDetailViewController *controller = [self new];
    controller.episode = episode;
    
    return controller;
}

- (void)loadView
{
    [super loadView];
    self.title = _episode.title;
}

@end
