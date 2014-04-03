//
//  EpisodeDetailViewController.m
//  esl
//
//  Created by yangzexin on 4/3/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "EpisodeDetailViewController.h"
#import "EpisodeDetailViewModel.h"
#import "ESEpisode.h"

@interface EpisodeDetailViewController ()

@property (nonatomic, strong) EpisodeDetailViewModel *viewModel;
@property (nonatomic, weak) UITextView *textView;

@end

@implementation EpisodeDetailViewController

+ (instancetype)controllerWithViewModel:(EpisodeDetailViewModel *)viewModel
{
    EpisodeDetailViewController *controller = [self new];
    controller.viewModel = viewModel;
    
    return controller;
}

- (void)loadView
{
    [super loadView];
    self.title = _viewModel.episode.title;
    
    {
        UITextView *textView = [[UITextView alloc] initWithFrame:self.view.bounds];
        textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        textView.font = [UIFont systemFontOfSize:15.0f];
        [self.view addSubview:textView];
        self.textView = textView;
        
        RAC(self.textView, text) = _viewModel.episodeDetailSignal;
    }
}

@end
