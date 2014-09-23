
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

@property (nonatomic, strong) NSMutableArray *episodes;

@property (nonatomic, strong) RACSignal *refreshEpisodesSignal;

@property (nonatomic, assign) BOOL usingCache;

@property (nonatomic, assign) BOOL hasMorePages;

@property (nonatomic, assign) BOOL refreshing;

@end

@implementation EpisodesViewModel

- (id)init
{
    self = [super init];
    
    self.usingCache = YES;
    self.episodes = [NSMutableArray array];
    self.hasMorePages = NO;
    
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

- (RACSignal *)_episodesSignal
{
    if (_refreshEpisodesSignal == nil) {
        @weakify(self);
        self.refreshEpisodesSignal = [[[[[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            ESEpisodeService *episodesService = [ESEpisodeService new];
            episodesService.useCache = self.usingCache;
            episodesService.pageIndex = self.pageIndex;
            [episodesService requestWithCompletion:^(NSArray *resultObject, NSError *error) {
                @strongify(self);
                if (resultObject) {
                    [subscriber sendNext:resultObject];
                } else {
                    --self.pageIndex;
                    [subscriber sendError:error];
                }
                [subscriber sendCompleted];
            }];
            return [RACDisposable disposableWithBlock:^{
                [episodesService cancel];
            }];
        }] doNext:^(NSArray *x) {
            @strongify(self);
            NSMutableArray *episodes = [NSMutableArray array];
            if (!self.refreshing) {
                [episodes addObjectsFromArray:self.episodes];
            }
            [episodes addObjectsFromArray:x];
            self.episodes = episodes;
            self.hasMorePages = x.count == 20;
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

- (RACSignal *)refreshEpisodesSignal
{
    self.pageIndex = 0;
    self.refreshing = YES;
    return [self _episodesSignal];
}

- (RACSignal *)nextPageEpisodesSignal
{
    self.refreshing = NO;
    ++self.pageIndex;
    return [self _episodesSignal];
}

@end
