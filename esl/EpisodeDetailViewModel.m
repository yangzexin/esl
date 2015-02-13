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
#import "NSObject+SFRuntime.h"
#import "NSObject+SFObjectRepository.h"

#import "SFRepeatTimer.h"

#import "ESSoundDownloadManager.h"

#import "ESSoundPlayContext.h"

#import "NSString+SFAddition.h"

NSString *const ESEpisodeDidStartDownloadNotification = @"ESEpisodeDidStartDownloadNotification";

@interface EpisodeDetailViewModel ()

@property (nonatomic, strong) ESEpisode *episode;

@property (nonatomic, strong) RACSignal *episodeDetailSignal;

@property (nonatomic, strong) RACSignal *downloadSignal;

@property (nonatomic, assign, getter = isLoadingEpisodeDetail) BOOL loadingEpisodeDetail;

@property (nonatomic, assign) SFDownloadState downloadState;

@property (nonatomic, assign) float downloadPercent;

@property (nonatomic, assign) BOOL soundPlaying;
@property (nonatomic, assign) BOOL playingCurrentEpisode;

@property (nonatomic, strong) NSArray *subSoundTitles;
@property (nonatomic, strong) NSDictionary *keySubSoundTitleValueTime;

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
    [self sf_addRepositionSupportedObject:[SFRepeatTimer timerStartWithTimeInterval:0.50f tick:^{
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
        @weakify(self);
        self.episodeDetailSignal = [[[[[[NSURLConnection rac_sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_episode.contentURLString]]] map:^id(id value) {
            if (![value isKindOfClass:[NSError class]]) {
                @strongify(self);
                NSData *responseData = [value last];
                NSString *HTML = [[NSString alloc] initWithData:responseData encoding:NSWindowsCP1252StringEncoding];
                NSString *outReplacedHTML = nil;
                [self _getAudioIndexesWithHTML:HTML outReplacedHTML:&outReplacedHTML];
                
                if (outReplacedHTML.length != 0) {
                    HTML = outReplacedHTML;
                }
                
                value = HTML;
                
                NSString *beginMatching = @"class=\"podcast_table_home\"";
                NSString *endMatching = @"<a class=\"grayButton\"";
                NSInteger beginIndex = [HTML sf_find:beginMatching];
                if (beginIndex != -1) {
                    beginIndex += beginMatching.length + 1;
                    NSInteger endIndex = [HTML sf_find:endMatching fromIndex:beginIndex];
                    if (endIndex != -1) {
                        NSString *content = [HTML sf_substringWithBeginIndex:beginIndex endIndex:endIndex];
                        NSString *contentWrapper = @"<html><body><div style='font-family:Verdana;padding-top:$paddingTop;'>"\
                        "<div style=\"font-size:12pt;font-weight:bold;padding-bottom:10px;\">$title</div>"\
                        "<div>$content</div>"\
                        "</div></body></html>";
                        value = [contentWrapper stringByReplacingOccurrencesOfString:@"$content" withString:content.length == 0 ? @"" : content];
                        value = [value stringByReplacingOccurrencesOfString:@"$title" withString:self.episode.title.length == 0 ? @"" : self.episode.title];
                    }
                }
            }
            return value;
        }] catchTo:[RACSignal empty]] deliverOn:[RACScheduler mainThreadScheduler]] publish] autoconnect];
        
        self.loadingEpisodeDetail = YES;
        
        [self.episodeDetailSignal subscribeCompleted:^{
            @strongify(self);
            self.loadingEpisodeDetail = NO;
            self.episodeDetailSignal = nil;
        }];
    }
    return _episodeDetailSignal;
}

- (void)_getAudioIndexesWithHTML:(NSString *)HTML outReplacedHTML:(NSString **)outReplacedHTML
{
    NSString *matching = @"Audio Index:";
    NSInteger beginIndex = [HTML sf_find:matching];
    if (beginIndex != -1) {
        NSInteger endIndex = [HTML sf_find:@"</span>" fromIndex:beginIndex + matching.length];
        NSString *innerText = [HTML sf_substringWithBeginIndex:beginIndex + matching.length endIndex:endIndex];
        
        if ([innerText sf_find:@"<br>"] != -1) {
            NSArray *subSoundTitleStrings = [innerText componentsSeparatedByString:@"<br>"];
            NSMutableArray *subSoundTitles = [NSMutableArray array];
            for (NSString *subSoundTitleString in subSoundTitleStrings) {
                NSString *tmpSubSoundTitleString = [subSoundTitleString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if (tmpSubSoundTitleString.length != 0) {
                    NSInteger bracketIndex = [tmpSubSoundTitleString sf_find:@":"];
                    if (bracketIndex != -1) {
                        NSString *subSoundTitle = [tmpSubSoundTitleString substringToIndex:bracketIndex];
                        [subSoundTitles addObject:subSoundTitle];
                    }
                }
            }
            self.subSoundTitles = subSoundTitles;
        }
        
        if (self.subSoundTitles.count != 0) {
            NSMutableDictionary *keySubSoundTitleValueTime = [NSMutableDictionary dictionary];
            
            for (NSString *subSoundTitle in self.subSoundTitles) {
                [keySubSoundTitleValueTime setObject:@([self _getAudioIndexTimeWithHTML:innerText prefix:[NSString stringWithFormat:@"%@:", subSoundTitle]])
                                              forKey:subSoundTitle];
            }
            
            self.keySubSoundTitleValueTime = keySubSoundTitleValueTime;
            
            NSMutableString *replacedHTML = [NSMutableString stringWithFormat:@"<!-- %@ -->", innerText];
            for (NSString *subSoundTitle in self.subSoundTitles) {
                [replacedHTML appendFormat:@"<div>"\
                 "<a style=\"color:blue;\" href=\"javascript:void(0);\" onclick=\"javascript:window.location.href='esl://playSubWithTitle?%@';\">"\
                 "<span style=\"display:block;font-size:12pt;padding-top:10px;padding-bottom:10px;\">%@</span>"\
                 "</a>"\
                 "</div>",
                 [subSoundTitle stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], subSoundTitle];
            }
            
            if (outReplacedHTML) {
                *outReplacedHTML = [HTML stringByReplacingOccurrencesOfString:innerText withString:replacedHTML];
            }
        }
    }
}

- (double)_getAudioIndexTimeWithHTML:(NSString *)HTML prefix:(NSString *)prefix
{
    double time = 0;
    
    NSInteger beginIndex = [HTML sf_find:prefix];
    if (beginIndex != -1) {
        NSInteger endIndex = [HTML sf_find:@"<br>" fromIndex:beginIndex + prefix.length];
        if (endIndex != -1) {
            NSString *timeDescription = [HTML sf_substringWithBeginIndex:beginIndex + prefix.length endIndex:endIndex];
            NSArray *timeAttrs = [timeDescription componentsSeparatedByString:@":"];
            if (timeAttrs.count == 2) {
                NSInteger minute = [[timeAttrs objectAtIndex:0] integerValue];
                NSInteger second = [[timeAttrs objectAtIndex:1] integerValue];
                time = minute * 60 + second;
            }
        }
    }
    
    return time;
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
        [self sf_addRepositionSupportedObject:[SFRepeatTimer timerStartWithTimeInterval:0.50f tick:^{
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
            [self sf_removeRepositionSupportedObjectWithIdentifier:@"CheckDownloadStateTimer"];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ESEpisodeDidStartDownloadNotification object:self.episode];
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

- (void)rewind
{
    [[ESSoundPlayContext sharedContext] setCurrentTime:[[ESSoundPlayContext sharedContext] currentTime] - 5];
}

- (void)fastForward
{
    [[ESSoundPlayContext sharedContext] setCurrentTime:[[ESSoundPlayContext sharedContext] currentTime] + 5];
}

- (void)playSubWithTitle:(NSString *)subTitle HTML:(NSString *)HTML
{
    if (self.keySubSoundTitleValueTime.count == 0) {
        [self _getAudioIndexesWithHTML:HTML outReplacedHTML:NULL];
    }
    if (self.keySubSoundTitleValueTime.count != 0) {
        double time = [[self.keySubSoundTitleValueTime objectForKey:subTitle] doubleValue];
        if (![self soundPlaying]) {
            [self playSound];
        }
        [self jumpToTime:time];
    }
}

@end
