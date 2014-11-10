//
//  SFPreparedFileWriter.m
//  esl
//
//  Created by yangzexin on 11/10/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "SFPreparedFileWriter.h"

@interface SFPreparedFileWriter ()

@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, strong) NSFileHandle *fileHandle;

@property (nonatomic, strong) NSMutableData *data;

@end

@implementation SFPreparedFileWriter

- (void)dealloc
{
    [self.fileHandle closeFile];
}

- (instancetype)initWithFilePath:(NSString *)filePath
{
    self = [super init];
    
    self.filePath = filePath;
    
    return self;
}

- (void)writeData:(NSData *)data offset:(unsigned long long)offset
{
    [self.fileHandle seekToFileOffset:offset];
    [self.fileHandle writeData:data];
    NSLog(@"%lld-%lld", offset, offset + data.length);
    [self.data appendData:data];
}

- (void)close
{
    [self.fileHandle closeFile];
    self.fileHandle = nil;
    [self.data writeToFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"test.png"] atomically:NO];
}

- (void)preparingForFileWritingWithFileSize:(unsigned long long)fileSize
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:nil];
    }
    [[NSFileManager defaultManager] createFileAtPath:self.filePath contents:[NSData data] attributes:nil];
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
    if (self.fileHandle) {
        if (fileSize != 0) {
            unsigned int sizeOfEmptyBytes = sizeof(char) * 1024 * 1024;
            if (fileSize < sizeOfEmptyBytes) {
                sizeOfEmptyBytes = (unsigned int)fileSize;
            }
            char *emptyBytes = malloc(sizeOfEmptyBytes);
            NSData *emptyData = [NSData dataWithBytes:emptyBytes length:sizeOfEmptyBytes];
            NSInteger numberOfEmptyDataWritingLoops = (NSInteger)(fileSize / (unsigned long long)sizeOfEmptyBytes);
            for (NSInteger i = 0; i < numberOfEmptyDataWritingLoops; ++i) {
                [self.fileHandle writeData:emptyData];
            }
            free(emptyBytes);
            
            unsigned int remainsEmptyDataSize = fileSize % sizeOfEmptyBytes;
            char *remainsBytes = malloc(remainsEmptyDataSize);
            [self.fileHandle writeData:[NSData dataWithBytes:remainsBytes length:remainsEmptyDataSize]];
            free(remainsBytes);
        }
    }
    self.data = [NSMutableData data];
}

@end
