//
//  ESTableViewController.m
//  esl
//
//  Created by yangzexin on 10/25/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESTableViewController.h"

@implementation ESTableViewController {
    UITableView *tableView;
}

- (void)loadView
{
    [super loadView];
    
    self->tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:[self tableViewStyle]];
    self->tableView.delegate = self;
    self->tableView.dataSource = self;
    self->tableView.backgroundColor = [UIColor whiteColor];
    self->tableView.backgroundView = [UIView new];
    self->tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self->tableView];
}

- (UITableViewStyle)tableViewStyle
{
    return UITableViewStylePlain;
}

- (UITableView *)tableView
{
    return self->tableView;
}

#pragma mark - UITableViewDelegate & UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView_ cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"null_cell";
    UITableViewCell *cell = [tableView_ dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.textLabel.text = @"NULL CELL";
    return cell;
}

@end
