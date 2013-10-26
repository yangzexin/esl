//
//  TrackListController.m
//  esl
//
//  Created by yangzexin on 10/25/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESTrackListController.h"
#import "ESEpisode.h"
#import "ESServiceFactory.h"

@implementation ESTrackListController {
    NSArray *episodes;
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
    [self requestService:[ESServiceFactory eslEpisodes] completion:^(id resultObject, NSError *error) {
        
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

@end
