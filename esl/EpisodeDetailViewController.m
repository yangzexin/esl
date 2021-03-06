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

#import "PlayerStatusView.h"

#import "AppDelegate+SharedUtils.h"

@interface EpisodeDetailViewController () <PlayerStatusViewDelegate, UIWebViewDelegate>

@property (nonatomic, strong) EpisodeDetailViewModel *viewModel;
@property (nonatomic, weak) UIWebView *textView;

@property (nonatomic, strong) PlayerStatusView *playerStatusView;

@property (nonatomic, copy) NSString *html;

@property (nonatomic, strong) LevelDB *textCacheDB;

@property (nonatomic, assign) BOOL updatingHTML;

@end

@implementation EpisodeDetailViewController

+ (instancetype)controllerWithViewModel:(EpisodeDetailViewModel *)viewModel
{
    EpisodeDetailViewController *controller = [self new];
    controller.viewModel = viewModel;
    controller.hidesBottomBarWhenPushed = YES;
    
    return controller;
}

- (void)loadView
{
    [super loadView];
    
    self.title = @"Episode";
    self.toolbarHidden = NO;
    
    if (SFDeviceSystemVersion < 7.0f) {
        self.navigationController.toolbar.barStyle = UIBarStyleBlackOpaque;
    }
    
    {
        UIWebView *textView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [textView sf_removeShadow];
        [self.view addSubview:textView];
        textView.delegate = self;
        textView.opaque = NO;
        textView.backgroundColor = [UIColor clearColor];
        self.textView = textView;
        
        self.playerStatusView = [[PlayerStatusView alloc] initWithFrame:CGRectMake(0, SFDeviceSystemVersion < 7.0f ? 0 : 64, self.view.frame.size.width, 50)];
        self.playerStatusView.delegate = self;
        [self.view addSubview:_playerStatusView];
        
        @weakify(self);
        
        self.navigationItem.rightBarButtonItem = [SFBlockedBarButtonItem blockedBarButtonItemWithBarButtonSystemItem:UIBarButtonSystemItemAction tap:^{
            @strongify(self);
            NSMutableArray *actionTitles = [NSMutableArray array];
            if ([self.viewModel downloadState] == SFDownloadStateDownloaded) {
                [actionTitles addObject:@"重新下载"];
            }
            [actionTitles addObject:self.html.length == 0 ? @"显示文本" : @"刷新文本"];
            [UIActionSheet sf_actionSheetWithTitle:@"" completion:^(NSInteger buttonIndex, NSString *buttonTitle) {
                @strongify(self);
                if ([buttonTitle isEqualToString:@"重新下载"]) {
                    [UIAlertView sf_alertWithTitle:@"温馨提示" message:@"确定要重新下载音频吗？" completion:^(NSInteger buttonIndex, NSString *buttonTitle) {
                        if (buttonIndex != 0) {
                            [self.viewModel redownload];
                            [self.viewModel startDownload];
                        }
                    } cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
                } else if ([buttonTitle isEqualToString:@"显示文本"] || [buttonTitle isEqualToString:@"刷新文本"]) {
                    [self _viewTextContentWithRefreshing:[buttonTitle isEqualToString:@"刷新文本"]];
                }
            } cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitleList:actionTitles];
        }];
    }
    
    @weakify(self);
    [RACObserve(_viewModel, loadingEpisodeDetail) subscribeNext:^(id x) {
        NSNumber *loading = x;
        @strongify(self);
        [SFWaitingIndicator showLoading:[loading boolValue] inView:self.textView transparentBackground:NO identifier:@"loadingEpisodeDetail"];
    }];
    
    UIBarButtonItem *downloadingIndicatorButton = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:@selector(_downloadingIndicatorButtonTapped)];
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
    
    UIBarButtonItem *rewindButton = [SFBlockedBarButtonItem blockedBarButtonItemWithBarButtonSystemItem:UIBarButtonSystemItemRewind tap:^{
        @strongify(self);
        [self.viewModel rewind];
    }];
    
    UIBarButtonItem *fastForwardButton = [SFBlockedBarButtonItem blockedBarButtonItemWithBarButtonSystemItem:UIBarButtonSystemItemFastForward tap:^{
        @strongify(self);
        [self.viewModel fastForward];
    }];
    
    [RACObserve(_viewModel, soundPlaying) subscribeNext:^(NSNumber *x) {
        @strongify(self);
        if (self.viewModel.downloadState == SFDownloadStateDownloaded) {
            NSMutableArray *toolbarItems = [NSMutableArray array];
            [toolbarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
            
            BOOL showsControlButtons = [self.viewModel playingCurrentEpisode];
            if (showsControlButtons) {
                [toolbarItems addObject:rewindButton];
                [toolbarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
            }
            
            if ([x boolValue]) {
                [toolbarItems addObject:pauseButton];
            } else {
                [toolbarItems addObject:playButton];
            }
            [toolbarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
            
            if (showsControlButtons) {
                [toolbarItems addObject:fastForwardButton];
                [toolbarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
            }
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
    if (self.html.length == 0) {
        [self _viewTextContentWithRefreshing:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)_viewTextContentWithRefreshing:(BOOL)refreshing
{
    NSString *html = nil;
    if (!refreshing && self.textCacheDB == nil) {
        self.textCacheDB = [AppDelegate keyURLStringValueHTML];html = [self.textCacheDB objectForKey:[self.viewModel.episode.contentURLString sf_stringByEncryptingUsingMD5]];
    }
    if (html.length != 0) {
        self.html = html;
        [SFWaitingIndicator showLoading:YES inView:self.textView transparentBackground:NO identifier:@"loadingHTML"];
        self.updatingHTML = YES;
        [self _updateHtml];
    } else {
        @weakify(self);
        [self.viewModel.episodeDetailSignal subscribeNext:^(id x) {
            @strongify(self);
            self.html = x;
            [self.textCacheDB setObject:self.html forKey:[self.viewModel.episode.contentURLString sf_stringByEncryptingUsingMD5]];
            [SFWaitingIndicator showLoading:YES inView:self.textView transparentBackground:NO identifier:@"loadingHTML"];
            self.updatingHTML = YES;
            [self _updateHtml];
        } error:^(NSError *error) {
            
        }];
    }
}

- (void)_updateHtml
{
    CGFloat paddingTop = _playerStatusView.frame.size.height;
    [self.textView loadHTMLString:[_html stringByReplacingOccurrencesOfString:@"$paddingTop" withString:_playerStatusView.hidden ? @"0" : [NSString stringWithFormat:@"%.0f", paddingTop]] baseURL:nil];
}

- (void)_downloadButtonTapped:(UIBarButtonItem *)downloadBarButtonItem
{
    [_viewModel startDownload];
}

- (void)_downloadingIndicatorButtonTapped
{
    [UIActionSheet sf_actionSheetWithTitle:@"" completion:^(NSInteger buttonIndex, NSString *buttonTitle) {
        if ([buttonTitle isEqualToString:@"暂停"]) {
            [self.viewModel pauseDownload];
        } else if ([buttonTitle isEqualToString:@"重新下载"]) {
            [UIAlertView sf_alertWithTitle:@"温馨提示" message:@"确定要重新下载音频吗？" completion:^(NSInteger buttonIndex, NSString *buttonTitle) {
                if (buttonIndex != 0) {
                    [self.viewModel redownload];
                    [self.viewModel startDownload];
                }
            } cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        }
    } cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"暂停", @"重新下载", nil];
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

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *URLString = [[request URL] absoluteString];
    if ([URLString hasPrefix:@"esl://"]) {
        NSString *const kCommandPlaySub = @"esl://playSubWithTitle?";
        if ([URLString hasPrefix:kCommandPlaySub]) {
            NSString *subTitle = [URLString substringFromIndex:kCommandPlaySub.length];
            if (self.viewModel.downloadState == SFDownloadStateDownloaded) {
                [self.viewModel playSubWithTitle:[subTitle stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] HTML:self.html];
            } else {
                [UIAlertView sf_alertWithTitle:@"温馨提示" message:@"当前节目还没有下载完成" completion:^(NSInteger buttonIndex, NSString *buttonTitle) {
                    if (buttonIndex != 0) {
                        if (self.viewModel.downloadState == SFDownloadStateNotDowloaded) {
                            [self.viewModel startDownload];
                        } else if (self.viewModel.downloadState != SFDownloadStateDownloading) {
                            [self _retryButtonTapped];
                        }
                    }
                } cancelButtonTitle:self.viewModel.downloadState == SFDownloadStateDownloading ? @"确定" : @"取消" otherButtonTitles:self.viewModel.downloadState == SFDownloadStateDownloading ? nil : @"下载", nil];
            }
        }
        return NO;
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [webView sf_disableWebViewContextMenu];
    if (self.updatingHTML) {
        self.textView.alpha = .0f;
        [SFWaitingIndicator showLoading:NO inView:self.textView transparentBackground:NO identifier:@"loadingHTML"];
        [UIView animateWithDuration:.50f animations:^{
            self.textView.alpha = 1.0f;
        }];
        self.updatingHTML = NO;
    }
}

@end
