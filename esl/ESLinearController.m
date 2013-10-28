//
//  ESLinearController.m
//  esl
//
//  Created by yangzexin on 10/27/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESLinearController.h"

@interface ESLinearController ()

@property (nonatomic, strong) NSMutableArray *views;

@end

@implementation ESLinearController

- (void)loadView
{
    [super loadView];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)addView:(UIView *)view
{
    if (self.views == nil) {
        self.views = [NSMutableArray array];
    }
    [self.views addObject:view];
    [self.tableView reloadData];
}

- (void)insertView:(UIView *)view atIndex:(NSInteger)index
{
    if (self.views == nil) {
        self.views = [NSMutableArray array];
    }
    [self.views insertObject:view atIndex:index];
    [self.tableView reloadData];
}

- (void)removeView:(UIView *)view
{
    [self.views removeObject:view];
    [self.tableView reloadData];
}

- (void)setBounces:(BOOL)bounces
{
    self.tableView.bounces = bounces;
}

- (BOOL)bounces
{
    return self.tableView.bounces;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIView *view = [self.views objectAtIndex:indexPath.row];
    return view.frame.size.height + view.frame.origin.y;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.views.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identfiier = @"__id__view";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identfiier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identfiier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    for (UIView *view in [cell.contentView subviews]) {
        [view removeFromSuperview];
    }
    [cell.contentView addSubview:[self.views objectAtIndex:indexPath.row]];
    
    return cell;
}

@end
