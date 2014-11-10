//
//  SFMultiThreadURLDownloader.m
//  esl
//
//  Created by yangzexin on 11/10/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "SFMultiThreadURLDownloader.h"

@interface SFMultiThreadFileWriter ()

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, assign) dispatch_queue_t queue;

@property (nonatomic, strong) NSFileHandle *fileHandle;

@end

@implementation SFMultiThreadFileWriter

- (void)dealloc
{
    dispatch_release(self.queue);
}

- (instancetype)initWithFilePath:(NSString *)filePath
{
    self = [super init];
    
    self.filePath = filePath;
    self.queue = dispatch_queue_create([[NSString stringWithFormat:@"fileWriter-%@", filePath] UTF8String], NULL);
    
    return self;
}

- (SFCancellable *)openWithCreatingEmptyFileWithSize:(unsigned long long)size completion:(void(^)(BOOL success))completion
{
    __block BOOL cancelled = NO;
    
    dispatch_async(self.queue, ^{
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.filePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:nil];
        }
        [[NSFileManager defaultManager] createFileAtPath:self.filePath contents:[NSData data] attributes:nil];
        self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
        if (self.fileHandle) {
            unsigned int sizeOfEmptyBytes = sizeof(char) * 1024 * 1024;
            if (size < sizeOfEmptyBytes) {
                sizeOfEmptyBytes = (unsigned int)size;
            }
            char *emptyBytes = malloc(sizeOfEmptyBytes);
            NSData *emptyData = [NSData dataWithBytes:emptyBytes length:sizeOfEmptyBytes];
            NSInteger numberOfEmptyDataWritingLoops = (NSInteger)(size / (unsigned long long)sizeOfEmptyBytes);
            for (NSInteger i = 0; i < numberOfEmptyDataWritingLoops; ++i) {
                if (cancelled) {
                    break;
                }
                [self.fileHandle writeData:emptyData];
            }
            if (!cancelled) {
                unsigned int remainsEmptyDataSize = size % sizeOfEmptyBytes;
                [self.fileHandle writeData:[NSData dataWithBytes:malloc(remainsEmptyDataSize) length:remainsEmptyDataSize]];
                
                completion(YES);
            } else {
                completion(NO);
            }
        } else {
            completion(NO);
        }
    });
    
    return [SFCancellable cancellableWithWhenCancel:^{
        cancelled = YES;
    }];
}

- (void)writeData:(NSData *)data offset:(unsigned long long)offset
{
    [self writeData:data offset:offset completion:nil];
}

- (void)writeData:(NSData *)data offset:(unsigned long long)offset completion:(void(^)())completion
{
    dispatch_async(self.queue, ^{
        [self.fileHandle seekToFileOffset:offset];
        [self.fileHandle writeData:data];
    });
}

@end

@interface SFMultiThreadURLDownloader ()

@property (nonatomic, copy) NSString *URLString;
@property (nonatomic, assign, getter=isDownloading) BOOL downloading;

@property (nonatomic, strong) NSFileHandle *fileHandle;

@end

@implementation SFMultiThreadURLDownloader

@synthesize delegate;

- (id)initWithURLString:(NSString *)URLString
{
    self = [super init];
    
    self.URLString = URLString;
    
    return self;
}

- (NSString *)downloadingURLString
{
    return self.URLString;
}

- (void)start
{
    //TODO:open file writer and create empty file
}

- (void)resume
{
}

- (void)pause
{
}

- (void)stop
{
}

- (CGFloat)downloadedPercent
{
    return .0f;
}

- (void)willRemoveFromObjectRepository
{
}

- (BOOL)shouldRemoveFromObjectRepository
{
    return NO;
}

#pragma mark - private methods
- (SFCancellable *)_createEmptyFileWithSize:(unsigned long long)fileSize completion:(void(^)())completion
{
    __block BOOL cancelled = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
    });
    
    return [SFCancellable cancellableWithWhenCancel:^{
        cancelled = YES;
    }];
}

- (void)_writeData:(NSData *)data offset:(unsigned long long)offset
{
    [self.fileHandle seekToFileOffset:offset];
    [self.fileHandle writeData:data];
}

@end
