//
//  ESLocalEpisodesController.m
//  esl
//
//  Created by yangzexin on 10/27/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESLocalEpisodesController.h"

#import "ESEpisode.h"
#import "ESESLEpisodeManager.h"
#import "ESViewEpisodeController.h"

@interface ESLocalEpisodesController ()

@property (nonatomic, strong) NSArray *episodes;

@end

@implementation ESLocalEpisodesController

- (void)loadView
{
    [super loadView];
    
    self.title = @"My Episodes";
    
    __weak typeof(self) weakSelf = self;
    self.navigationItem.rightBarButtonItem = [SFBlockedBarButtonItem blockedBarButtonItemWithBarButtonSystemItem:UIBarButtonSystemItemDone tap:^{
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.episodes.count == 0) {
        NSArray *episodes = [[ESESLEpisodeManager sharedManager] downloadedEpisodes];
        NSMutableArray *reversedEpisodes = [NSMutableArray array];
        [episodes enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [reversedEpisodes addObject:obj];
        }];
        self.episodes = reversedEpisodes;
        [self.tableView reloadData];
    }
}

- (void)_viewEpisode:(ESEpisode *)episode
{
    ESViewEpisodeController *controller = [ESViewEpisodeController viewEpisodeControllerWithEpisode:episode];
    controller.episodeManager = [ESESLEpisodeManager sharedManager];
    __weak typeof(self) weakSelf = self;
    controller.navigationItem.rightBarButtonItem = [SFBlockedBarButtonItem blockedBarButtonItemWithBarButtonSystemItem:UIBarButtonSystemItemDone tap:^{
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

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [[ESESLEpisodeManager sharedManager] removeDownloadedEpisode:[self.episodes objectAtIndex:indexPath.row]];
        NSMutableArray *newEpisodes = [NSMutableArray arrayWithArray:self.episodes];
        [newEpisodes removeObjectAtIndex:indexPath.row];
        self.episodes = newEpisodes;
        [tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tableView endUpdates];
    }
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
    cell.detailTextLabel.text = [NSString stringWithFormat:@"\n%@\n%@", episode.date, episode.formattedIntrodution];
    
    return cell;
}

@end
