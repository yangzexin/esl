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

- (void)addView:(UIView *)view animated:(BOOL)animated;
- (void)insertView:(UIView *)view atIndex:(NSInteger)index animated:(BOOL)animated;
- (void)removeView:(UIView *)view animated:(BOOL)animated;

- (void)reloadView:(UIView *)view animated:(BOOL)animated;

- (BOOL)isViewExists:(UIView *)view;

@end
