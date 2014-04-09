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
    RAC(self, episodes) = self.refreshEpisodesSignal;
    @weakify(self);
    [self.refreshEpisodesSignal subscribeNext:^(id x) {
        @strongify(self);
        self.usingCache = NO;
        [self.refreshEpisodesSignal subscribeNext:^(id x) {
            NSLog(@"updated:");
            NSLog(@"%@", x);
        }];
    }];
    
    return self;
}

- (RACSignal *)refreshEpisodesSignal
{
    if (_refreshEpisodesSignal == nil) {
        @weakify(self);
        self.refreshEpisodesSignal = [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
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
                @strongify(self);
                self.refreshEpisodesSignal = nil;
                [episodesService cancel];
            }];
        }] publish] autoconnect];
    }
    return _refreshEpisodesSignal;
}

@end
