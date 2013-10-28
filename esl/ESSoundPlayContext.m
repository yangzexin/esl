//
//  ESSoundPlayContext.m
//  esl
//
//  Created by yangzexin on 10/27/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESSoundPlayContext.h"
#import "ESSoundPlayer.h"

NSString *ESSoundPlayDidStartNotification = @"ESSoundPlayDidStartNotification";
NSString *ESSoundPlayDidFinishNotification = @"ESSoundPlayDidFinishNotification";
NSString *ESSoundPlayDidPauseNotification = @"ESSoundPlayStateDidChangeNotification";
NSString *ESSoundPlayDidResumeNotification = @"ESSoundPlayDidResumeNotification";

@interface ESSoundPlayContext ()

@property (nonatomic, strong) ESEpisode *playingEpisode;
@property (nonatomic, strong) ESSoundPlayer *soundPlayer;

@end

@implementation ESSoundPlayContext

+ (instancetype)sharedContext
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self class] new];
    });
    return instance;
}

- (id)init
{
    self = [super init];
    
    _soundPlayer = [ESSoundPlayer sharedPlayer];
    
    return self;
}

- (void)playWithEpisode:(ESEpisode *)episode soundPath:(NSString *)soundPath finishBlock:(void(^)())finishBlock
{
    self.playingEpisode = episode;
    self.playFinishBlock = finishBlock;
    [[NSNotificationCenter defaultCenter] postNotificationName:ESSoundPlayDidStartNotification object:nil];
    __weak typeof(self) weakSelf = self;
    [self.soundPlayer playWithSoundPath:soundPath finishBlock:^{
        weakSelf.playingEpisode = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:ESSoundPlayDidFinishNotification object:nil];
        if (weakSelf.playFinishBlock) {
            weakSelf.playFinishBlock();
        }
    }];
    [self.soundPlayer setPlayStateChanged:^{
        if (weakSelf.soundPlayer.isPaused) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ESSoundPlayDidPauseNotification object:nil];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:ESSoundPlayDidResumeNotification object:nil];
        }
    }];
}

- (void)pause
{
    [self.soundPlayer pause];
}

- (void)resume
{
    [self.soundPlayer resume];
}

- (void)stop
{
    [self.soundPlayer stop];
}

- (void)setPlayingBlock:(void (^)(NSTimeInterval, NSTimeInterval))playingBlock
{
    [self.soundPlayer setPlayingBlock:playingBlock];
}

- (void (^)(NSTimeInterval, NSTimeInterval))playingBlock
{
    return self.soundPlayer.playingBlock;
}

- (NSTimeInterval)currentTime
{
    return self.soundPlayer.currentTime;
}

- (BOOL)isPlaying
{
    return self.soundPlayer.isPlaying;
}

- (BOOL)isPaused
{
    return self.soundPlayer.isPaused;
}

- (void)setCurrentTime:(NSTimeInterval)currentTime
{
    self.soundPlayer.currentTime = currentTime;
}

- (NSTimeInterval)duration
{
    return self.soundPlayer.duration;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    [self.soundPlayer remoteControlReceivedWithEvent:event];
}

@end
