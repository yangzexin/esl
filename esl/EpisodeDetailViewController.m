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
#import "UIWebView+SFAddition.h"

@interface EpisodeDetailViewController ()

@property (nonatomic, strong) EpisodeDetailViewModel *viewModel;
@property (nonatomic, weak) UIWebView *textView;

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
        UIWebView *textView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [textView removeShadow];
        [self.view addSubview:textView];
        self.textView = textView;
        
        @weakify(self);
        [_viewModel.episodeDetailSignal subscribeNext:^(id x) {
            @strongify(self);
            [self.textView loadHTMLString:x baseURL:nil];
        } error:^(NSError *error) {
            
        }];
    }
    
    {
        
    }
}

@end
