//
//  SFFileCache.h
//  
//
//  Created by yangzexin on 10/16/13.
//  Copyright (c) 2013 __MyCompany__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFCacheManager.h"

@protocol SFJSONOperation <NSObject>

- (id)objectFromJSONString:(NSString *)JSONString;
- (NSString *)JSONStringFromObject:(id)object;

@end

@interface SFFileCache : NSObject <SFCache>

@property (nonatomic, strong) id<SFCacheDecorator> cacheDecorator;
@property (nonatomic, strong) id<SFJSONOperation> JSONOperation;

@property (nonatomic, readonly) NSString *cachedDataFilePath;

+ (instancetype)cacheWithIdentifier:(NSString *)identifier folderPath:(NSString *)folerPath;
+ (instancetype)cacheWithIdentifier:(NSString *)identifier folderPath:(NSString *)folerPath data:(NSData *)data applicationIdentifier:(NSString *)applicationIdentifier;

- (void)write;
- (void)read;
- (void)clear;
- (BOOL)isCacheExists;

@end
