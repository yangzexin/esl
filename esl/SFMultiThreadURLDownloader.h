//
//  SFMultiThreadURLDownloader.h
//  esl
//
//  Created by yangzexin on 11/10/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFURLDownloader.h"
#import "SFCancellable.h"

@interface SFMultiThreadFileWriter : NSObject

- (instancetype)initWithFilePath:(NSString *)filePath;

- (SFCancellable *)openWithCreatingEmptyFileWithSize:(unsigned long long)size completion:(void(^)(BOOL success))completion;

- (void)writeData:(NSData *)data offset:(unsigned long long)offset;

@end

@interface SFMultiThreadURLDownloader : NSObject <SFURLDownloader>

- (id)initWithURLString:(NSString *)URLString;

@end
