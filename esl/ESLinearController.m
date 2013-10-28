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
    [self addView:view animated:NO];
}

- (void)insertView:(UIView *)view atIndex:(NSInteger)index
{
    [self insertView:view atIndex:index animated:NO];
}

- (void)removeView:(UIView *)view
{
    [self removeView:view animated:NO];
}

- (void)setBounces:(BOOL)bounces
{
    self.tableView.bounces = bounces;
}

- (BOOL)bounces
{
    return self.tableView.bounces;
}

- (void)addView:(UIView *)view animated:(BOOL)animated
{
    if (self.views == nil) {
        self.views = [NSMutableArray array];
    }
    [self.views addObject:view];
    if (animated) {
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.views.count - 1 inSection:0]]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    } else {
        [self.tableView reloadData];
    }
}

- (void)insertView:(UIView *)view atIndex:(NSInteger)index animated:(BOOL)animated
{
    if (self.views == nil) {
        self.views = [NSMutableArray array];
    }
    [self.views insertObject:view atIndex:index];
    if (animated) {
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    } else {
        [self.tableView reloadData];
    }
}

- (BOOL)isViewExists:(UIView *)view
{
    return self.views.count !=0 && [self.views indexOfObject:view] != NSNotFound;
}

- (void)removeView:(UIView *)view animated:(BOOL)animated
{
    NSUInteger index = NSNotFound;
    if (self.views.count != 0 && (index = [self.views indexOfObject:view]) != NSNotFound) {
        [self.views removeObject:view];
        if (animated) {
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]]
                                  withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        } else {
            [self.tableView reloadData];
        }
    }
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
