//
//  ESSoundPlayer.m
//  esl
//
//  Created by yangzexin on 10/27/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESSoundPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "SFRepeatTimer.h"

@interface ESSoundPlayer () <AVAudioPlayerDelegate>

@property (nonatomic, assign, getter = isPlaying) BOOL playing;
@property (nonatomic, assign, getter = isPaused) BOOL paused;
@property (nonatomic, assign) NSTimeInterval pausedTime;
@property (nonatomic, copy) NSString *playingSoundPath;
@property (nonatomic, copy) void(^finishBlock)();
@property (nonatomic, strong) SFRepeatTimer *timer;

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@end

@implementation ESSoundPlayer

+ (instancetype)sharedPlayer
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self class] new];
    });
    
    return instance;
}

- (void)playWithSoundPath:(NSString *)path finishBlock:(void(^)())finishBlock
{
    [self.audioPlayer stop];
    self.playingSoundPath = path;
    self.finishBlock = finishBlock;
    self.playing = YES;
    NSError *error = nil;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&error];
    if (error != nil) {
        [self _playerStoped];
    } else {
        self.audioPlayer.delegate = self;
        [self.audioPlayer play];
        __weak typeof(self) weakSelf = self;
        [self.timer stop];
        self.timer = [SFRepeatTimer timerWithTimeInterval:0.50f tick:^{
            if (weakSelf.playingBlock) {
                weakSelf.playingBlock(weakSelf.currentTime, weakSelf.duration);
            }
        }];
    }
}

- (void)_playerStoped
{
    self.playing = NO;
    if (self.finishBlock) {
        self.finishBlock();
    }
}

- (void)pause
{
    if (self.isPaused == NO) {
        self.pausedTime = self.currentTime;
        [self.audioPlayer pause];
        self.paused = YES;
    }
}

- (void)resume
{
    if (self.isPaused) {
        self.currentTime = self.pausedTime - 2.0f;
        [self.audioPlayer play];
        self.paused = NO;
    }
}

- (void)stop
{
    [self pause];
}

- (NSTimeInterval)currentTime
{
    return self.audioPlayer.currentTime;
}

- (void)setCurrentTime:(NSTimeInterval)currentTime
{
    self.audioPlayer.currentTime = currentTime;
}

- (NSTimeInterval)duration
{
    return self.audioPlayer.duration;
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self _playerStoped];
}

@end
