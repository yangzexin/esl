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
    
    self.title = @"episodes";
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_episodesDidUpdateNotification:) name:ESEpisodeDidUpdateNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 20;
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
