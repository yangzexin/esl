//
//  TrackListController.m
//  esl
//
//  Created by yangzexin on 10/25/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESNewEpisodesController.h"

#import "ESEpisode.h"
#import "ODRefreshControl.h"
#import "ESViewEpisodeController.h"
#import "ESSoundPlayContext.h"

@interface ESNewEpisodesController ()

@property (nonatomic, strong) UIBarButtonItem *refreshBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *nowPlayingBarButtonItem;
@property (nonatomic, strong) NSArray *episodes;
@property (nonatomic, strong) NSDictionary *keyEpisodeUidValueCacheStateBool;

@end

@implementation ESNewEpisodesController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init
{
    self = [super init];
    
    self.title = @"Episodes";
    
    return self;
}

- (void)loadView
{
    [super loadView];
    
    if ([UIDevice currentDevice].systemVersion.floatValue < 7.0f) {
        ODRefreshControl *refreshControl = [[ODRefreshControl alloc] initInScrollView:self.tableView];
        [refreshControl addTarget:self action:@selector(_dropViewDidBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
    } else {
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(_refreshControlDidBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
        [self.tableView addSubview:refreshControl];
    }
    
    __weak typeof(self) weakSelf = self;
    
    self.nowPlayingBarButtonItem = [SFBlockedBarButtonItem blockedBarButtonItemWithTitle:@"Now Playing" eventHandler:^{
        [weakSelf _viewEpisode:[ESSoundPlayContext sharedContext].playingEpisode];
    }];
    self.nowPlayingBarButtonItem.style = UIBarButtonItemStyleDone;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_soundPlayDidStartNofitication:) name:ESSoundPlayDidStartNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_soundPlayDidFinishNotification:) name:ESSoundPlayDidFinishNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.episodes.count == 0) {
        [self _requestEpisodes];
    } else {
        [self _updateCacheStates];
    }
    
    [self _updatePlayingState];
}

- (void)_requestEpisodes
{
    __weak typeof(self) weakSelf = self;
    [self _requestEpisodesWithCompletion:^{
        [weakSelf _requestEpisodesWithService:[weakSelf.episodeManager newestEpisodes] completion:nil];
    }];
}

- (void)_requestNewestEpisodes
{
    __weak typeof(self) weakSelf = self;
    [self _requestEpisodesWithService:[self.episodeManager newestEpisodes] completion:^{
        weakSelf.refreshBarButtonItem.enabled = YES;
    }];
}

- (void)_requestEpisodesWithCompletion:(void(^)())completion
{
    [self _requestEpisodesWithService:[self.episodeManager episodes] completion:completion];
}

- (void)_requestEpisodesWithService:(id<ESService>)service completion:(void(^)())completion
{
    __weak typeof(self) weakSelf = self;
    [self requestService:service identifier:@"episodes" completion:^(id resultObject, NSError *error) {
        if (error == nil) {
            [weakSelf _episodesDidUpdate:resultObject];
        }
        if (completion) {
            completion();
        }
    }];
}

- (void)_episodesDidUpdateNotification:(NSNotification *)noti
{
    [self _episodesDidUpdate:noti.object];
}

- (void)_updatePlayingState
{
    if ([ESSoundPlayContext sharedContext].isPlaying) {
        self.navigationItem.rightBarButtonItem = self.nowPlayingBarButtonItem;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)_soundPlayDidStartNofitication:(NSNotification *)noti
{
    [self _updatePlayingState];
}

- (void)_soundPlayDidFinishNotification:(NSNotification *)noti
{
    [self _updatePlayingState];
}

- (void)_episodesDidUpdate:(NSArray *)newEpisodes
{
    if (newEpisodes.count != 0) {
        self.episodes = newEpisodes;
        [self _updateCacheStates];
        
        [self.tableView reloadData];
    }
}

- (void)_updateCacheStates
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableDictionary *keyEpisodeUidValueCacheStateBool = [NSMutableDictionary dictionary];
        for (ESEpisode *episode in self.episodes) {
            BOOL isCached = [self.episodeManager isEpisodeDownloaded:episode];
            [keyEpisodeUidValueCacheStateBool setObject:[NSNumber numberWithBool:isCached] forKey:episode.uid];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.keyEpisodeUidValueCacheStateBool = keyEpisodeUidValueCacheStateBool;
            [self.tableView reloadData];
        });
    });
}

- (void)_dropViewDidBeginRefreshing:(ODRefreshControl *)refreshControl
{
    [self _requestNewestEpisodes];
    
    double delayInSeconds = 1.0f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [refreshControl endRefreshing];
    });
}

- (void)_refreshControlDidBeginRefreshing:(UIRefreshControl *)refreshControl
{
    self.refreshBarButtonItem.enabled = YES;
    [self _requestNewestEpisodes];
    
    double delayInSeconds = 1.0f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [refreshControl endRefreshing];
    });
}

- (void)_viewEpisode:(ESEpisode *)episode
{
    ESViewEpisodeController *controller = [ESViewEpisodeController viewEpisodeControllerWithEpisode:episode];
    controller.episodeManager = self.episodeManager;
    controller.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ESEpisode *episode = [self.episodes objectAtIndex:indexPath.row];
    [self _viewEpisode:episode];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.episodes.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"__id";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.textLabel.numberOfLines = 1;
        cell.detailTextLabel.numberOfLines = 4;
        cell.textLabel.font = [UIFont systemFontOfSize:14.0f];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0f];
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    ESEpisode *episode = [self.episodes objectAtIndex:indexPath.row];
    NSNumber *cacheState = [self.keyEpisodeUidValueCacheStateBool objectForKey:episode.uid];
    if (cacheState) {
        BOOL isCached = [cacheState boolValue];
        cell.textLabel.textColor = isCached ? [UIColor blueColor] : [UIColor blackColor];
    }
    cell.textLabel.text = episode.title;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"\n%@\n%@", episode.date, episode.introdution];
    
    return cell;
}

@end
