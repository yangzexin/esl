//
//  SFViewController.h
//  SimpleFramework
//
//  Created by yangzexin on 13-7-4.
//  Copyright (c) 2013年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SFViewController : UIViewController

@end

@interface SFViewController (Observer)

- (void)addViewWillAppearObserver:(id)observer usingBlock:(void(^)(BOOL animated))block;
- (void)removeViewWillAppearObserver:(id)observer;

- (void)addViewDidAppearObserver:(id)observer usingBlock:(void(^)(BOOL animated))block;
- (void)removeViewDidAppearObserver:(id)observer;

- (void)addViewDidDisappearObserver:(id)observer usingBlock:(void(^)(BOOL animated))block;
- (void)removeViewDidDisappearObserver:(id)observer;

- (void)addViewWillDisappearObserver:(id)observer usingBlock:(void(^)(BOOL animated))block;
- (void)removeViewWillDisappearObserver:(id)observer;

- (void)addViewDidLoadObserver:(id)observer usingBlock:(void(^)())block;
- (void)removeViewDidLoadObserver:(id)observer;

- (void)addLoadViewObserver:(id)observer usingBlock:(void(^)())block;
- (void)removeLoadViewObserver:(id)observer;

@end