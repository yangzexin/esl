//
//  ESSoundPlayContext.h
//  esl
//
//  Created by yangzexin on 10/27/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ESEpisode;

OBJC_EXPORT NSString *ESSoundPlayDidStartNotification;
OBJC_EXPORT NSString *ESSoundPlayDidFinishNotification;
OBJC_EXPORT NSString *ESSoundPlayDidPauseNotification;
OBJC_EXPORT NSString *ESSoundPlayDidResumeNotification;

@interface ESSoundPlayContext : NSObject

+ (instancetype)sharedContext;

@property (nonatomic, readonly) ESEpisode *playingEpisode;
@property (nonatomic, assign) NSTimeInterval currentTime;
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, readonly, getter = isPlaying) BOOL playing;
@property (nonatomic, readonly, getter = isPaused) BOOL paused;

@property (nonatomic, copy) void(^playingBlock)(NSTimeInterval currentTime, NSTimeInterval duration);
@property (nonatomic, copy) void(^playStartedBlock)();
@property (nonatomic, copy) void(^playFinishedBlock)(BOOL success, NSError *error);

- (void)remoteControlReceivedWithEvent:(UIEvent *)event;

- (void)playWithEpisode:(ESEpisode *)episode soundPath:(NSString *)soundPath finishBlock:(void(^)(BOOL success, NSError *error))finishBlock;
- (void)pause;
- (void)resume;
- (void)stop;

@end
