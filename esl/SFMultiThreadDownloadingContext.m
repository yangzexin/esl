//
//  SFMultiThreadDownloadingContext.m
//  esl
//
//  Created by yangzexin on 11/10/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "SFMultiThreadDownloadingContext.h"

@interface SFMultiThreadDownloadingContext ()

@property (nonatomic, copy) NSString *URLString;
@property (nonatomic, strong) NSMutableArray *fragments;
@property (nonatomic, strong) SFFileFragment *mainFragment;
@property (nonatomic, assign) BOOL notified;

@end

@implementation SFMultiThreadDownloadingContext

- (id)initWithURLString:(NSString *)URLString
{
    self = [super init];
    
    self.URLString = URLString;
    self.mainFragment = [SFFileFragment fragmentWithURLString:self.URLString offset:0];
    
    return self;
}

- (SFFileFragment *)nextFragment
{
    SFFileFragment *fragment = nil;
    if (self.fragments == nil) {
        self.fragments = [NSMutableArray array];
        fragment = self.mainFragment;
        [self.fragments addObject:fragment];
    } else if (self.fragments.count == 1) {
        SFFileFragment *firstFragment = [self.fragments objectAtIndex:0];
        fragment = [firstFragment fragmentByHalfCutting];
        if (fragment) {
            [self.fragments addObject:fragment];
        }
    } else {
        for (SFFileFragment *tmpFragment in self.fragments) {
            if (!tmpFragment.downloading && !tmpFragment.finished) {
                fragment = tmpFragment;
                break;
            }
        }
    }
    if (!fragment.downloading) {
        fragment.downloading = YES;
    }
    
    return fragment;
}

- (void)readFromDisk
{
}

- (void)saveToDisk
{
}

- (void)_checkIfFinished
{
    BOOL isFinished = [self isFinished];
    if (isFinished && !self.notified) {
        self.notified = YES;
        [self.delegate multiThreadDownloadingContextDidFinishDownloading:self];
    }
}

- (BOOL)isFinished
{
    BOOL allFinished = YES;
    for (SFFileFragment *tmpFragment in self.fragments) {
        if (!tmpFragment.finished) {
            allFinished = NO;
            break;
        }
    }
    return allFinished;
}

- (void)fragmentDidFinish:(SFFileFragment *)fragment
{
    [self _checkIfFinished];
}

- (void)fragmentDidFail:(SFFileFragment *)fragment
{
    fragment.downloading = NO;
    if (self.fragments.count == 1) {
        [self _checkIfFinished];
    }
}

@end
