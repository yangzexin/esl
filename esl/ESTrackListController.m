//
//  TrackListController.m
//  esl
//
//  Created by yangzexin on 10/25/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESTrackListController.h"
#import "ESEpisode.h"
#import "ESEpisodeService.h"
#import "ODRefreshControl.h"
#import "ESSoundManager.h"

@interface ESTrackListController () <ESProgressTracker>

@end

@implementation ESTrackListController {
    NSArray *episodes;
}

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
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_episodesDidUpdateNotification:) name:ESEpisodeDidUpdateNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self->episodes.count == 0) {
        [self _requestEpisodes];
    }
}

- (void)_requestEpisodes
{
    __block typeof(self) bself = self;
    [self requestService:[ESEpisodeService new] completion:^(id resultObject, NSError *error) {
        if (error == nil) {
            [bself _episodesDidUpdate:resultObject];
        }
    }];
}

- (void)_episodesDidUpdateNotification:(NSNotification *)noti
{
    [self _episodesDidUpdate:noti.object];
}

- (void)_episodesDidUpdate:(NSArray *)newEpisodes
{
    self->episodes = newEpisodes;
    [self.tableView reloadData];
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

- (void)progressUpdatingWithPercent:(float)percent
{
    NSLog(@"%f", percent);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ESEpisode *episode = [self->episodes objectAtIndex:indexPath.row];
    id<ESService> soundService = [ESSoundManager soundWithURLString:episode.soundURLString progressTracker:self];
    [self requestService:soundService completion:^(id resultObject, NSError *error) {
        
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self->episodes.count;
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
    ESEpisode *episode = [self->episodes objectAtIndex:indexPath.row];
    cell.textLabel.text = episode.title;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"\n%@\n%@", episode.date, episode.introdution];
    
    return cell;
}

@end
