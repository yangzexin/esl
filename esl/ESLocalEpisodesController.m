//
//  ESLocalEpisodesController.m
//  esl
//
//  Created by yangzexin on 10/27/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESLocalEpisodesController.h"
#import "SFBlockedBarButtonItem.h"
#import "ESEpisode.h"
#import "ESEpisodeManager.h"
#import "ESViewEpisodeController.h"
#import "ESUIDefaults.h"

@interface ESLocalEpisodesController ()

@property (nonatomic, strong) NSArray *episodes;

@end

@implementation ESLocalEpisodesController

- (void)loadView
{
    [super loadView];
    
    self.title = @"My Episodes";
    
    __weak typeof(self) weakSelf = self;
    self.navigationItem.rightBarButtonItem = [SFBlockedBarButtonItem blockedBarButtonItemWithBarButtonSystemItem:UIBarButtonSystemItemDone eventHandler:^{
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.episodes.count == 0) {
        self.episodes = [[ESEpisodeManager sharedManager] downloadedEpisodes];
        [self.tableView reloadData];
    }
}

- (void)_viewEpisode:(ESEpisode *)episode
{
    ESViewEpisodeController *controller = [ESViewEpisodeController viewEpisodeControllerWithEpisode:episode];
    __weak typeof(self) weakSelf = self;
    controller.navigationItem.rightBarButtonItem = [SFBlockedBarButtonItem blockedBarButtonItemWithBarButtonSystemItem:UIBarButtonSystemItemDone eventHandler:^{
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    }];
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
    cell.textLabel.text = episode.title;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"\n%@\n%@", episode.date, episode.introdution];
    
    return cell;
}

@end
