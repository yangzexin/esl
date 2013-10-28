//
//  ESLinearController.h
//  esl
//
//  Created by yangzexin on 10/27/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESTableViewController.h"

@interface ESLinearController : ESTableViewController

@property (nonatomic, assign) BOOL bounces;

- (void)addView:(UIView *)view;
- (void)insertView:(UIView *)view atIndex:(NSInteger)index;
- (void)removeView:(UIView *)view;

@end
