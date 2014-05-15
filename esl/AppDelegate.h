//
//  AppDelegate.h
//  esl
//
//  Created by yangzexin on 10/25/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <UIKit/UIKit.h>

OBJC_EXPORT NSString *const ESEnableSideMenuGestureNotification;
OBJC_EXPORT NSString *const ESDisableSideMenuGestureNotification;
OBJC_EXPORT NSString *const ESShowSideMenuNotification;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
