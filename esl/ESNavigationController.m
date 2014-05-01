//
//  ESNavigationController.m
//  esl
//
//  Created by yangzexin on 5/1/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "ESNavigationController.h"
#import "AppDelegate.h"

@interface ESNavigationController  () <UINavigationControllerDelegate>

@end

@implementation ESNavigationController

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    
    self.delegate = self;
    
    return self;
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (self.viewControllers.count == 1) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ESEnableSideMenuGestureNotification object:nil userInfo:nil];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:ESDisableSideMenuGestureNotification object:nil userInfo:nil];
    }
}

@end
