//
//  ESUIDefaults.m
//  esl
//
//  Created by yangzexin on 10/25/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESUIDefaults.h"
#import "ESNavigationController.h"

@implementation ESUIDefaults

+ (UINavigationController *)navigationControllerWithRootViewController:(UIViewController *)viewController
{
    UINavigationController *controller = [[ESNavigationController alloc] initWithRootViewController:viewController];
    
    return controller;
}

+ (UINavigationController *)navigationController
{
    return [self navigationControllerWithRootViewController:nil];
}

@end
