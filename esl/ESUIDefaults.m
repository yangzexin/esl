//
//  ESUIDefaults.m
//  esl
//
//  Created by yangzexin on 10/25/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESUIDefaults.h"

@implementation ESUIDefaults

+ (UINavigationController *)navigationControllerWithRootViewController:(UIViewController *)viewController
{
    UINavigationController *controller = [[UINavigationController alloc] initWithRootViewController:viewController];
    
    return controller;
}

+ (UINavigationController *)navigationController
{
    return [self navigationControllerWithRootViewController:nil];
}

@end
