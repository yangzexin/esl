//
//  SFPreparedFileWriter.h
//  esl
//
//  Created by yangzexin on 11/10/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFFileWritable.h"
#import "SFCancellable.h"

@interface SFPreparedFileWriter : NSObject <SFPreparedFileWritable>

- (instancetype)initWithFilePath:(NSString *)filePath;

@end
