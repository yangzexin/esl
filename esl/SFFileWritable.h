//
//  SFFileWritable.h
//  esl
//
//  Created by yangzexin on 11/10/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

@protocol SFFileWritable <NSObject>

- (void)writeData:(NSData *)data offset:(unsigned long long)offset;
- (void)close;

@end

@protocol SFPreparedFileWritable <SFFileWritable>

- (void)preparingForFileWritingWithFileSize:(unsigned long long)fileSize;

@end