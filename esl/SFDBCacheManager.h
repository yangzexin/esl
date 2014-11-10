//
//  SFDBCacheManager.h
//  DemoProject
//
//  Created by yangzexin on 5/1/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFCacheManager.h"

@interface SFDBCacheManager : NSObject <SFCacheManager>

@property (nonatomic, strong) id<SFCacheDecorator> cacheDecorator;

+ (instancetype)cacheManagerInLibraryWithName:(NSString *)name;

@end
