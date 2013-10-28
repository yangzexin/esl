//
//  ESViewEpisodeController.m
//  esl
//
//  Created by yangzexin on 10/27/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESViewEpisodeController.h"
#import "ESEpisode.h"
#import "SFBlockedBarButtonItem.h"
#import "UILabel+SFAddition.h"
#import "ESEpisodeManager.h"
#import "SFDialogTools.h"
#import "ESSoundPlayContext.h"
#import "PlayerStatusView.h"

@interface ESViewEpisodeController () <ESProgressTracker, PlayerStatusViewDelegate>

@property (nonatomic, strong) ESEpisode *episode;
@property (nonatomic, strong) UIBarButtonItem *playControlBarButtonItem;
@property (nonatomic, strong) PlayerStatusView *playerStatusView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *introdutionLabel;
@property (nonatomic, assign) BOOL playing;
@property (nonatomic, assign) BOOL paused;
@property (nonatomic, assign) BOOL downloading;
@property (nonatomic, assign) BOOL needHideToolbar;

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
    self.bounces = NO;
    
    self.playerStatusView = [[PlayerStatusView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    self.playerStatusView.delegate = self;
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width - 20, 0)];
    self.titleLabel.text = self.episode.title;
    self.titleLabel.font = [UIFont systemFontOfSize:14.0f];
    [self.titleLabel fitHeightByTextUsingCurrentFontWithMaxHeight:0];
    [self addView:self.titleLabel];
    
    self.introdutionLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width - 20, 0)];
    self.introdutionLabel.text = [NSString stringWithFormat:@"%@\n%@", self.episode.date, self.episode.introdution];
    self.introdutionLabel.font = [UIFont systemFontOfSize:12.0f];
    [self.introdutionLabel fitHeightByTextUsingCurrentFontWithMaxHeight:0];
    [self addView:self.introdutionLabel];
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
    if ([[ESSoundPlayContext sharedContext].playingEpisode.uid isEqualToString:self.episode.uid]) {
        self.playing = [ESSoundPlayContext sharedContext].isPlaying;
        self.paused = [ESSoundPlayContext sharedContext].isPaused;
        self.playerStatusView.totalTime = [ESSoundPlayContext sharedContext].duration;
        self.playerStatusView.currentTime = [ESSoundPlayContext sharedContext].currentTime;
        [self _updateUIStates];
        [self insertView:self.playerStatusView atIndex:0];
        
        __weak typeof(self) weakSelf = self;
        [[ESSoundPlayContext sharedContext] setPlayingBlock:^(NSTimeInterval currentTime, NSTimeInterval duration) {
            [weakSelf _playingWithCurrentTime:currentTime duration:duration];
        }];
        [[ESSoundPlayContext sharedContext] setPlayFinishBlock:^{
            [weakSelf _playFinished];
        }];
    } else {
        [self _updateUIStatesAnimated:self.needHideToolbar == NO];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_soundPlayDidPauseNotification:) name:ESSoundPlayDidPauseNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_soundPlayDidResumeNotification:) name:ESSoundPlayDidResumeNotification object:nil];
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
    if (self.playing == NO || self.paused == YES) {
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
            [SFDialogTools alertWithTitle:@"Download" message:@"r u sure to cancel this downloading?" completion:^(NSInteger buttonIndex, NSString *buttonTitle) {
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

- (void)_playFinished
{
    self.playing = NO;
    self.paused = NO;
    [self _updateUIStates];
    [self removeView:self.playerStatusView animated:YES];
}

- (void)_playingWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration
{
    self.playerStatusView.currentTime = currentTime;
    self.playerStatusView.totalTime = duration;
}

- (void)_playWithSoundPath:(NSString *)soundPath
{
    __weak typeof(self) weakSelf = self;
    [[ESSoundPlayContext sharedContext] setPlayingBlock:^(NSTimeInterval currentTime, NSTimeInterval duration) {
        [weakSelf _playingWithCurrentTime:currentTime duration:duration];
    }];
    [[ESSoundPlayContext sharedContext] playWithEpisode:self.episode soundPath:soundPath finishBlock:^{
        [weakSelf _playFinished];
    }];
    [self insertView:self.playerStatusView atIndex:0 animated:YES];
    self.playing = YES;
    self.paused = NO;
    [self _updateUIStates];
}

- (void)_togglePauseResume
{
    if (self.paused) {
        [[ESSoundPlayContext sharedContext] resume];
    } else {
        [[ESSoundPlayContext sharedContext] pause];
    }
    self.paused = !self.paused;
    [self _updateUIStates];
}

- (void)_playControlBarButtonItemTapped
{
    if (self.playing == NO) {
        if ([[ESEpisodeManager sharedManager] isEpisodeDownloaded:self.episode]) {
            id<ESService> downloadSoundService = [[ESEpisodeManager sharedManager] cachedSoundWithEpisode:self.episode];
            __weak typeof(self) weakSelf = self;
            [self requestService:downloadSoundService identifier:@"download_sound" completion:^(id resultObject, NSError *error) {
                [weakSelf _playWithSoundPath:resultObject];
            }];
        } else {
            self.downloading = YES;
            [self _updateUIStates];
            id<ESService> downloadSoundService = [[ESEpisodeManager sharedManager] downloadSoundWithEpisode:self.episode progressTracker:self];
            __weak typeof(self) weakSelf = self;
            [self requestService:downloadSoundService identifier:@"download_sound" completion:^(id resultObject, NSError *error) {
                weakSelf.downloading = NO;
                if (error != nil) {
                    [SFDialogTools alertWithTitle:@"Download" message:@"Download failed" completion:^(NSInteger buttonIndex, NSString *buttonTitle) {
                        if (buttonIndex != 0) {
                            [weakSelf _playControlBarButtonItemTapped];
                        } else {
                            [weakSelf _updateUIStates];
                        }
                    } cancelButtonTitle:@"Cancel" otherButtonTitles:@"Retry", nil];
                } else {
                    [weakSelf _updateUIStates];
                    [weakSelf _playWithSoundPath:resultObject];
                }
            }];
        }
    } else {
        [self _togglePauseResume];
    }
}

- (void)_soundPlayDidPauseNotification:(NSNotification *)note
{
    self.paused = YES;
    [self _updateUIStates];
}

- (void)_soundPlayDidResumeNotification:(NSNotification *)note
{
    self.paused = NO;
    [self _updateUIStates];
}

#pragma mark - PlayStatusViewDelegate
- (void)playerStatusView:(PlayerStatusView *)playerStatusView didChangeToNewPosition:(float)value
{
    [ESSoundPlayContext sharedContext].currentTime = value;
}

@end
