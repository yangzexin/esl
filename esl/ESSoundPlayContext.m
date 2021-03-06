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
NSString *ESSoundPlayStateDidChangeNotification = @"ESSoundPlayStateDidChangeNotification";

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

- (void)playWithEpisode:(ESEpisode *)episode soundPath:(NSString *)soundPath finishBlock:(void(^)(BOOL success, NSError *error))finishBlock
{
    self.playingEpisode = episode;
    self.playFinishedBlock = finishBlock;
    [[NSNotificationCenter defaultCenter] postNotificationName:ESSoundPlayDidStartNotification object:nil];
    __weak typeof(self) weakSelf = self;
    [self.soundPlayer setPlayStartedBlock:^{
        if (weakSelf.playStartedBlock) {
            weakSelf.playStartedBlock();
        }
    }];
    [self.soundPlayer playWithSoundPath:soundPath finishBlock:^(BOOL success, NSError *error){
        weakSelf.playingEpisode = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:ESSoundPlayDidFinishNotification object:nil];
        if (weakSelf.playFinishedBlock) {
            weakSelf.playFinishedBlock(success, error);
        }
    }];
    [self.soundPlayer setPlayStateChanged:^{
        if (weakSelf.soundPlayer.isPaused) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ESSoundPlayDidPauseNotification object:nil];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:ESSoundPlayDidResumeNotification object:nil];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:ESSoundPlayStateDidChangeNotification object:nil];
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
