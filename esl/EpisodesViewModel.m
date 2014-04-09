
//
//  EpisodesViewModel.m
//  esl
//
//  Created by yangzexin on 3/27/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "EpisodesViewModel.h"
#import "ESEpisodeService.h"

@interface EpisodesViewModel ()

@property (nonatomic, strong) NSArray *episodes;

@property (nonatomic, strong) RACSignal *refreshEpisodesSignal;

@property (nonatomic, assign) BOOL usingCache;

@end

@implementation EpisodesViewModel

- (id)init
{
    self = [super init];
    
    self.usingCache = YES;
    
    @weakify(self);
    [self.refreshEpisodesSignal subscribeCompleted:^{
        @strongify(self);
        NSLog(@"episodes loaded");
        self.usingCache = NO;
        [self.refreshEpisodesSignal subscribeNext:^(id x) {
            NSLog(@"episodes updated");
        }];
    }];
    
    return self;
}

- (RACSignal *)refreshEpisodesSignal
{
    if (_refreshEpisodesSignal == nil) {
        @weakify(self);
        self.refreshEpisodesSignal = [[[[[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            ESEpisodeService *episodesService = [ESEpisodeService new];
            episodesService.useCache = self.usingCache;
            [episodesService requestWithCompletion:^(id resultObject, NSError *error) {
                if (resultObject) {
                    [subscriber sendNext:resultObject];
                } else {
                    [subscriber sendError:error];
                }
                [subscriber sendCompleted];
            }];
            return [RACDisposable disposableWithBlock:^{
                [episodesService cancel];
            }];
        }] doNext:^(id x) {
            @strongify(self);
            self.episodes = x;
        }] doError:^(NSError *error) {
            @strongify(self);
            self.refreshEpisodesSignal = nil;
        }] doCompleted:^{
            @strongify(self);
            self.refreshEpisodesSignal = nil;
        }] publish] autoconnect];
    }
    return _refreshEpisodesSignal;
}

@end
