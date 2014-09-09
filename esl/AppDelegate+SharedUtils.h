//
//  AppDelegate+SharedUtils.h
//  esl
//
//  Created by yangzexin on 9/9/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"
#import <Objective-LevelDB/LevelDB.h>

@interface AppDelegate (SharedUtils)

+ (NSString *)configurationPath;

+ (LevelDB *)levelDBWithName:(NSString *)name;

@end
