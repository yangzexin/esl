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
#import "SFFileWritable.h"

@interface SFMultiThreadURLDownloader : NSObject <SFURLDownloader>

- (id)initWithURLString:(NSString *)URLString fileWritable:(id<SFPreparedFileWritable>)fileWritable;

@end
