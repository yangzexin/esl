//
//  ESEpisodeService.m
//  esl
//
//  Created by yangzexin on 10/26/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESEpisodeService.h"
#import "ESServiceSession.h"
#import "ESHTTPRequest.h"
#import "SFSharedCache.h"
#import "NSString+SFJavaLikeStringHandle.h"
#import "ESEpisode.h"
#import "NSString+SFAddition.h"
#import "SFBuildInCacheFilters.h"

NSString *ESEpisodeDidUpdateNotification = @"ESEpisodeDidUpdateNotification";
NSString *ESBackgroundUpdateEpisodeDidFinishNotification = @"ESBackgroundUpdateEpisodeDidFinishNotification";

NSString *kEpisodesListURLString = @"http://www.eslpod.com/website/show_all.php";
NSString *kEpisodesContentPrefixURLString = @"http://www.eslpod.com/website/";

@interface ESEpisodeService ()

@property (nonatomic, assign) BOOL executing;
@property (nonatomic, copy) ESServiceCompletion completion;
@property (nonatomic, strong) ESServiceSession *session;

@end

@implementation ESEpisodeService

- (void)dealloc
{
    [_session cancel];
}

- (id)init
{
    self = [super init];
    
    _useCache = YES;
    
    return self;
}

- (void)requestWithCompletion:(ESServiceCompletion)completion
{
    [self cancel];
    self.completion = completion;
    self.executing = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *_cachedHTML = nil;
        if (self.useCache && (_cachedHTML = [self _cachedData]) && _cachedHTML.length != 0) {
            NSArray *episodes = [self _analyzeHTML:_cachedHTML];
            [self _updateEpisodesBackground];
            [self _notifyFinishWithEpisodes:episodes error:nil];
        } else {
            __weak typeof(self) weakSelf = self;
            [self _requestEpisodesWithCompletion:^(id resultObject, NSError *error) {
                [weakSelf _notifyFinishWithEpisodes:resultObject error:error];
            }];
        }
    });
}

- (void)_storeCacheData:(NSString *)data
{
    [[SFSharedCache sharedFileCache] storeCacheWithIdentifier:@"episodes" string:data];
}

- (NSString *)_cachedData
{
    return [[SFSharedCache sharedFileCache] cachedStringWithIdentifier:@"episodes" filter:[SFBuildInCacheFilters foreverCacheFilter]];
}

- (void)_updateEpisodesBackground
{
    [self _requestEpisodesWithCompletion:^(id resultObject, NSError *error) {
        NSArray *episodes = resultObject;
        if (episodes.count != 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ESEpisodeDidUpdateNotification object:episodes];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:ESBackgroundUpdateEpisodeDidFinishNotification object:nil];
    }];
}

- (void)_requestEpisodesWithCompletion:(ESServiceCompletion)completion
{
    ESHTTPRequest *request = [ESHTTPRequest requestWithURLString:[NSString stringWithFormat:@"%@?low_rec=%d", kEpisodesListURLString, self.pageIndex * [self pageSize]]
                                                     useHTTPPost:NO];
    __weak typeof(self) weakSelf = self;
    [request setResponseDataWrapper:^id(NSData *data) {
        NSString *string = [[NSString alloc] initWithData:data encoding:NSWindowsCP1252StringEncoding];
        [weakSelf _storeCacheData:string];
        return string;
    }];
    self.session = [ESServiceSession sessionWithRequestProxy:request responseProcessor:^id(id response, NSError *__autoreleasing *error) {
        return [weakSelf _analyzeHTML:response];
    }];
    [self.session requestWithCompletion:^(id resultObject, NSError *error) {
        completion(resultObject, error);
    }];
}

- (NSArray *)_analyzeHTML:(NSString *)HTML
{
    NSString *responseString = HTML;
    NSString *const matching = @"<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\" class=\"podcast_table_home\">";
    NSString *const bottomMatching = @"</table>";
    NSInteger beginIndex = -1;
    NSInteger endIndex = 0;
    
    NSMutableArray *episodes = [NSMutableArray array];
    while ((beginIndex = [responseString sf_find:matching fromIndex:endIndex]) != -1
           && (endIndex = [responseString sf_find:bottomMatching fromIndex:beginIndex + matching.length]) != -1) {
        NSInteger currentIndex = beginIndex += matching.length;
        
        ESEpisode *episode = [ESEpisode new];
        
        NSString *const dateMatching = @"<span class=\"date-header\">";
        NSString *const dateBottomMatching = @"</span><br>";
        NSInteger dateBeginIndex = [responseString sf_find:dateMatching fromIndex:currentIndex];
        if (dateBeginIndex != -1) {
            dateBeginIndex += dateMatching.length;
            NSInteger dateEndIndex = [responseString sf_find:dateBottomMatching fromIndex:dateBeginIndex];
            NSString *date = [responseString sf_substringWithBeginIndex:dateBeginIndex endIndex:dateEndIndex];
            date = [date stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            episode.date = date;
            currentIndex = dateEndIndex;
        }
        
        NSString *const podcastDetailPageMatching = @"show_podcast.php?";
        NSInteger podcastDetailPageIndex = [responseString sf_find:podcastDetailPageMatching fromIndex:currentIndex];
        if (podcastDetailPageIndex != -1) {
            NSInteger podcastDetailPageEndIndex = [responseString sf_find:@"\"" fromIndex:podcastDetailPageIndex];
            if (podcastDetailPageEndIndex != -1) {
                NSString *podcastDetailPageLink = [responseString sf_substringWithBeginIndex:podcastDetailPageIndex endIndex:podcastDetailPageEndIndex];
                episode.contentURLString = [NSString stringWithFormat:@"%@%@", kEpisodesContentPrefixURLString, podcastDetailPageLink];
                currentIndex = podcastDetailPageEndIndex;
            }
        }
        
        NSString *const titleMatching = @"class=\"podcast_title\">";
        NSString *const titleBottomMatching = @"</a>";
        NSInteger titleBeginIndex = [responseString sf_find:titleMatching fromIndex:currentIndex];
        if (titleBeginIndex != -1) {
            titleBeginIndex += titleMatching.length;
            NSInteger titleEndIndex = [responseString sf_find:titleBottomMatching fromIndex:titleBeginIndex];
            NSString *title = [responseString sf_substringWithBeginIndex:titleBeginIndex endIndex:titleEndIndex];
            title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            episode.title = title;
            currentIndex = titleEndIndex;
        }
        
        NSString *const soundURLStringMatching = @"Download Podcast";
        NSInteger downloadStringIndex = [responseString sf_find:soundURLStringMatching fromIndex:currentIndex];
        if (downloadStringIndex != -1) {
            NSInteger aLinkBeginIndex = [responseString sf_find:@"<a" fromIndex:downloadStringIndex reverse:YES];
            NSInteger aLinkEndIndex = [responseString sf_find:@">" fromIndex:aLinkBeginIndex];
            NSString *aLinkInnerHTML = [responseString sf_substringWithBeginIndex:aLinkBeginIndex endIndex:aLinkEndIndex];
            
            NSString *const hrefMatching = @"href=\"";
            NSInteger hrefBeginIndex = [aLinkInnerHTML sf_find:hrefMatching];
            if (hrefBeginIndex != -1) {
                hrefBeginIndex += hrefMatching.length;
                NSInteger hrefEndIndex = [aLinkInnerHTML sf_find:@"\"" fromIndex:hrefBeginIndex];
                NSString *soundURLString = [aLinkInnerHTML sf_substringWithBeginIndex:hrefBeginIndex endIndex:hrefEndIndex];
                episode.soundURLString = soundURLString;
            }
            currentIndex = downloadStringIndex;
        }
        
        NSString *const episodeDescriptionMatching = @"</span>";
        NSInteger episodeDescriptionBeginIndex = [responseString sf_find:episodeDescriptionMatching fromIndex:currentIndex];
        if (episodeDescriptionBeginIndex != -1) {
            episodeDescriptionBeginIndex += episodeDescriptionMatching.length;
            NSInteger episodeDescriptionEndIndex = [responseString sf_find:@"<br>" fromIndex:episodeDescriptionBeginIndex];
            NSString *episodeDescription = [responseString sf_substringWithBeginIndex:episodeDescriptionBeginIndex endIndex:episodeDescriptionEndIndex];
            episodeDescription = [episodeDescription stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            episodeDescription = [episodeDescription stringByReplacingOccurrencesOfString:@"\r" withString:@""];
            episodeDescription = [episodeDescription sf_stringByStrippingHTMLTags];
            episodeDescription = [episodeDescription stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            episodeDescription = [episodeDescription stringByReplacingOccurrencesOfString:@"[" withString:@"\""];
            episodeDescription = [episodeDescription stringByReplacingOccurrencesOfString:@"]" withString:@"\""];
            episode.introdution = episodeDescription;
            episode.formattedIntrodution = episodeDescription;
            currentIndex = episodeDescriptionEndIndex;
        }
        episode.uid = [[NSString stringWithFormat:@"%@", episode.title] sf_stringByEncryptingUsingMD5];
        [episodes addObject:episode];
    }
    return episodes;
}

- (void)_notifyFinishWithEpisodes:(NSArray *)episodes error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.completion(episodes, error);
        self.executing = NO;
    });
}

- (NSInteger)pageSize
{
    return 20;
}

- (BOOL)isExecuting
{
    return self.executing;
}

- (void)cancel
{
    self.executing = NO;
    self.completion = nil;
    [self.session cancel];
}

- (BOOL)shouldRemoveDepositable
{
    return [self isExecuting] == NO;
}

- (void)depositableWillRemove
{
    [self cancel];
}

@end
