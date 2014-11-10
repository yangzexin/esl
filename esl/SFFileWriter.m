//
//  SFFileWriter.m
//  esl
//
//  Created by yangzexin on 11/10/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "SFFileWriter.h"

@interface SFFileWriter ()

@property (nonatomic, assign) float memoryCacheSizeInMegabyte;

@property (nonatomic, strong) NSMutableData *cachedData;

@end

@implementation SFFileWriter

- (void)dealloc
{
    [_fileHandle closeFile];
}

- (id)initWithFilePath:(NSString *)filePath memoryCacheSizeInMegabyte:(float)memoryCacheSizeInMegabyte
{
    self = [super init];
    
    self.filePath = filePath;
    self.memoryCacheSizeInMegabyte = memoryCacheSizeInMegabyte;
    
    return self;
}

- (unsigned long long)prepareForWriting
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:_filePath]) {
        [[NSFileManager defaultManager] createFileAtPath:_filePath contents:[NSData data] attributes:nil];
    }
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:_filePath];
    unsigned long long skipedBytes = [_fileHandle seekToEndOfFile];
    
    self.cachedData = [NSMutableData data];
    
    return skipedBytes;
}

- (void)_writeCachedData
{
    [_fileHandle writeData:_cachedData];
    [_cachedData setData:[NSData data]];
}

- (void)appendWithData:(NSData *)data
{
    [_cachedData appendData:data];
    if (_memoryCacheSizeInMegabyte * 1024 * 1024 < _cachedData.length) {
        [self _writeCachedData];
    }
}

- (void)closeFile
{
    if (_cachedData.length != 0) {
        [self _writeCachedData];
    }
    [_fileHandle closeFile];
}

@end
