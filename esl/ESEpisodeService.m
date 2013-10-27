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
#import "NSString+JavaLikeStringHandle.h"
#import "ESEpisode.h"

NSString *ESEpisodeDidUpdateNotification = @"ESEpisodeDidUpdateNotification";

NSString *kEpisodesListURLString = @"http://www.eslpod.com/website/show_all.php";

@interface ESEpisodeService ()

@property (nonatomic, assign) BOOL executing;
@property (nonatomic, copy) ESServiceCompletion completion;
@property (nonatomic, retain) ESServiceSession *session;

@end

@implementation ESEpisodeService

- (void)requestWithCompletion:(ESServiceCompletion)completion
{
    [self cancel];
    self.completion = completion;
    self.executing = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *_cachedHTML = [self _cachedData];
        if (_cachedHTML.length != 0) {
            NSArray *episodes = [self _analyzeHTML:_cachedHTML];
            [self _updateEpisodesBackground];
            [self _notifyFinishWithEpisodes:episodes error:nil];
        } else {
            __block typeof(self) bself = self;
            [self _requestEpisodesWithCompletion:^(id resultObject, NSError *error) {
                [bself _notifyFinishWithEpisodes:resultObject error:error];
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
    return [[SFSharedCache sharedFileCache] cachedStringWithIdentifier:@"episodes" filter:[SFSharedCache foreverCacheFilter]];
}

- (void)_updateEpisodesBackground
{
    [self _requestEpisodesWithCompletion:^(id resultObject, NSError *error) {
        NSArray *episodes = resultObject;
        if (episodes.count != 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ESEpisodeDidUpdateNotification object:episodes];
        }
    }];
}

- (void)_requestEpisodesWithCompletion:(ESServiceCompletion)completion
{
    ESHTTPRequest *request = [ESHTTPRequest requestWithURLString:kEpisodesListURLString useHTTPPost:NO];
    __block typeof(self) bself = self;
    [request setResponseDataWrapper:^id(NSData *data) {
        NSString *string = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
        [bself _storeCacheData:string];
        return string;
    }];
    self.session = [ESServiceSession sessionWithRequestProxy:request responseProcessor:^id(id response, NSError *__autoreleasing *error) {
        return [bself _analyzeHTML:response];
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
    while ((beginIndex = [responseString find:matching fromIndex:endIndex]) != -1
           && (endIndex = [responseString find:bottomMatching fromIndex:beginIndex + matching.length]) != -1) {
        NSInteger currentIndex = beginIndex += matching.length;
        
        ESEpisode *episode = [ESEpisode new];
        
        NSString *const dateMatching = @"<span class=\"date-header\">";
        NSString *const dateBottomMatching = @"</span><br>";
        NSInteger dateBeginIndex = [responseString find:dateMatching fromIndex:currentIndex];
        if (dateBeginIndex != -1) {
            dateBeginIndex += dateMatching.length;
            NSInteger dateEndIndex = [responseString find:dateBottomMatching fromIndex:dateBeginIndex];
            NSString *date = [responseString substringWithBeginIndex:dateBeginIndex endIndex:dateEndIndex];
            date = [date stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            episode.date = date;
            currentIndex = dateEndIndex;
        }
        
        NSString *const titleMatching = @"class=\"podcast_title\">";
        NSString *const titleBottomMatching = @"</a>";
        NSInteger titleBeginIndex = [responseString find:titleMatching fromIndex:currentIndex];
        if (titleBeginIndex != -1) {
            titleBeginIndex += titleMatching.length;
            NSInteger titleEndIndex = [responseString find:titleBottomMatching fromIndex:titleBeginIndex];
            NSString *title = [responseString substringWithBeginIndex:titleBeginIndex endIndex:titleEndIndex];
            title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            episode.title = title;
            currentIndex = titleEndIndex;
        }
        
        NSString *const soundURLStringMatching = @"Download Podcast";
        NSInteger downloadStringIndex = [responseString find:soundURLStringMatching fromIndex:currentIndex];
        if (downloadStringIndex != -1) {
            NSInteger aLinkBeginIndex = [responseString find:@"<a" fromIndex:downloadStringIndex reverse:YES];
            NSInteger aLinkEndIndex = [responseString find:@">" fromIndex:aLinkBeginIndex];
            NSString *aLinkInnerHTML = [responseString substringWithBeginIndex:aLinkBeginIndex endIndex:aLinkEndIndex];
            
            NSString *const hrefMatching = @"href=\"";
            NSInteger hrefBeginIndex = [aLinkInnerHTML find:hrefMatching];
            if (hrefBeginIndex != -1) {
                hrefBeginIndex += hrefMatching.length;
                NSInteger hrefEndIndex = [aLinkInnerHTML find:@"\"" fromIndex:hrefBeginIndex];
                NSString *soundURLString = [aLinkInnerHTML substringWithBeginIndex:hrefBeginIndex endIndex:hrefEndIndex];
                episode.soundURLString = soundURLString;
            }
            currentIndex = downloadStringIndex;
        }
        
        NSString *const episodeDescriptionMatching = @"</span>";
        NSInteger episodeDescriptionBeginIndex = [responseString find:episodeDescriptionMatching fromIndex:currentIndex];
        if (episodeDescriptionBeginIndex != -1) {
            episodeDescriptionBeginIndex += episodeDescriptionMatching.length;
            NSInteger episodeDescriptionEndIndex = [responseString find:@"<br>" fromIndex:episodeDescriptionBeginIndex];
            NSString *episodeDescription = [responseString substringWithBeginIndex:episodeDescriptionBeginIndex endIndex:episodeDescriptionEndIndex];
            episodeDescription = [episodeDescription stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            episodeDescription = [episodeDescription stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            episodeDescription = [episodeDescription stringByReplacingOccurrencesOfString:@"\r" withString:@""];
            episode.introdution = episodeDescription;
            currentIndex = episodeDescriptionEndIndex;
        }
        [episodes addObject:episode];
    }
    return episodes;
}

- (void)_notifyFinishWithEpisodes:(NSArray *)episodes error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.completion(episodes, nil);
        self.executing = NO;
    });
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

- (BOOL)shouldRemoveFromObjectRepository
{
    return [self isExecuting];
}

- (void)willRemoveFromObjectRepository
{
    [self cancel];
}

@end
