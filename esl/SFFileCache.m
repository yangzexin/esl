//
//  SFFileCache.m
//  
//
//  Created by yangzexin on 10/16/13.
//  Copyright (c) 2013 __MyCompany__. All rights reserved.
//

#import "SFFileCache.h"

@interface SFFileCache ()

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, strong) NSDate *createDate;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, copy) NSString *applicationIdentifier;
@property (nonatomic, copy) NSString *folderPath;

@end

@implementation SFFileCache

- (NSString *)cacheFolder
{
    NSString *cacheFolder = self.folderPath;
    if ([[NSFileManager defaultManager] fileExistsAtPath:cacheFolder] == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheFolder withIntermediateDirectories:NO attributes:Nil error:nil];
    }
    return cacheFolder;
}

- (NSString *)cachedDataFilePath
{
    return [self _cacheDataFilePathWithWrappedIdentifier:[self _wrappedIdentifier]];
}

- (NSString *)_wrappedIdentifier
{
    return [self.identifier sf_stringByEncryptingUsingMD5];
}

- (NSData *)_decoratedDataByDecoratingWithOriginalData:(NSData *)data
{
    NSData *resultData = data;
    id<SFCacheDecorator> decorator = self.cacheDecorator;
    if (decorator != nil) {
        resultData = [decorator decoratedDataByDecoratingWithOriginalData:data];
    }
    return resultData;
}

- (NSData *)_originalDataByRestoringWithDecoratedData:(NSData *)data
{
    NSData *resultData = data;
    id<SFCacheDecorator> decorator = self.cacheDecorator;
    if (decorator != nil) {
        resultData = [decorator originalDataByRestoringWithDecoratedData:data];
    }
    return resultData;
}

- (NSString *)_cacheInfoFilePathWithoutFileExtensionsWithWrappedIdentifier:(NSString *)wrappedIdentifier
{
    return [[self cacheFolder] stringByAppendingPathComponent:wrappedIdentifier];
}

- (NSString *)_cacheInfoFilePathWithWrappedIdentifier:(NSString *)wrappedIdentifier
{
    return [[self _cacheInfoFilePathWithoutFileExtensionsWithWrappedIdentifier:wrappedIdentifier] stringByAppendingPathExtension:@"plist"];
}

- (NSString *)_cacheDataFilePathWithWrappedIdentifier:(NSString *)wrappedIdentifier
{
    return [self _cacheInfoFilePathWithoutFileExtensionsWithWrappedIdentifier:wrappedIdentifier];
}

- (NSDictionary *)_infoDictionaryWithContentOfFile:(NSString *)filePath
{
    NSDictionary *infoDictionary = nil;
    if (self.JSONOperation != nil && self.cacheDecorator != nil) {
        NSData *cacheInfoData = [NSData dataWithContentsOfFile:filePath];
        NSString *JSONString = [[NSString alloc] initWithData:[self _originalDataByRestoringWithDecoratedData:cacheInfoData] encoding:NSUTF8StringEncoding];
        infoDictionary = [self.JSONOperation objectFromJSONString:JSONString];
    } else {
        infoDictionary = [NSDictionary dictionaryWithContentsOfFile:filePath];
    }
    return infoDictionary;
}

- (void)read
{
    NSString *wrappedIdentifier = [self _wrappedIdentifier];
    if (wrappedIdentifier.length != 0) {
        NSString *cacheInfoFilePath = [self _cacheInfoFilePathWithWrappedIdentifier:wrappedIdentifier];
        NSString *cacheDataFilePath = [self _cacheDataFilePathWithWrappedIdentifier:wrappedIdentifier];
        
        NSDictionary *cacheInfoDictionary = [self _infoDictionaryWithContentOfFile:cacheInfoFilePath];
        self.applicationIdentifier = [cacheInfoDictionary objectForKey:@"applicationIdentifier"];
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        self.createDate = [dateFormatter dateFromString:[cacheInfoDictionary objectForKey:@"createDate"]];
        
        self.data = [self _originalDataByRestoringWithDecoratedData:[NSData dataWithContentsOfFile:cacheDataFilePath]];
    }
}

- (void)write
{
    self.createDate = [NSDate new];
    
    NSString *wrappedIdentifier = [self _wrappedIdentifier];
    if (wrappedIdentifier.length != 0) {
        [self clear];
        
        NSString *cacheInfoFilePath = [self _cacheInfoFilePathWithWrappedIdentifier:wrappedIdentifier];
        NSString *cacheDataFilePath = [self _cacheDataFilePathWithWrappedIdentifier:wrappedIdentifier];
        
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
        NSString *createDateString = [dateFormatter stringFromDate:self.createDate];
        NSDictionary *cacheInfoDictionary = @{@"identifier" : self.identifier,
                                              @"createDate" : createDateString,
                                              @"applicationIdentifier" : self.applicationIdentifier
                                              };
        if (self.JSONOperation != nil && self.cacheDecorator != nil) {
            NSString *cacheInfoJSONString = [self.JSONOperation JSONStringFromObject:cacheInfoDictionary];
            NSData *cacheInfoData = [self _decoratedDataByDecoratingWithOriginalData:[cacheInfoJSONString dataUsingEncoding:NSUTF8StringEncoding]];
            [cacheInfoData writeToFile:cacheInfoFilePath atomically:NO];
        } else {
            [cacheInfoDictionary writeToFile:cacheInfoFilePath atomically:NO];
        }
        
        NSData *decoratedData = [self _decoratedDataByDecoratingWithOriginalData:self.data];
        [decoratedData writeToFile:cacheDataFilePath atomically:NO];
    }
}

- (void)clear
{
    NSString *wrappedIdentifier = [self _wrappedIdentifier];
    if (wrappedIdentifier.length != 0) {
        NSString *cacheInfofilePath = [self _cacheInfoFilePathWithWrappedIdentifier:wrappedIdentifier];
        NSString *cacheDataFilePath = [self _cacheDataFilePathWithWrappedIdentifier:wrappedIdentifier];
        [[NSFileManager defaultManager] removeItemAtPath:cacheInfofilePath error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:cacheDataFilePath error:nil];
    }
}

- (BOOL)isCacheExists
{
    return [[NSFileManager defaultManager] fileExistsAtPath:self.cachedDataFilePath];
}

+ (instancetype)cacheWithIdentifier:(NSString *)identifier folderPath:(NSString *)folerPath
{
    return [self cacheWithIdentifier:identifier folderPath:folerPath data:nil applicationIdentifier:nil];
}

+ (instancetype)cacheWithIdentifier:(NSString *)identifier folderPath:(NSString *)folerPath data:(NSData *)data applicationIdentifier:(NSString *)applicationIdentifier
{
    SFFileCache *fileCache = [SFFileCache new];
    fileCache.identifier = identifier;
    fileCache.folderPath = folerPath;
    fileCache.data = data;
    fileCache.applicationIdentifier = applicationIdentifier;
    return fileCache;
}

@end
