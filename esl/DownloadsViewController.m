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
    cell.textLabel.text = [episode title];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f%%", [[_keyEpisodeIdValuePercent objectForKey:episode.uid] floatValue] * 100];
    
    return cell;
}

@end
