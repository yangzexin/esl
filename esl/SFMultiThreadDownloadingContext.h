//
//  SFMultiThreadDownloadingContext.h
//  esl
//
//  Created by yangzexin on 11/10/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SFFileFragment.h"

@class SFMultiThreadDownloadingContext;

@protocol SFMultiThreadDownloadingContextDelegate <NSObject>

- (void)multiThreadDownloadingContextDidFinishDownloading:(SFMultiThreadDownloadingContext *)multiThreadDownloadingContext;

@end

@interface SFMultiThreadDownloadingContext : NSObject

@property (nonatomic, assign) id<SFMultiThreadDownloadingContextDelegate> delegate;
@property (nonatomic, copy, readonly) NSString *URLString;
@property (nonatomic, strong, readonly) SFFileFragment *mainFragment;

- (id)initWithURLString:(NSString *)URLString;

- (SFFileFragment *)nextFragment;
- (BOOL)isFinished;

- (void)readFromDisk;
- (void)saveToDisk;

- (void)fragmentDidFinish:(SFFileFragment *)fragment;

- (void)fragmentDidFail:(SFFileFragment *)fragment;

@end
