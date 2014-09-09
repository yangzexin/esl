//
//  AppDelegate+SharedUtils.m
//  esl
//
//  Created by yangzexin on 9/9/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "AppDelegate+SharedUtils.h"

@implementation AppDelegate (SharedUtils)

+ (NSString *)configurationPath
{
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    documentPath = [documentPath stringByAppendingPathComponent:@"Configuration.docset"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:documentPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:documentPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return documentPath;
}

+ (LevelDB *)levelDBWithName:(NSString *)name
{
    LevelDB *db = [[LevelDB alloc] initWithPath:[[self configurationPath] stringByAppendingPathComponent:name] andName:name];
    
    return db;
}

@end
