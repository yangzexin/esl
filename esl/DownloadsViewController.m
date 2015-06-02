//
//  DownloadsViewController.m
//  esl
//
//  Created by yangzexin on 4/3/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "DownloadsViewController.h"

#import "SFFoundation.h"

#import "ESEpisode.h"

#import "ESSoundDownloadManager.h"

#import "SFiOSKit.h"

#import "EpisodeDetailViewController.h"

#import "EpisodeDetailViewModel.h"

@interface DownloadsViewController ()

@property (nonatomic, strong) NSArray *downloadingEpisodes;
@property (nonatomic, strong) NSDictionary *keyEpisodeIdValuePercent;

@property (nonatomic, assign) BOOL downloadsUpdated;

@property (nonatomic, assign) BOOL visible;

@end

@implementation DownloadsViewController

- (id)init
{
    self = [super init];
    
    self.title = NSLocalizedString(@"Downloads", nil);
    
    return self;
}

- (void)loadView
{
    [super loadView];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(_refreshControlDidBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    @weakify(self);
    [self sf_depositNotificationObserver:[[NSNotificationCenter defaultCenter] addObserverForName:ESEpisodeDidStartDownloadNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        @strongify(self);
        self.downloadsUpdated = YES;
    }]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.downloadingEpisodes.count == 0 || self.downloadsUpdated) {
        self.downloadsUpdated = NO;
        [self _refreshDownloads];
    }
    self.visible = YES;
}

- (void)_refreshDownloads
{
    @weakify(self);
    [self _refreshDownloadsWithCompletion:^{
        @strongify(self);
        [self.tableView reloadData];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.visible = NO;
}

- (void)_refreshDownloadsWithCompletion:(void(^)())completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.downloadingEpisodes = [[ESSoundDownloadManager sharedManager] downloadingEpisodes];
        NSMutableDictionary *keyEpisodeIdValuePercent = [NSMutableDictionary dictionary];
        for (ESEpisode *episode in _downloadingEpisodes) {
            [keyEpisodeIdValuePercent setObject:[NSNumber numberWithFloat:[[ESSoundDownloadManager sharedManager] downloadedPercentForEpisode:episode]] forKey:episode.uid];
        }
        self.keyEpisodeIdValuePercent = keyEpisodeIdValuePercent;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion();
            }
        });
    });
}

- (void)_refreshControlDidBeginRefreshing:(UIRefreshControl *)refreshControl
{
    @weakify(self);
    @weakify(refreshControl);
    [self _refreshDownloadsWithCompletion:^{
        @strongify(self);
        @strongify(refreshControl);
        [refreshControl endRefreshing];
        [self.tableView reloadData];
    }];
}

- (void)_showOptionsMenuWithEpisode:(ESEpisode *)episode
{
    NSMutableArray *actionTitles = [NSMutableArray array];
    [actionTitles addObject:@"查看"];
    SFDownloadState downloadState = [[ESSoundDownloadManager sharedManager] stateForEpisode:episode];
    if (downloadState == SFDownloadStatePaused || downloadState == SFDownloadStateErrored) {
        [actionTitles addObject:@"继续下载"];
    } else if (downloadState == SFDownloadStateDownloading) {
        [actionTitles addObject:@"暂停下载"];
    }
    [actionTitles addObject:@"重新下载"];
    [actionTitles addObject:@"删除"];
    
    [UIActionSheet sf_actionSheetWithTitle:@"" completion:^(NSInteger buttonIndex, NSString *buttonTitle) {
        if ([buttonTitle isEqualToString:@"查看"]) {
            [self.navigationController pushViewController:[EpisodeDetailViewController controllerWithViewModel:[EpisodeDetailViewModel viewModelWithEpisode:episode]] animated:YES];
        } else if ([buttonTitle isEqualToString:@"继续下载"]) {
            [[ESSoundDownloadManager sharedManager] downloadEpisode:episode];
            [self _refreshDownloads];
        } else if ([buttonTitle isEqualToString:@"重新下载"]) {
            [UIAlertView sf_alertWithTitle:@"温馨提示" message:@"确定要重新下载音频吗？" completion:^(NSInteger buttonIndex, NSString *buttonTitle) {
                if (buttonIndex != 0) {
                    [[ESSoundDownloadManager sharedManager] removeEpisode:episode];
                    [[ESSoundDownloadManager sharedManager] downloadEpisode:episode];
                    [self _refreshDownloads];
                }
            } cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        } else if ([buttonTitle isEqualToString:@"暂停下载"]) {
            [[ESSoundDownloadManager sharedManager] pauseDownloadingEpisode:episode];
            [self _refreshDownloads];
        } else if ([buttonTitle isEqualToString:@"删除"]) {
            [UIAlertView sf_alertWithTitle:@"温馨提示" message:@"确定要删除节目吗？" completion:^(NSInteger buttonIndex, NSString *buttonTitle) {
                if (buttonIndex != 0) {
                    [[ESSoundDownloadManager sharedManager] removeEpisode:episode];
                    [self _refreshDownloads];
                }
            } cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        }
    } cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitleList:actionTitles];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ESEpisode *episode = [_downloadingEpisodes objectAtIndex:indexPath.row];
    SFDownloadState downloadState = [[ESSoundDownloadManager sharedManager] stateForEpisode:episode];
    if (downloadState == SFDownloadStateDownloaded) {
        [self.navigationController pushViewController:[EpisodeDetailViewController controllerWithViewModel:[EpisodeDetailViewModel viewModelWithEpisode:episode]] animated:YES];
    } else {
        [self _showOptionsMenuWithEpisode:episode];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    ESEpisode *episode = [_downloadingEpisodes objectAtIndex:indexPath.row];
    [self _showOptionsMenuWithEpisode:episode];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _downloadingEpisodes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"__id";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    UIView *downloadPercentView = nil;
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.textLabel.numberOfLines = 1;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.font = [UIFont systemFontOfSize:15.0f];
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        
        downloadPercentView = [[UIView alloc] initWithFrame:cell.bounds];
        downloadPercentView.tag = 1001;
        downloadPercentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [cell insertSubview:downloadPercentView belowSubview:cell.contentView];
        
        [cell sf_addBottomLineWithColor:[UIColor sf_colorWithRed:0 green:0 blue:0 alpha:10]];
    } else {
        downloadPercentView = (id)[cell viewWithTag:1001];
    }
    ESEpisode *episode = [_downloadingEpisodes objectAtIndex:indexPath.row];
    cell.textLabel.text = episode.simpleTitle;
    [cell.textLabel sizeToFit];
    
    @weakify(episode);
    @weakify(downloadPercentView);
    @weakify(cell);
    @weakify(self);
    [cell sf_deposit:[SFRepeatTimer timerStartWithTimeInterval:.50f tick:^{
        @strongify(episode);
        @strongify(downloadPercentView);
        @strongify(cell);
        @strongify(self);
        if (self.visible && episode != nil) {
            SFDownloadState downloadState = [[ESSoundDownloadManager sharedManager] stateForEpisode:episode];
            if (downloadState == SFDownloadStateDownloaded) {
                downloadPercentView.hidden = YES;
            } else {
                downloadPercentView.hidden = NO;
                
                if (downloadState == SFDownloadStateErrored || downloadState == SFDownloadStatePaused) {
                    downloadPercentView.backgroundColor = [UIColor sf_colorWithRed:255 green:0 blue:0 alpha:72];
                } else {
                    downloadPercentView.backgroundColor = [UIColor sf_colorWithRed:0 green:255 blue:0 alpha:27];
                }
                
                float percent = [[ESSoundDownloadManager sharedManager] downloadedPercentForEpisode:episode];
                CGRect tmpFrame = downloadPercentView.frame;
                tmpFrame.size.width = cell.frame.size.width * percent;
                if (tmpFrame.size.width == 0.0f) {
                    tmpFrame.size.width = 2.0f;
                }
                downloadPercentView.frame = tmpFrame;
            }
        }
        
    }] identifier:@"refreshTimer"];
    
    return cell;
}

//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    static NSString *identifier = @"identifier";
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
//    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
//        cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0f];
//        cell.textLabel.adjustsFontSizeToFitWidth = YES;
//        cell.textLabel.numberOfLines = 3;
//        cell.detailTextLabel.font = [UIFont systemFontOfSize:13.0f];
//        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
//    }
//    
//    ESEpisode *episode = [_downloadingEpisodes objectAtIndex:indexPath.row];
//    SFDownloadState downloadState = [[ESSoundDownloadManager sharedManager] stateForEpisode:episode];
//    cell.textLabel.text = [episode simpleTitle];
//    cell.textLabel.textColor = (downloadState == SFDownloadStateErrored || downloadState == SFDownloadStatePaused) ? [UIColor lightGrayColor] : [UIColor blackColor];
//    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f%%", [[_keyEpisodeIdValuePercent objectForKey:episode.uid] floatValue] * 100];
//    
//    return cell;
//}

@end
