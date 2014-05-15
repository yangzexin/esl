//
//  SettingsViewController.m
//  esl
//
//  Created by yangzexin on 4/3/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "SettingsViewController.h"

@implementation SettingsViewController

- (id)init
{
    self = [super init];
    
    self.title = NSLocalizedString(@"Settings", nil);
    
    return self;
}

- (void)loadView
{
    [super loadView];
    [self setLeftBarButtonItemAsSideMenuSwitcher];
}

@end
