//
//  EpisodeDetailViewModel.m
//  esl
//
//  Created by yangzexin on 4/3/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "EpisodeDetailViewModel.h"
#import "ESEpisode.h"

@interface EpisodeDetailViewModel ()

@property (nonatomic, strong) ESEpisode *episode;

@property (nonatomic, strong) RACSignal *episodeDetailSignal;

@end

@implementation EpisodeDetailViewModel

+ (instancetype)viewModelWithEpisode:(ESEpisode *)episode
{
    EpisodeDetailViewModel *viewModel = [EpisodeDetailViewModel new];
    viewModel.episode = episode;
    
    return viewModel;
}

- (RACSignal *)episodeDetailSignal
{
    if (_episodeDetailSignal == nil) {
        self.episodeDetailSignal = [[[[[NSURLConnection rac_sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_episode.contentURLString]]] map:^id(id value) {
            if (![value isKindOfClass:[NSError class]]) {
                NSData *responseData = [value last];
                NSString *HTML = [[NSString alloc] initWithData:responseData encoding:NSASCIIStringEncoding];
                value = HTML;
            } else {
                value = @"";
            }
            return value;
        }] deliverOn:[RACScheduler mainThreadScheduler]] publish] autoconnect];
        @weakify(self);
        [self.episodeDetailSignal subscribeCompleted:^{
            @strongify(self);
            self.episodeDetailSignal = nil;
        }];
    }
    return _episodeDetailSignal;
}

@end
