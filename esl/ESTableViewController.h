//
//  ESTableViewController.h
//  esl
//
//  Created by yangzexin on 10/25/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESViewController.h"

@interface ESTableViewController : ESViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, readonly) UITableView *tableView;

- (UITableViewStyle)tableViewStyle;

@end
