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
#import "SFWaitingIndicator.h"

#import "ESSoundDownloadManager.h"

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
    
    @weakify(self);
    [RACObserve(_viewModel, loadingEpisodeDetail) subscribeNext:^(id x) {
        NSNumber *loading = x;
        @strongify(self);
        [SFWaitingIndicator showLoading:[loading boolValue] inView:self.view];
    }];
    
    UIBarButtonItem *downloadingIndicatorButton = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    UIBarButtonItem *playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(_playButtonTapped)];
    UIBarButtonItem *retryButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(_retryButtonTapped)];
    UIBarButtonItem *pauseButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(_pauseButtonTapped)];
    
    [RACObserve(_viewModel, downloadState) subscribeNext:^(NSNumber *num) {
        @strongify(self);
        if (!self.viewModel.soundPlaying) {
            NSMutableArray *toolbarItems = [NSMutableArray array];
            [toolbarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
            SFDownloadState downloadState = [num integerValue];
            if (downloadState == SFDownloadStateNotDowloaded) {
                UIBarButtonItem *downloadBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"下载" style:UIBarButtonItemStylePlain target:self action:@selector(_downloadButtonTapped:)];
                [toolbarItems addObject:downloadBarButtonItem];
            } else if (downloadState == SFDownloadStateDownloading) {
                [toolbarItems addObject:downloadingIndicatorButton];
            } else if (downloadState == SFDownloadStateErrored || downloadState == SFDownloadStatePaused) {
                [toolbarItems addObject:retryButton];
            } else if (downloadState == SFDownloadStateDownloaded) {
                [toolbarItems addObject:playButton];
            }
            [toolbarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
            self.toolbarItems = toolbarItems;
        }
    }];
    
    [RACObserve(_viewModel, downloadPercent) subscribeNext:^(NSNumber *num) {
        downloadingIndicatorButton.title = [NSString stringWithFormat:@"%.0f%%", [num floatValue] * 100];
    }];
    
    [RACObserve(_viewModel, soundPlaying) subscribeNext:^(NSNumber *x) {
        @strongify(self);
        if (self.viewModel.downloadState == SFDownloadStateDownloaded) {
            NSMutableArray *toolbarItems = [NSMutableArray array];
            [toolbarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
            if ([x boolValue]) {
                [toolbarItems addObject:pauseButton];
            } else {
                [toolbarItems addObject:playButton];
            }
            [toolbarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
            self.toolbarItems = toolbarItems;
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)_downloadButtonTapped:(UIBarButtonItem *)downloadBarButtonItem
{
    [_viewModel.downloadSignal subscribeNext:^(id x) {
        
    }];
}

- (void)_playButtonTapped
{
    [_viewModel playSound];
}

- (void)_retryButtonTapped
{
    [_viewModel.downloadSignal subscribeNext:^(id x) {
        
    }];
}

- (void)_pauseButtonTapped
{
    [self.viewModel pauseSound];
}

@end
