//
//  MenuController.h
//  esl
//
//  Created by yangzexin on 4/3/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESTableViewController.h"

@interface MenuController : ESTableViewController

@property (nonatomic, strong, readonly) NSArray *menuItemTitles;
@property (nonatomic, copy) void(^menuItemSelectHandler)(NSString *menuItemTitle);

+ (instancetype)controllerWithMenuItemTitles:(NSArray *)menuItemTitles;

@end
