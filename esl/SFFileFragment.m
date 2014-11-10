//
//  SFFileFragment.m
//  esl
//
//  Created by yangzexin on 11/10/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "SFFileFragment.h"

@interface SFFileFragment ()

@property (nonatomic, copy) NSString *URLString;
@property (nonatomic, assign) unsigned long long offset;
@property (nonatomic, assign) unsigned long long size;
@property (nonatomic, assign) unsigned long long downloadedSize;
@property (nonatomic, assign) BOOL finished;

@end

@implementation SFFileFragment

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    self.offset = [[aDecoder decodeObjectForKey:@"offset"] longLongValue];
    self.size = [[aDecoder decodeObjectForKey:@"size"] longLongValue];
    self.URLString = [aDecoder decodeObjectForKey:@"URLString"];
    self.downloadedSize = [[aDecoder decodeObjectForKey:@"downloadedSize"] longLongValue];
    self.uncuttable = [aDecoder decodeBoolForKey:@"uncuttable"];
    self.finished = [aDecoder decodeBoolForKey:@"finished"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[NSString stringWithFormat:@"%lld", self.offset] forKey:@"offset"];
    [aCoder encodeObject:[NSString stringWithFormat:@"%lld", self.size] forKey:@"size"];
    [aCoder encodeObject:self.URLString forKey:@"URLString"];
    [aCoder encodeObject:[NSString stringWithFormat:@"%lld", self.downloadedSize] forKey:@"downloadedSize"];
    [aCoder encodeBool:self.uncuttable forKey:@"uncuttable"];
    [aCoder encodeBool:self.finished forKey:@"finished"];
}

- (void)setContentLength:(unsigned long long)contentLength
{
    if (self.size == 0) {
        self.size = contentLength;
    }
}

- (void)increaseDownloadedSize:(NSUInteger)size
{
    self.downloadedSize += size;
}

- (void)setDidFinish
{
    self.downloadedSize = self.size;
    
    self.finished = YES;
    self.downloading = NO;
}

- (void)setDidFailWithCurrentDownloadedSize
{
    self.offset += self.downloadedSize;
    self.size -= self.downloadedSize;
    
    self.downloading = NO;
}

- (unsigned long long)writingOffset
{
    return self.offset + self.downloadedSize;
}

- (SFFileFragment *)fragmentByHalfCutting
{
    SFFileFragment *fragment = nil;
    
    if (!self.uncuttable) {
        unsigned long long halfUndownloadedSize = (self.size - self.downloadedSize) / 2;
        fragment = [SFFileFragment fragmentWithURLString:self.URLString offset:self.offset + self.downloadedSize + halfUndownloadedSize size:halfUndownloadedSize];
        
        self.size -= halfUndownloadedSize;
    }
    
    return fragment;
}

+ (instancetype)fragmentWithURLString:(NSString *)URLString offset:(unsigned long long)offset
{
    return [self fragmentWithURLString:URLString offset:offset size:0];
}

+ (instancetype)fragmentWithURLString:(NSString *)URLString offset:(unsigned long long)offset size:(unsigned long long)size
{
    SFFileFragment *fragment = [self new];
    fragment.URLString = URLString;
    fragment.offset = offset;
    fragment.size = size;
    
    return fragment;
}

@end
