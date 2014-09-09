//
//  AppDelegate+SharedUtils.m
//  esl
//
//  Created by yangzexin on 9/9/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "AppDelegate+SharedUtils.h"

@implementation AppDelegate (SharedUtils)

+ (LevelDB *)levelDBWithName:(NSString *)name
{
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    documentPath = [documentPath stringByAppendingPathComponent:@"Configuration.docset"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:documentPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:documentPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    LevelDB *db = [[LevelDB alloc] initWithPath:[documentPath stringByAppendingPathComponent:name] andName:name];
    
    return db;
}

@end
