//
//  ESViewEpisodeController.m
//  esl
//
//  Created by yangzexin on 10/27/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESViewEpisodeController.h"

#import "ESEpisode.h"
#import "ESSoundPlayContext.h"
#import "PlayerStatusView.h"
#import "ESAutoHeightWebView.h"
#import "ESHighlightManager.h"

@interface ESViewEpisodeController () <ESProgressTracker, PlayerStatusViewDelegate, ESAutoHeightWebViewDelegate>

@property (nonatomic, strong) ESEpisode *episode;
@property (nonatomic, strong) UIBarButtonItem *playControlBarButtonItem;
@property (nonatomic, strong) PlayerStatusView *playerStatusView;
@property (nonatomic, strong) UIView *fakeStatusView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) ESAutoHeightWebView *introdutionWebView;
@property (nonatomic, assign, readonly) BOOL playing;
@property (nonatomic, assign, readonly) BOOL paused;
@property (nonatomic, assign) BOOL downloading;
@property (nonatomic, assign) BOOL needHideToolbar;
@property (nonatomic, strong) id<ESHighlightManager> highlightManager;

@end

@implementation ESViewEpisodeController

+ (instancetype)viewEpisodeControllerWithEpisode:(ESEpisode *)episode
{
    ESViewEpisodeController *controller = [ESViewEpisodeController new];
    controller.episode = episode;
    return controller;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView
{
    [super loadView];
    self.title = @"Episode";
    self.bounces = YES;
    
    self.playerStatusView = [[PlayerStatusView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    self.playerStatusView.delegate = self;
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width - 20, 0)];
    self.titleLabel.text = self.episode.title;
    self.titleLabel.font = [UIFont systemFontOfSize:20.0f];
    [self.titleLabel sf_fitHeightByTextUsingCurrentFontWithMaxHeight:0];
    [self addView:self.titleLabel];

    self.introdutionWebView = [[ESAutoHeightWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 7)];
    self.introdutionWebView.delegate = self;
    __weak typeof(self) weakSelf = self;
    [self.introdutionWebView loadWitHTMLString:self.episode.formattedIntrodution autoFitHeightCompletion:^(CGFloat height) {
        weakSelf.introdutionWebView.frame = CGRectMake(0, 0, weakSelf.view.frame.size.width, height);
        [weakSelf reloadView:weakSelf.introdutionWebView animated:YES];
    }];
    [self addView:self.introdutionWebView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.navigationController.toolbarHidden) {
        self.needHideToolbar = YES;
        [self.navigationController setToolbarHidden:NO animated:YES];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.highlightManager = [ESSharedHighlightManager highlightManagerWithIdentifier:self.episode.uid];
    
    if ([[ESSoundPlayContext sharedContext].playingEpisode.uid isEqualToString:self.episode.uid]) {
        self.playerStatusView.totalTime = [ESSoundPlayContext sharedContext].duration;
        self.playerStatusView.currentTime = [ESSoundPlayContext sharedContext].currentTime;
        [self _updateUIStates];
        [self _showPlayStatusViewAnimated:NO];
        
        __weak typeof(self) weakSelf = self;
        [[ESSoundPlayContext sharedContext] setPlayingBlock:^(NSTimeInterval currentTime, NSTimeInterval duration) {
            [weakSelf _playingWithCurrentTime:currentTime duration:duration];
        }];
        [[ESSoundPlayContext sharedContext] setPlayFinishedBlock:^(BOOL success, NSError *error){
            [weakSelf _playFinished];
        }];
    } else {
        [self _updateUIStatesAnimated:self.needHideToolbar == NO];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_soundPlayDidPauseNotification:) name:ESSoundPlayDidPauseNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_soundPlayDidResumeNotification:) name:ESSoundPlayDidResumeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_soundPlayStateDidChangeNotification:) name:ESSoundPlayStateDidChangeNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.needHideToolbar) {
        [self.navigationController setToolbarHidden:YES animated:YES];
    }
}

- (void)progressUpdatingWithPercent:(float)percent
{
    self.playControlBarButtonItem.title = [NSString stringWithFormat:@" %.0f%% ", percent * 100];
}

- (void)_updateUIStatesAnimated:(BOOL)animated
{
    NSMutableArray *toolbarItems = [NSMutableArray array];
    
    [toolbarItems addObject:[SFBlockedBarButtonItem blockedBarButtonItemWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace eventHandler:nil]];
    if (self.playing == NO
        || self.paused == YES
        || (self.playing == YES && ![[ESSoundPlayContext sharedContext].playingEpisode.uid isEqualToString:self.episode.uid])) {
        __weak typeof(self) weakSelf = self;
        self.playControlBarButtonItem = [SFBlockedBarButtonItem blockedBarButtonItemWithBarButtonSystemItem:UIBarButtonSystemItemPlay eventHandler:^{
            [weakSelf _playControlBarButtonItemTapped];
        }];
    } else {
        __weak typeof(self) weakSelf = self;
        self.playControlBarButtonItem = [SFBlockedBarButtonItem blockedBarButtonItemWithBarButtonSystemItem:UIBarButtonSystemItemPause eventHandler:^{
            [weakSelf _playControlBarButtonItemTapped];
        }];
    }
    if (self.downloading) {
        __weak typeof(self) weakSelf = self;
        self.playControlBarButtonItem = [SFBlockedBarButtonItem blockedBarButtonItemWithTitle:@"0%" eventHandler:^{
            [UIAlertView sf_alertWithTitle:@"Download" message:@"r u sure to cancel this downloading?" completion:^(NSInteger buttonIndex, NSString *buttonTitle) {
                if (buttonIndex != 0) {
                    [weakSelf stopRequestingServiceWithIdnentifier:@"download_sound"];
                    weakSelf.downloading = NO;
                    [weakSelf _updateUIStates];
                }
            } cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        }];
        self.playControlBarButtonItem.style = UIBarButtonItemStyleDone;
    }
    self.playerStatusView.userInteractionEnabled = self.playing;
    [toolbarItems addObject:self.playControlBarButtonItem];
    [toolbarItems addObject:[SFBlockedBarButtonItem blockedBarButtonItemWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace eventHandler:nil]];
    
    [self setToolbarItems:toolbarItems animated:animated];
}

- (void)_updateUIStates
{
    [self _updateUIStatesAnimated:NO];
}

- (void)_showPlayStatusViewAnimated:(BOOL)animated
{
    self.fakeStatusView = [[UIView alloc] initWithFrame:self.playerStatusView.bounds];
    [self insertView:self.fakeStatusView atIndex:0];
    
    CGRect tmpRect = self.playerStatusView.frame;
    tmpRect.origin.y = - self.playerStatusView.frame.size.height;
    self.playerStatusView.frame = tmpRect;
    [self.view addSubview:self.playerStatusView];
    [UIView animateWithDuration:animated ? 0.25f : 0.0f animations:^{
        CGRect tmpRect = self.playerStatusView.frame;
        tmpRect.origin.y = [self startYPositionOfView];
        self.playerStatusView.frame = tmpRect;
    }];
}

- (void)_hidePlayStatusView
{
    [self removeView:self.fakeStatusView animated:YES];
    
    [UIView animateWithDuration:0.25f animations:^{
        CGRect tmpRect = self.playerStatusView.frame;
        tmpRect.origin.y = - self.playerStatusView.frame.size.height;
        self.playerStatusView.frame = tmpRect;
    } completion:^(BOOL finished) {
        [self.playerStatusView removeFromSuperview];
    }];
}

- (void)_playFinished
{
    [self _updateUIStates];
    [self _hidePlayStatusView];
}

- (void)_playingWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration
{
    self.playerStatusView.currentTime = currentTime;
    self.playerStatusView.totalTime = duration;
}

- (void)_playStarted
{
    [self _showPlayStatusViewAnimated:YES];
    [self _updateUIStates];
}

- (void)_playWithSoundPath:(NSString *)soundPath
{
    __weak typeof(self) weakSelf = self;
    [[ESSoundPlayContext sharedContext] setPlayStartedBlock:^{
        [weakSelf _playStarted];
    }];
    [[ESSoundPlayContext sharedContext] setPlayingBlock:^(NSTimeInterval currentTime, NSTimeInterval duration) {
        [weakSelf _playingWithCurrentTime:currentTime duration:duration];
    }];
    [[ESSoundPlayContext sharedContext] playWithEpisode:self.episode soundPath:soundPath finishBlock:^(BOOL success, NSError *error){
        [weakSelf _playFinished];
        if (error) {
            [UIAlertView sf_alertWithTitle:@"Error" message:@"It seems error encountered when playing sound, would u want to redownload this sound?" completion:^(NSInteger buttonIndex, NSString *buttonTitle) {
                if (buttonIndex != 0) {
                    [weakSelf _downloadSoundAndPlay:YES];
                }
            } cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        }
    }];
}

- (void)_togglePauseResume
{
    if (self.paused) {
        [[ESSoundPlayContext sharedContext] resume];
    } else {
        [[ESSoundPlayContext sharedContext] pause];
    }
    [self _updateUIStates];
}

- (void)_downloadSoundAndPlay:(BOOL)playWhenDownloadFinished
{
    self.downloading = YES;
    [self _updateUIStates];
    id<ESService> downloadSoundService = [self.episodeManager soundPathWithEpisode:self.episode progressTracker:self];
    __weak typeof(self) weakSelf = self;
    [self requestService:downloadSoundService identifier:@"download_sound" completion:^(id resultObject, NSError *error) {
        weakSelf.downloading = NO;
        if (error != nil) {
            [UIAlertView sf_alertWithTitle:@"Download" message:[NSString stringWithFormat:@"Download failed:%@", error.localizedDescription] completion:^(NSInteger buttonIndex, NSString *buttonTitle) {
                if (buttonIndex != 0) {
                    [weakSelf _downloadSoundAndPlay:playWhenDownloadFinished];
                } else {
                    [weakSelf _updateUIStates];
                }
            } cancelButtonTitle:@"Cancel" otherButtonTitles:@"Retry", nil];
        } else {
            [weakSelf _updateUIStates];
            if (playWhenDownloadFinished) {
                [UIAlertView sf_alertWithTitle:@"Download" message:@"Download finished, would u like to play now?" completion:^(NSInteger buttonIndex, NSString *buttonTitle) {
                    if (buttonIndex != 0) {
                        [weakSelf _playWithSoundPath:resultObject];
                    }
                } cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
            }
        }
    }];
}

- (void)_playControlBarButtonItemTapped
{
    if (self.playing == NO
        || (self.playing == YES && ![[ESSoundPlayContext sharedContext].playingEpisode.uid isEqualToString:self.episode.uid])) {
        if ([self.episodeManager isEpisodeDownloaded:self.episode]) {
            id<ESService> downloadSoundService = [self.episodeManager soundPathWithEpisode:self.episode];
            __weak typeof(self) weakSelf = self;
            [self requestService:downloadSoundService identifier:@"download_sound" completion:^(id resultObject, NSError *error) {
                [weakSelf _playWithSoundPath:resultObject];
            }];
        } else {
            [self _downloadSoundAndPlay:YES];
        }
    } else {
        [self _togglePauseResume];
    }
}

- (void)_soundPlayDidPauseNotification:(NSNotification *)note
{
    [self _updateUIStates];
}

- (void)_soundPlayDidResumeNotification:(NSNotification *)note
{
    [self _updateUIStates];
}

- (void)_soundPlayStateDidChangeNotification:(NSNotification *)note
{
    [self _updateUIStates];
}

- (BOOL)paused
{
    return [[ESSoundPlayContext sharedContext] isPaused];
}

- (BOOL)playing
{
    return [[ESSoundPlayContext sharedContext] isPlaying];
}

#pragma mark - ESAutoHeightWebViewDelegate
- (void)autoHeightWebView:(ESAutoHeightWebView *)webView highlightingText:(NSString *)text
{
    ESHighlight *highlight = [ESHighlight new];
    highlight.text = text;
    
    [self.highlightManager addHighlight:highlight];
}

- (void)autoHeightWebView:(ESAutoHeightWebView *)webView unhighlightingText:(NSString *)text
{
}

- (BOOL)autoHeightWebView:(ESAutoHeightWebView *)web shouldUnhightText:(NSString *)text
{
    return NO;
}

#pragma mark - PlayStatusViewDelegate
- (void)playerStatusView:(PlayerStatusView *)playerStatusView didChangeToNewPosition:(float)value
{
    [ESSoundPlayContext sharedContext].currentTime = value;
}

@end
