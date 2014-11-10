//
//  SFFileFragment.h
//  esl
//
//  Created by yangzexin on 11/10/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SFFileFragment : NSObject <NSCoding>

@property (nonatomic, copy, readonly) NSString *URLString;
@property (nonatomic, assign, readonly) unsigned long long offset;
@property (nonatomic, assign, readonly) unsigned long long size;
@property (nonatomic, assign, readonly) unsigned long long downloadedSize;
@property (nonatomic, assign, readonly) BOOL finished;

@property (nonatomic, assign) BOOL uncuttable;

@property (nonatomic, assign) BOOL downloading;

- (void)setContentLength:(unsigned long long)contentLength;

- (void)increaseDownloadedSize:(NSUInteger)size;

- (void)setDidFinish;
- (void)setDidFailWithCurrentDownloadedSize;

- (unsigned long long)writingOffset;

- (SFFileFragment *)fragmentByHalfCutting;

+ (instancetype)fragmentWithURLString:(NSString *)URLString offset:(unsigned long long)offset;
+ (instancetype)fragmentWithURLString:(NSString *)URLString offset:(unsigned long long)offset size:(unsigned long long)size;

@end
