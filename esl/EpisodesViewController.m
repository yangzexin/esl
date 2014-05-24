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

#import "AppDelegate.h"

#import "SFiOSKit.h"

#import "ESSoundPlayContext.h"

@interface EpisodesViewController () <SFImageLabelDelegate>

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
        [refreshControl addTarget:self action:@selector(_refreshControlDidBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
    } else {
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(_refreshControlDidBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
        [self.tableView addSubview:refreshControl];
    }
    [self setLeftBarButtonItemAsSideMenuSwitcher];
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
    NSLog(@"viewWillAppear");
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
    NSLog(@"viewDidAppear");
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSLog(@"viewWillDisappear");
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    NSLog(@"viewDidDisappear");
}

#pragma mark - UI events
- (void)_refreshControlDidBeginRefreshing:(id)refreshControl
{
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
    [UIImagePickerController pickImageUsingActionSheetWithViewController:self completion:^(UIImage *selectedImage, BOOL cancelled) {
        
    }];
//    ESEpisode *episode = [self.viewModel.episodes objectAtIndex:indexPath.row];
//    [self.navigationController pushViewController:[EpisodeDetailViewController controllerWithViewModel:[EpisodeDetailViewModel viewModelWithEpisode:episode]] animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _viewModel.episodes.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ESEpisode *episode = [self.viewModel.episodes objectAtIndex:indexPath.row];
    return [episode titleFormatted].size.height + 20;
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
        [keyImageNameValueImage setObject:[label toImageLegacy] forKey:@"title"];
        
        label.text = @"📅";
        [keyImageNameValueImage setObject:[label toImageLegacy] forKey:@"date"];
        
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
//        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        imageLabel = [[SFImageLabel alloc] initWithFrame:CGRectMake(5, 7, cell.contentView.bounds.size.width - 10, cell.contentView.bounds.size.height)];
        imageLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        imageLabel.tag = 1001;
        imageLabel.delegate = self;
        imageLabel.drawsImageWithImageSize = YES;
        [cell.contentView addSubview:imageLabel];
    } else {
        imageLabel = (id)[cell.contentView viewWithTag:1001];
    }
    ESEpisode *episode = [self.viewModel.episodes objectAtIndex:indexPath.row];
//    cell.textLabel.text = episode.title;
//    cell.detailTextLabel.text = [NSString stringWithFormat:@"\n%@\n%@", episode.date, episode.formattedIntrodution];
    imageLabel.text = [episode titleFormatted];
    
    return cell;
}

@end
