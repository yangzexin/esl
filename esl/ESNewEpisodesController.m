//
//  TrackListController.m
//  esl
//
//  Created by yangzexin on 10/25/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESNewEpisodesController.h"
#import "ESEpisode.h"
#import "ESEpisodeService.h"
#import "ODRefreshControl.h"
#import "SFBlockedBarButtonItem.h"
#import "SFDialogTools.h"
#import "ESUIDefaults.h"
#import "ESLocalEpisodesController.h"
#import "ESViewEpisodeController.h"
#import "ESEpisodeManager.h"
#import "ESSoundPlayContext.h"

@interface ESNewEpisodesController ()

@property (nonatomic, strong) UIBarButtonItem *refreshBarButtonItem;
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
    }
    
    [self.navigationController setToolbarHidden:NO];
    NSMutableArray *toolbarItems = [NSMutableArray array];
    
    __weak typeof(self) weakSelf = self;
    [toolbarItems addObject:[SFBlockedBarButtonItem blockedBarButtonItemWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace eventHandler:nil]];
    self.refreshBarButtonItem = [SFBlockedBarButtonItem blockedBarButtonItemWithBarButtonSystemItem:UIBarButtonSystemItemRefresh eventHandler:^{
        weakSelf.refreshBarButtonItem.enabled = NO;
        [weakSelf _requestEpisodes];
    }];
    [toolbarItems addObject:self.refreshBarButtonItem];
    [toolbarItems addObject:[SFBlockedBarButtonItem blockedBarButtonItemWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace eventHandler:nil]];
    [toolbarItems addObject:[SFBlockedBarButtonItem blockedBarButtonItemWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks eventHandler:^{
        [weakSelf _bookmarkButtonTapped];
    }]];
    [toolbarItems addObject:[SFBlockedBarButtonItem blockedBarButtonItemWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace eventHandler:nil]];
    
    [self setToolbarItems:toolbarItems];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_episodesDidUpdateNotification:) name:ESEpisodeDidUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_backgroundUpdateEpisodeDidFinishNotification:) name:ESBackgroundUpdateEpisodeDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_soundPlayDidStartNofitication:) name:ESSoundPlayDidStartNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_soundPlayDidFinishNotification:) name:ESSoundPlayDidFinishNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.episodes.count == 0) {
        [self _requestEpisodes];
    }
    
    [self _updatePlayingState];
}

- (void)_requestEpisodes
{
    [self _requestEpisodesWithCompletion:nil];
}

- (void)_requestEpisodesWithCompletion:(void(^)())completion
{
    __weak typeof(self) weakSelf = self;
    [self requestService:[ESEpisodeService new] identifier:@"episodes" completion:^(id resultObject, NSError *error) {
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
    __weak typeof(self) weakSelf = self;
    if ([ESSoundPlayContext sharedContext].playingEpisode != nil) {
        self.navigationItem.rightBarButtonItem = [SFBlockedBarButtonItem blockedBarButtonItemWithTitle:@"Now Playing" eventHandler:^{
            [weakSelf _viewEpisode:[ESSoundPlayContext sharedContext].playingEpisode];
        }];
    }
}

- (void)_backgroundUpdateEpisodeDidFinishNotification:(NSNotification *)noti
{
    self.refreshBarButtonItem.enabled = YES;
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
    self.episodes = newEpisodes;
    [self _updateCacheStates];
    
    [self.tableView reloadData];
}

- (void)_updateCacheStates
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableDictionary *keyEpisodeUidValueCacheStateBool = [NSMutableDictionary dictionary];
        for (ESEpisode *episode in self.episodes) {
            BOOL isCached = [[ESEpisodeManager sharedManager] isEpisodeDownloaded:episode];
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
    [self _requestEpisodes];
    
    double delayInSeconds = 1.0f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [refreshControl endRefreshing];
    });
}

- (void)_bookmarkButtonTapped
{
    ESLocalEpisodesController *controller = [ESLocalEpisodesController new];
    [self presentViewController:[ESUIDefaults navigationControllerWithRootViewController:controller] animated:YES completion:nil];
}

- (void)_actionButtonTapped
{
    [SFDialogTools actionSheetWithTitle:@"" completion:^(NSInteger buttonIndex, NSString *buttonTitle) {
        
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Local Episodes", @"Download Manager", nil];
}

- (void)progressUpdatingWithPercent:(float)percent
{
    NSLog(@"%f", percent);
    [self.tableView reloadData];
}

- (void)_viewEpisode:(ESEpisode *)episode
{
    ESViewEpisodeController *controller = [ESViewEpisodeController viewEpisodeControllerWithEpisode:episode];
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
