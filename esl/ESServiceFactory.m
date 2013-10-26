//
//  ESServiceFactory.m
//  esl
//
//  Created by yangzexin on 10/26/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESServiceFactory.h"
#import "NSString+JavaLikeStringHandle.h"
#import "ESEpisode.h"
#import "ESServiceSession.h"
#import "SFSharedCache.h"
#import "SFObjectRepository.h"
#import "ESHTTPRequest.h"

NSString *kEpisodesListURLString = @"http://www.eslpod.com/website/show_all.php";

@implementation ESServiceFactory

+ (id<ESService>)eslEpisodes
{
    ESHTTPRequest *request = [ESHTTPRequest requestWithURLString:kEpisodesListURLString useHTTPPost:NO];
    [request setResponseDataWrapper:^id(NSData *data) {
        return [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
    }];
    request.useCache = YES;
    request.cacheOperator = [ESBlockHTTPRequestCacheOperator cacheOpeartorWithReader:^NSData *(NSString *identifier) {
        return [[SFSharedCache sharedFileCache] cachedDataWithIdentifier:identifier filter:[SFSharedCache foreverCacheFilter]];
    } writer:^(NSData *data, NSString *identifier) {
        [[SFSharedCache sharedFileCache] storeCacheWithIdentifier:identifier data:data];
    }];
    [request setRequestDidFinish:^(id response, BOOL fromCache) {
        if(fromCache){
            
        }
    }];
    ESServiceSession *session = [ESServiceSession sessionWithRequestProxy:request responseProcessor:^id(id response, NSError *__autoreleasing *error) {
        NSString *responseString = response;
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
                NSString *soundURLString = aLinkInnerHTML;
                episode.soundURLString = soundURLString;
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
//                currentIndex = episodeDescriptionEndIndex;
            }
            [episodes addObject:episode];
        }
        
        return episodes;
    }];
    return session;
    return nil;
}

@end
