//
//  SFSingleThreadHandler.h
//  esl
//
//  Created by yangzexin on 11/10/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFSkipableURLDownloader.h"
#import "SFFileWritable.h"

@class SFFileFragment;

@class SFSingleThreadHandler;

@protocol SFSingleThreadHandlerDelegate <NSObject>

- (void)singleThreadHandler:(SFSingleThreadHandler *)singleThreadHandler didReceiveResponse:(NSURLResponse *)response contentLength:(unsigned long long)contentLength skipable:(BOOL)skipable;
- (void)singleThreadHandler:(SFSingleThreadHandler *)singleThreadHandler didFinishDownloadingFragment:(SFFileFragment *)fragment;
- (void)singleThreadHandler:(SFSingleThreadHandler *)singleThreadHandler didFailDownloadingFragment:(SFFileFragment *)fragment;

@end

@interface SFSingleThreadHandler : NSObject

@property (nonatomic, assign) id<SFSingleThreadHandlerDelegate> delegate;

@property (nonatomic, strong, readonly) SFFileFragment *fragment;

+ (instancetype)handlerWithSkipableURLDownloader:(id<SFSkipableURLDownloader>)skipableURLDownloader fileWritable:(id<SFPreparedFileWritable>)fileWritable;

- (void)startWithFragment:(SFFileFragment *)fragment;
- (BOOL)isExecuting;
- (void)cancel;

@end
