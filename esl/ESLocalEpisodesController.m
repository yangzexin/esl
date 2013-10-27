//
//  ESLocalEpisodesController.m
//  esl
//
//  Created by yangzexin on 10/27/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESLocalEpisodesController.h"
#import "SFBlockedBarButtonItem.h"

@implementation ESLocalEpisodesController

- (void)loadView
{
    [super loadView];
    
    self.title = @"Local Episodes";
    
    __weak typeof(self) weakSelf = self;
    self.navigationItem.rightBarButtonItem = [SFBlockedBarButtonItem blockedBarButtonItemWithBarButtonSystemItem:UIBarButtonSystemItemDone eventHandler:^{
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
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
