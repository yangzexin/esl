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

+ (LevelDB *)keyURLStringValueHTML
{
    static LevelDB *keyURLStringValueHTML = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keyURLStringValueHTML = [self levelDBWithName:@"keyURLStringValueHTML"];
        
        [keyURLStringValueHTML setEncoder:^NSData *(LevelDBKey * key, NSString *object){
            return [object dataUsingEncoding:NSUTF8StringEncoding];
        }];
        [keyURLStringValueHTML setDecoder:^id(LevelDBKey *key, NSData *data){
            return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }];
    });
    
    return keyURLStringValueHTML;
}

@end
