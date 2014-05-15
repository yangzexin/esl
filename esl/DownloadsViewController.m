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

@end

@implementation DownloadsViewController

- (id)init
{
    self = [super init];
    
    self.title = NSLocalizedString(@"Downloads", nil);
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setLeftBarButtonItemAsSideMenuSwitcher];
    
    @weakify(self);
    [self addRepositionSupportedObject:[SFRepeatTimer timerStartWithTimeInterval:1.0f tick:^{
        @strongify(self);
        self.downloadingEpisodes = [[ESSoundDownloadManager sharedManager] downloadingEpisodes];
        NSMutableDictionary *keyEpisodeIdValuePercent = [NSMutableDictionary dictionary];
        for (ESEpisode *episode in _downloadingEpisodes) {
            [keyEpisodeIdValuePercent setObject:[NSNumber numberWithFloat:[[ESSoundDownloadManager sharedManager] downloadedPercentForEpisode:episode]] forKey:episode.uid];
        }
        self.keyEpisodeIdValuePercent = keyEpisodeIdValuePercent;
        [self.tableView reloadData];
    }] identifier:@"CheckDownloadsState"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ESEpisode *episode = [_downloadingEpisodes objectAtIndex:indexPath.row];
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
    
    [UIActionSheet actionSheetWithTitle:@"" completion:^(NSInteger buttonIndex, NSString *buttonTitle) {
        if ([buttonTitle isEqualToString:@"查看"]) {
            [self.navigationController pushViewController:[EpisodeDetailViewController controllerWithViewModel:[EpisodeDetailViewModel viewModelWithEpisode:episode]] animated:YES];
        } else if ([buttonTitle isEqualToString:@"继续下载"]) {
            [[ESSoundDownloadManager sharedManager] downloadEpisode:episode];
        } else if ([buttonTitle isEqualToString:@"重新下载"]) {
            [[ESSoundDownloadManager sharedManager] removeEpisode:episode];
            [[ESSoundDownloadManager sharedManager] downloadEpisode:episode];
        } else if ([buttonTitle isEqualToString:@"暂停下载"]) {
            [[ESSoundDownloadManager sharedManager] pauseDownloadingEpisode:episode];
        } else if ([buttonTitle isEqualToString:@"删除"]) {
            [[ESSoundDownloadManager sharedManager] removeEpisode:episode];
        }
    } cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitleList:actionTitles];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _downloadingEpisodes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"identifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.textLabel.font = [UIFont systemFontOfSize:15.0f];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0f];
    }
    
    ESEpisode *episode = [_downloadingEpisodes objectAtIndex:indexPath.row];
    SFDownloadState downloadState = [[ESSoundDownloadManager sharedManager] stateForEpisode:episode];
    cell.textLabel.text = [episode title];
    cell.textLabel.textColor = (downloadState == SFDownloadStateErrored || downloadState == SFDownloadStatePaused) ? [UIColor lightGrayColor] : [UIColor blackColor];;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f%%", [[_keyEpisodeIdValuePercent objectForKey:episode.uid] floatValue] * 100];
    
    return cell;
}

@end
