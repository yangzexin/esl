//
//  ESSoundPlayer.h
//  esl
//
//  Created by yangzexin on 10/27/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ESSoundPlayer : NSObject

+ (instancetype)sharedPlayer;

@property (nonatomic, readonly, copy) NSString *playingSoundPath;
@property (nonatomic, readonly, getter = isPlaying) BOOL playing;
@property (nonatomic, readonly, getter = isPaused) BOOL paused;
@property (nonatomic, assign) NSTimeInterval currentTime;
@property (nonatomic, readonly) NSTimeInterval duration;

@property (nonatomic, copy) void(^playingBlock)(NSTimeInterval currentTime, NSTimeInterval duration);

- (void)playWithSoundPath:(NSString *)path finishBlock:(void(^)())finishBlock;
- (void)resume;
- (void)pause;
- (void)stop;

@end
