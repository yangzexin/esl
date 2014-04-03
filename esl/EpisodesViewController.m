//
//  EpisodesViewController.m
//  esl
//
//  Created by yangzexin on 3/27/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "EpisodesViewController.h"
#import "EpisodeDetailViewController.h"

#import "ESEpisode.h"

#import "EpisodesViewModel.h"

#import "ODRefreshControl.h"

@interface EpisodesViewController ()

@property (nonatomic, strong) EpisodesViewModel *viewModel;

@end

@implementation EpisodesViewController

- (id)init
{
    self = [super init];
    
    self.title = NSLocalizedString(@"Episodes", nil);
    self.viewModel = [EpisodesViewModel new];
    
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
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    @weakify(self);
    [RACObserve(_viewModel, episodes) subscribeNext:^(id x) {
        @strongify(self);
        [self.tableView reloadData];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

#pragma mark - UI events
- (void)_dropViewDidBeginRefreshing:(ODRefreshControl *)refreshControl
{
    
}

- (void)_refreshControlDidBeginRefreshing:(UIRefreshControl *)refreshControl
{
    [_viewModel.refreshEpisodesSignal subscribeNext:^(id x) {
        [refreshControl endRefreshing];
    }];
}

#pragma mark - UITableViewDelegate & dataSource
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ESEpisode *episode = [self.viewModel.episodes objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:[EpisodeDetailViewController controllerWithEpisode:episode] animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _viewModel.episodes.count;
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
        cell.textLabel.font = [UIFont systemFontOfSize:15.0f];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0f];
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    ESEpisode *episode = [self.viewModel.episodes objectAtIndex:indexPath.row];
    cell.textLabel.text = episode.title;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"\n%@\n%@", episode.date, episode.formattedIntrodution];
    
    return cell;
}

@end
