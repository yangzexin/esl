//
//  SFCacheUtils.m
//  
//
//  Created by yangzexin on 10/15/13.
//  Copyright (c) 2013 __MyCompany__. All rights reserved.
//

#import "SFFileCacheManager.h"
#import "SFCacheUtils.h"

@interface SFFileCacheManager ()

@property (nonatomic, copy) NSString *folderPath;

@end

@implementation SFFileCacheManager

+ (instancetype)fileCacheManagerWithFolderPath:(NSString *)folderPath
{
    SFFileCacheManager *storage = [SFFileCacheManager new];
    storage.folderPath = folderPath;
    return storage;
}

- (NSString *)cachedDataFilePathWithIdentifier:(NSString *)identifier
{
    SFFileCache *fileCache = [SFFileCache cacheWithIdentifier:identifier folderPath:self.folderPath];
    return fileCache.cachedDataFilePath;
}

- (BOOL)isCacheExistsWithIdentifier:(NSString *)identifier
{
    SFFileCache *fileCache = [SFFileCache cacheWithIdentifier:identifier folderPath:self.folderPath];
    return [fileCache isCacheExists];
}

- (NSData *)cachedDataWithIdentifier:(NSString *)identifier filter:(id<SFCacheFilter>)filter
{
    NSData *cacheData = nil;
    SFFileCache *fileCache = [SFFileCache cacheWithIdentifier:identifier folderPath:self.folderPath];
    fileCache.cacheDecorator = self.cacheDecorator;
    fileCache.JSONOperation = self.JSONOperation;
    [fileCache read];
    if ([fileCache data] != nil && filter != nil && [filter isCacheValid:fileCache]) {
        cacheData = [fileCache data];
    } else {
        [fileCache clear];
    }
    return cacheData;
}

- (void)storeCacheWithIdentifier:(NSString *)identifier data:(NSData *)data
{
    SFFileCache *fileCache = [SFFileCache cacheWithIdentifier:identifier
                                                   folderPath:self.folderPath
                                                         data:data
                                        applicationIdentifier:[SFCacheUtils applicationIdentifier]];
    fileCache.cacheDecorator = self.cacheDecorator;
    fileCache.JSONOperation = self.JSONOperation;
    [fileCache write];
}

- (void)clearCacheWithIdentifier:(NSString *)identifier
{
    SFFileCache *fileCache = [SFFileCache cacheWithIdentifier:identifier folderPath:self.folderPath];
    [fileCache clear];
}

@end
