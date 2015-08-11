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
#import "EpisodeDetailViewModel.h"

#import "ODRefreshControl.h"
#import "SFBlockedBarButtonItem.h"
#import "SVPullToRefresh.h"

#import "SFiOSKit.h"

#import "ESSoundPlayContext.h"

@interface EpisodesViewController () <SFImageLabelDelegate>

@property (nonatomic, strong) EpisodesViewModel *viewModel;

@property (nonatomic, strong) UIView *loadMoreFooter;

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
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(_refreshControlDidBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    
    SFCardLayout *loadMoreFooter = [[SFCardLayout alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 72)];
    loadMoreFooter.alignment = SFCardLayoutAlignmentCenter;
    loadMoreFooter.spacing = 5.0f;
    loadMoreFooter.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    loadMoreFooter.backgroundColor = [UIColor clearColor];
    self.loadMoreFooter = loadMoreFooter;
    
    SFBlockedButton *loadMoreLabel = [[SFBlockedButton alloc] initWithFrame:CGRectMake(0, 0, loadMoreFooter.frame.size.width, loadMoreFooter.frame.size.height)];
    loadMoreLabel.titleLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    loadMoreLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [loadMoreLabel setTitle:@"Show More .." forState:UIControlStateNormal];
    [loadMoreLabel setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [loadMoreLabel setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [loadMoreLabel setBackgroundImage:[UIImage sf_imageWithColor:[UIColor sf_colorWithRed:247 green:247 blue:247] size:CGSizeMake(1, 1)] forState:UIControlStateNormal];
    [loadMoreLabel setBackgroundImage:[UIImage sf_imageWithColor:[UIColor sf_colorWithRed:230 green:230 blue:230] size:CGSizeMake(1, 1)]
                             forState:UIControlStateHighlighted];
    [self.loadMoreFooter addSubview:loadMoreLabel];
    
    @weakify(self);
    @weakify(loadMoreLabel);
    [loadMoreLabel setTapHandler:^{
        @strongify(self);
        @strongify(loadMoreLabel);
        [loadMoreLabel setTitle:@"Loading .." forState:UIControlStateNormal];
        loadMoreLabel.userInteractionEnabled = NO;
        @weakify(self);
        [self.viewModel.nextPageEpisodesSignal subscribeError:^(NSError *error) {
            @strongify(self);
            [self.tableView reloadData];
            @strongify(loadMoreLabel);
            [loadMoreLabel setTitle:@"Show More .." forState:UIControlStateNormal];
            loadMoreLabel.userInteractionEnabled = YES;
        } completed:^{
            @strongify(self);
            [self.tableView reloadData];
            @strongify(loadMoreLabel);
            [loadMoreLabel setTitle:@"Show More .." forState:UIControlStateNormal];
            loadMoreLabel.userInteractionEnabled = YES;
        }];
    }];
    
    [RACObserve(self.viewModel, hasMorePages) subscribeNext:^(NSNumber *x) {
        @strongify(self);
        [self setShouldLoadMore:[x boolValue] && self.viewModel.episodes.count != 0];
    }];
}

- (void)setShouldLoadMore:(BOOL)more
{
    self.tableView.tableFooterView = more ? self.loadMoreFooter : nil;
    [self.loadMoreFooter setNeedsLayout];
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
//    NSLog(@"viewWillAppear");
    @weakify(self);
    ESEpisode *playingEpisode = [[ESSoundPlayContext sharedContext] playingEpisode];
    self.navigationItem.rightBarButtonItem = playingEpisode != nil ? ({
            SFBlockedBarButtonItem *buttonItem = [SFBlockedBarButtonItem blockedBarButtonItemWithTitle:@"Listening" eventHandler:^{
            @strongify(self);
            ESEpisode *episode = playingEpisode;
            [self.navigationController pushViewController:[EpisodeDetailViewController controllerWithViewModel:[EpisodeDetailViewModel viewModelWithEpisode:episode]] animated:YES];
        }];
        buttonItem.style = UIBarButtonItemStyleDone;
        buttonItem;
    }) : nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
//    NSLog(@"viewDidAppear");
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    NSLog(@"viewWillDisappear");
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
//    NSLog(@"viewDidDisappear");
}

#pragma mark - UI events
- (void)_refreshControlDidBeginRefreshing:(id)refreshControl
{
    self.viewModel.pageIndex = 0;
    @weakify(self);
    [_viewModel.refreshEpisodesSignal subscribeError:^(NSError *error) {
        [refreshControl endRefreshing];
        @strongify(self);
        [self.tableView reloadData];
    } completed:^{
        @strongify(self);
        [refreshControl endRefreshing];
        [self.tableView reloadData];
    }];
}

#pragma mark - UITableViewDelegate & dataSource
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ESEpisode *episode = [self.viewModel.episodes objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:[EpisodeDetailViewController controllerWithViewModel:[EpisodeDetailViewModel viewModelWithEpisode:episode]] animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _viewModel.episodes.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ESEpisode *episode = [self.viewModel.episodes objectAtIndex:indexPath.row];
    return [episode titleFormatted].size.height + 15 + (SFDeviceSystemVersion < 7.0f ? -30 : 0);
}

- (UIImage *)imageLabel:(SFImageLabel *)imageLabel imageWithName:(NSString *)imageName
{
    static NSMutableDictionary *keyImageNameValueImage = nil;
    if (keyImageNameValueImage == nil) {
        keyImageNameValueImage = [NSMutableDictionary dictionary];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 22, 20)];
        label.opaque = NO;
        label.font = [UIFont systemFontOfSize:17.0f];
        label.backgroundColor = [UIColor clearColor];
        label.contentMode = UIViewContentModeBottom;
        
        label.text = @"📀";
        [keyImageNameValueImage setObject:[label sf_toImageLegacy] forKey:@"title"];
        
        label.text = @"📅";
        [keyImageNameValueImage setObject:[label sf_toImageLegacy] forKey:@"date"];
        
        [keyImageNameValueImage setObject:[UIImage imageNamed:@"logo.gif"] forKey:@"introdution"];
    }
    return [keyImageNameValueImage objectForKey:imageName];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"__id";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    SFImageLabel *imageLabel = nil;
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.textLabel.numberOfLines = 1;
        cell.detailTextLabel.numberOfLines = 4;
        cell.textLabel.font = [UIFont systemFontOfSize:15.0f];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0f];
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
        cell.backgroundView = [UIView new];
//        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        imageLabel = [[SFImageLabel alloc] initWithFrame:CGRectMake(5, 7, cell.contentView.bounds.size.width - 10, cell.contentView.bounds.size.height)];
        imageLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        imageLabel.tag = 1001;
        imageLabel.delegate = self;
        imageLabel.drawsImageWithImageSize = YES;
        [cell.contentView addSubview:imageLabel];
        
        [cell.contentView sf_addBottomLineWithColor:[UIColor sf_colorWithRed:0 green:0 blue:0 alpha:10]];
    } else {
        imageLabel = (id)[cell.contentView viewWithTag:1001];
    }
    ESEpisode *episode = [self.viewModel.episodes objectAtIndex:indexPath.row];
//    cell.textLabel.text = episode.title;
//    cell.detailTextLabel.text = [NSString stringWithFormat:@"\n%@\n%@", episode.date, episode.formattedIntrodution];
    imageLabel.text = [episode titleFormatted];
    
    SFDownloadState downloadState = [[ESSoundDownloadManager sharedManager] stateForEpisode:episode];
    cell.backgroundView.backgroundColor = downloadState == SFDownloadStateDownloaded ? [UIColor sf_colorWithRed:0 green:255 blue:0 alpha:27] : [UIColor whiteColor];
    
    return cell;
}

@end
