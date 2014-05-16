//
//  MenuController.m
//  esl
//
//  Created by yangzexin on 4/3/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "MenuController.h"

#import "SFiOSKit.h"

@interface MenuController ()

@property (nonatomic, strong) NSArray *menuItemTitles;

@end

@implementation MenuController

+ (instancetype)controllerWithMenuItemTitles:(NSArray *)menuItemTitles
{
    MenuController *controller = [self new];
    controller.menuItemTitles = menuItemTitles;
    
    return controller;
}

- (void)loadView
{
    [super loadView];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = [UIView new];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    @weakify(self);
    [[self.tableView rac_signalForSelector:@selector(reloadData)] subscribeNext:^(id x) {
        @strongify(self);
        self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, self.tableView.contentSize.height < self.tableView.frame.size.height ? ((self.tableView.frame.size.height - self.tableView.contentSize.height) / 2 - 70) : 0)];
    }];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (_menuItemSelectHandler) {
        _menuItemSelectHandler([_menuItemTitles objectAtIndex:indexPath.row]);
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _menuItemTitles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"__id";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.textLabel.font = [UIFont systemFontOfSize:19.0f];
        cell.backgroundView = [UIView new];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    NSString *menuItemTitle = [_menuItemTitles objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"    %@", menuItemTitle];
    
    return cell;
}

@end
