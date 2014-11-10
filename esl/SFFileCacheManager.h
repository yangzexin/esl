//
//  SFCacheUtils.h
//  
//
//  Created by yangzexin on 10/15/13.
//  Copyright (c) 2013 __MyCompany__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFFileCache.h"

@protocol SFCacheDecorator;

@interface SFFileCacheManager : NSObject <SFCacheManager>

@property (nonatomic, strong) id<SFCacheDecorator> cacheDecorator;
@property (nonatomic, strong) id<SFJSONOperation> JSONOperation;

- (NSString *)cachedDataFilePathWithIdentifier:(NSString *)identifier;

+ (instancetype)fileCacheManagerWithFolderPath:(NSString *)folderPath;

@end
