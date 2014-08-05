//
//  EpisodeDetailViewModel.m
//  esl
//
//  Created by yangzexin on 4/3/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "EpisodeDetailViewModel.h"

#import "ESEpisode.h"

#import "NSString+SFJavaLikeStringHandle.h"
#import "NSObject+SFAddition.h"
#import "NSObject+SFObjectRepository.h"

#import "SFRepeatTimer.h"

#import "ESSoundDownloadManager.h"

#import "ESSoundPlayContext.h"

@interface EpisodeDetailViewModel ()

@property (nonatomic, strong) ESEpisode *episode;

@property (nonatomic, strong) RACSignal *episodeDetailSignal;

@property (nonatomic, strong) RACSignal *downloadSignal;

@property (nonatomic, assign, getter = isLoadingEpisodeDetail) BOOL loadingEpisodeDetail;

@property (nonatomic, assign) SFDownloadState downloadState;

@property (nonatomic, assign) float downloadPercent;

@property (nonatomic, assign) BOOL soundPlaying;
@property (nonatomic, assign) BOOL playingCurrentEpisode;

@end

@implementation EpisodeDetailViewModel

+ (instancetype)viewModelWithEpisode:(ESEpisode *)episode
{
    EpisodeDetailViewModel *viewModel = [[EpisodeDetailViewModel alloc] initWithEpisode:episode];
    
    return viewModel;
}

- (id)initWithEpisode:(ESEpisode *)episode
{
    self = [super init];
    
    self.episode = episode;
    
    @weakify(self);
    [self addRepositionSupportedObject:[SFRepeatTimer timerStartWithTimeInterval:0.50f tick:^{
        @strongify(self);
        [self _updateStates];
    }] identifier:@"downloadPercentRefreshTimer"];
    
    return self;
}

- (void)_updateStates
{
    self.downloadState = [[ESSoundDownloadManager sharedManager] stateForEpisode:self.episode];
    self.soundPlaying = [[ESSoundPlayContext sharedContext] isPlaying] && ![[ESSoundPlayContext sharedContext] isPaused] && [[ESSoundPlayContext sharedContext].playingEpisode.uid isEqualToString:self.episode.uid];
    self.playingCurrentEpisode = [[[ESSoundPlayContext sharedContext] playingEpisode].uid isEqualToString:_episode.uid];
    self.downloadPercent = [[ESSoundDownloadManager sharedManager] downloadedPercentForEpisode:self.episode];
    self.currentTime = [[ESSoundPlayContext sharedContext] currentTime];
}

- (RACSignal *)episodeDetailSignal
{
    if (_episodeDetailSignal == nil) {
        self.episodeDetailSignal = [[[[[[NSURLConnection rac_sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_episode.contentURLString]]] map:^id(id value) {
            if (![value isKindOfClass:[NSError class]]) {
                NSData *responseData = [value last];
                NSString *HTML = [[NSString alloc] initWithData:responseData encoding:NSWindowsCP1252StringEncoding];
                
                value = HTML;
                
                NSString *beginMatching = @"class=\"podcast_table_home\"";
                NSString *endMatching = @"<a class=\"grayButton\"";
                NSInteger beginIndex = [HTML find:beginMatching];
                if (beginIndex != -1) {
                    beginIndex += beginMatching.length + 1;
                    NSInteger endIndex = [HTML find:endMatching fromIndex:beginIndex];
                    if (endIndex != -1) {
                        NSString *content = [HTML substringWithBeginIndex:beginIndex endIndex:endIndex];
                        NSString *contentWrapper = @"<html><body><div style='font-family:Verdana;padding-top:$paddingTop;'>$content</div></body></html>";
                        value = [contentWrapper stringByReplacingOccurrencesOfString:@"$content" withString:content];
                    }
                }
            }
            return value;
        }] catchTo:[RACSignal empty]] deliverOn:[RACScheduler mainThreadScheduler]] publish] autoconnect];
        
        self.loadingEpisodeDetail = YES;
        
        @weakify(self);
        [self.episodeDetailSignal subscribeCompleted:^{
            @strongify(self);
            self.loadingEpisodeDetail = NO;
            self.episodeDetailSignal = nil;
        }];
    }
    return _episodeDetailSignal;
}

- (RACSignal *)downloadSignal
{
    @weakify(self);
    _downloadSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        if ([[ESSoundDownloadManager sharedManager] stateForEpisode:self.episode] != SFDownloadStateDownloading) {
            [[ESSoundDownloadManager sharedManager] downloadEpisode:self.episode];
        }
        @weakify(self);
        [self addRepositionSupportedObject:[SFRepeatTimer timerStartWithTimeInterval:0.50f tick:^{
            @strongify(self);
            if ([[ESSoundDownloadManager sharedManager] stateForEpisode:self.episode] == SFDownloadStateDownloaded) {
                [subscriber sendNext:[[ESSoundDownloadManager sharedManager] soundFilePathForEpisode:self.episode]];
                [subscriber sendCompleted];
            } else if ([[ESSoundDownloadManager sharedManager] stateForEpisode:self.episode] == SFDownloadStateErrored) {
                [subscriber sendError:[[ESSoundDownloadManager sharedManager] errorForEpisode:self.episode]];
                [subscriber sendCompleted];
            }
        }] identifier:@"CheckDownloadStateTimer"];
        return [RACDisposable disposableWithBlock:^{
            @strongify(self);
            [self removeRepositionSupportedObjectWithIdentifier:@"CheckDownloadStateTimer"];
        }];
    }];
    return _downloadSignal;
}

- (void)playSound
{
    self.soundPlaying = YES;
    @weakify(self);
    if ([[ESSoundPlayContext sharedContext].playingEpisode.uid isEqual:self.episode.uid]) {
        [[ESSoundPlayContext sharedContext] resume];
    } else {
        [[ESSoundPlayContext sharedContext] playWithEpisode:self.episode soundPath:[[ESSoundDownloadManager sharedManager] soundFilePathForEpisode:self.episode] finishBlock:^(BOOL success, NSError *error) {
            @strongify(self);
            self.soundPlaying = NO;
        }];
    }
}

- (void)pauseSound
{
    [[ESSoundPlayContext sharedContext] pause];
    self.soundPlaying = NO;
}

- (void)startDownload
{
    [self.downloadSignal subscribeNext:^(id x) {
        
    }];
}

- (void)redownload
{
    [[ESSoundDownloadManager sharedManager] removeEpisode:_episode];
}

- (void)pauseDownload
{
    [[ESSoundDownloadManager sharedManager] pauseDownloadingEpisode:_episode];
}

- (void)jumpToTime:(NSTimeInterval)time
{
    [[ESSoundPlayContext sharedContext] setCurrentTime:time];
}

- (NSTimeInterval)totalTime
{
    return [[ESSoundPlayContext sharedContext] duration];
}

@end
