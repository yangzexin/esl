//
//  EpisodeDetailViewModel.m
//  esl
//
//  Created by yangzexin on 4/3/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "EpisodeDetailViewModel.h"
#import "ESEpisode.h"
#import "NSString+JavaLikeStringHandle.h"
#import "NSObject+SFAddition.h"
#import "SFRepeatTimer.h"
#import "ESSoundDownloadManager.h"

@interface EpisodeDetailViewModel ()

@property (nonatomic, strong) ESEpisode *episode;

@property (nonatomic, strong) RACSignal *episodeDetailSignal;

@property (nonatomic, assign) BOOL soundDownloaded;

@property (nonatomic, assign) float downloadPercent;

@end

@implementation EpisodeDetailViewModel

+ (instancetype)viewModelWithEpisode:(ESEpisode *)episode
{
    EpisodeDetailViewModel *viewModel = [EpisodeDetailViewModel new];
    viewModel.episode = episode;
    
    return viewModel;
}

- (id)init
{
    self = [super init];
    
    @weakify(self);
    [self addRepositionSupportedObject:[SFRepeatTimer timerStartWithTimeInterval:0.50f tick:^{
        @strongify(self);
        self.downloadPercent = [[ESSoundDownloadManager sharedManager] downloadedPercentForEpisode:self.episode];
    }] identifier:@"downloadPercentRefreshTimer"];
    
    return self;
}

- (RACSignal *)episodeDetailSignal
{
    if (_episodeDetailSignal == nil) {
        self.episodeDetailSignal = [[[[[[NSURLConnection rac_sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_episode.contentURLString]]] map:^id(id value) {
            if (![value isKindOfClass:[NSError class]]) {
                NSData *responseData = [value last];
                NSString *HTML = [[NSString alloc] initWithData:responseData encoding:NSASCIIStringEncoding];
                
                value = HTML;
                
                NSString *beginMatching = @"class=\"podcast_table_home\"";
                NSString *endMatching = @"<a class=\"grayButton\"";
                NSInteger beginIndex = [HTML find:beginMatching];
                if (beginIndex != -1) {
                    beginIndex += beginMatching.length + 1;
                    NSInteger endIndex = [HTML find:endMatching fromIndex:beginIndex];
                    if (endIndex != -1) {
                        NSString *content = [HTML substringWithBeginIndex:beginIndex endIndex:endIndex];
                        NSString *contentWrapper = @"<html><body><div style='font-family:Verdana;'>$content</div></body></html>";
                        value = [contentWrapper stringByReplacingOccurrencesOfString:@"$content" withString:content];
                    }
                }
            }
            return value;
        }] catchTo:[RACSignal empty]] deliverOn:[RACScheduler mainThreadScheduler]] publish] autoconnect];
        @weakify(self);
        [self.episodeDetailSignal subscribeCompleted:^{
            @strongify(self);
            self.episodeDetailSignal = nil;
        }];
    }
    return _episodeDetailSignal;
}

@end
