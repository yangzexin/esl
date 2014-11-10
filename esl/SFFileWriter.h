//
//  SFFileWriter.h
//  esl
//
//  Created by yangzexin on 11/10/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SFFileWriter : NSObject

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, strong) NSFileHandle *fileHandle;

- (id)initWithFilePath:(NSString *)filePath memoryCacheSizeInMegabyte:(float)memoryCacheSizeInMegabyte;
- (unsigned long long)prepareForWriting;
- (void)appendWithData:(NSData *)data;
- (void)closeFile;

@end
