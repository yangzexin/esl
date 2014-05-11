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
#import "PlayerStatusView.h"

#import "ESSoundDownloadManager.h"

#import "SFiOSKit.h"

@interface EpisodeDetailViewController () <PlayerStatusViewDelegate>

@property (nonatomic, strong) EpisodeDetailViewModel *viewModel;
@property (nonatomic, weak) UIWebView *textView;

@property (nonatomic, strong) PlayerStatusView *playerStatusView;

@property (nonatomic, copy) NSString *html;

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
        
        self.playerStatusView = [[PlayerStatusView alloc] initWithFrame:CGRectMake(0, SFDeviceSystemVersion < 7.0f ? 0 : 64, self.view.frame.size.width, 50)];
        self.playerStatusView.delegate = self;
        [self.view addSubview:_playerStatusView];
        
        @weakify(self);
        [_viewModel.episodeDetailSignal subscribeNext:^(id x) {
            @strongify(self);
            self.html = x;
            [self _updateHtml];
        } error:^(NSError *error) {
            
        }];
        
        self.navigationItem.rightBarButtonItem = [SFBlockedBarButtonItem blockedBarButtonItemWithBarButtonSystemItem:UIBarButtonSystemItemAction eventHandler:^{
            [UIActionSheet actionSheetWithTitle:@"" completion:^(NSInteger buttonIndex, NSString *buttonTitle) {
                @strongify(self);
                if (buttonIndex == 0) {
                    [self.viewModel redownload];
                    [self.viewModel.downloadSignal subscribeNext:^(id x) {
                        
                    }];
                }
            } cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"重新下载", @"刷新", nil];
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
        
        self.playerStatusView.userInteractionEnabled = [x boolValue];
        if ([x boolValue]) {
            self.playerStatusView.totalTime = self.viewModel.totalTime;
        }
        self.playerStatusView.totalTime = self.viewModel.totalTime;
        BOOL hidden = self.playerStatusView.hidden;
        self.playerStatusView.hidden = !(self.viewModel.playingCurrentEpisode);
        if (hidden != self.playerStatusView.hidden) {
            [self _updateHtml];
        }
    }];
    
    [RACObserve(_viewModel, currentTime) subscribeNext:^(id x) {
        @strongify(self);
        self.playerStatusView.currentTime = [x doubleValue];
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

- (void)_updateHtml
{
    CGFloat paddingTop = _playerStatusView.frame.size.height;
    [self.textView loadHTMLString:[_html stringByReplacingOccurrencesOfString:@"$paddingTop" withString:_playerStatusView.hidden ? @"0" : [NSString stringWithFormat:@"%.0f", paddingTop]] baseURL:nil];
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

- (void)playerStatusView:(PlayerStatusView *)playerStatusView didChangeToNewPosition:(float)value
{
    [_viewModel jumpToTime:value];
}

@end
