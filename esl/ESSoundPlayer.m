//
//  ESSoundPlayer.m
//  esl
//
//  Created by yangzexin on 10/27/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESSoundPlayer.h"

#import <AVFoundation/AVFoundation.h>

@interface ESSoundPlayer () <AVAudioPlayerDelegate>

@property (nonatomic, assign, getter = isPlaying) BOOL playing;
@property (nonatomic, assign, getter = isPaused) BOOL paused;
@property (nonatomic, assign) NSTimeInterval pausedTime;
@property (nonatomic, copy) NSString *playingSoundPath;
@property (nonatomic, copy) void(^playFinishedBlock)(BOOL success, NSError *error);
@property (nonatomic, strong) SFRepeatTimer *timer;
@property (nonatomic, assign) BOOL pausedByPlugout;

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

- (void)playWithSoundPath:(NSString *)path finishBlock:(void(^)(BOOL success, NSError *error))finishBlock
{
    [self.audioPlayer stop];
    self.playingSoundPath = path;
    self.playFinishedBlock = finishBlock;
    self.playing = YES;
    NSError *error = nil;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&error];
    if (error != nil) {
        [self _playerStopedWithError:error];
    } else {
        self.audioPlayer.delegate = self;
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        
        AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, audioRouteChange, (__bridge void *)(self));
        [self _playStateChanged];
        [self.audioPlayer play];
        if (self.playStartedBlock) {
            self.playStartedBlock();
        }
        __weak typeof(self) weakSelf = self;
        [self.timer stop];
        self.timer = [SFRepeatTimer timerStartWithTimeInterval:0.50f tick:^{
            if (weakSelf.playingBlock) {
                weakSelf.playingBlock(weakSelf.currentTime, weakSelf.duration);
            }
        }];
    }
}

- (void)_playStateChanged
{
    self.pausedByPlugout = NO;
}

- (void)_notifyPlayStateChangedByExternal
{
    if (self.playStateChanged) {
        self.playStateChanged();
    }
}

- (void)_playerStopedWithError:(NSError *)error
{
    self.playing = NO;
    [self.timer stop]; self.timer = nil;
    if (self.playFinishedBlock) {
        self.playFinishedBlock(error == nil, error);
    }
}

- (void)_playerStoped
{
    [self _playerStopedWithError:nil];
}

- (void)pause
{
    if (self.isPaused == NO) {
        self.pausedTime = self.currentTime;
        [self.audioPlayer pause];
        self.paused = YES;
        [self _playStateChanged];
    }
}

- (void)pauseByRoutePlugout
{
    if (self.isPaused == NO) {
        [self pause];
        self.pausedByPlugout = YES;
        [self _notifyPlayStateChangedByExternal];
    }
}

- (void)resumeByRoutePlugin
{
    if (self.pausedByPlugout) {
        if (self.isPaused) {
            self.pausedByPlugout = NO;
            [self resume];
            [self _notifyPlayStateChangedByExternal];
        }
    }
}

- (void)clearResumeWhenPlugout
{
    self.pausedByPlugout = NO;
}

- (void)resume
{
    if (self.isPaused) {
        self.currentTime = self.pausedTime;
        [self.audioPlayer play];
        self.paused = NO;
        [self _playStateChanged];
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
    self.pausedTime = currentTime;
    self.audioPlayer.currentTime = currentTime;
}

- (NSTimeInterval)duration
{
    return self.audioPlayer.duration;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    if (self.isPlaying) {
        if (event.subtype == UIEventSubtypeRemoteControlNextTrack) {
            double time = self.audioPlayer.currentTime - 10;
            self.audioPlayer.currentTime = time < 0 ? 0 : time;
        } else if ([UIDevice currentDevice].systemVersion.floatValue < 7.0f) {
            if (event.subtype == UIEventSubtypeRemoteControlTogglePlayPause) {
                self.isPaused ? [self resume] : [self pause];
                [self _notifyPlayStateChangedByExternal];
            }
        } else {
            if (event.subtype == UIEventSubtypeRemoteControlPlay) {
                [self resume];
                [self _notifyPlayStateChangedByExternal];
            } else if (event.subtype == UIEventSubtypeRemoteControlPause) {
                [self pause];
                [self _notifyPlayStateChangedByExternal];
            }
        }
    }
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self _playerStoped];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    [self _playerStopedWithError:error];
}

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
    NSLog(@"audioPlayerBeginInterruption:%@", player);
}

void audioRouteChange(
                      void *                  inClientData,
                      AudioSessionPropertyID	inID,
                      UInt32                  inDataSize,
                      const void *            inData)
{
    CFDictionaryRef    routeChangeDictionary = inData;
    CFNumberRef routeChangeReasonRef = CFDictionaryGetValue(routeChangeDictionary, CFSTR(kAudioSession_AudioRouteChangeKey_Reason));
    SInt32 routeChangeReason;
    CFNumberGetValue(routeChangeReasonRef, kCFNumberSInt32Type, &routeChangeReason);
    if(routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable){
        [(__bridge id)inClientData pauseByRoutePlugout];
    }else if(routeChangeReason == kAudioSessionRouteChangeReason_NewDeviceAvailable){
        [(__bridge id)inClientData resumeByRoutePlugin];
    }
}

@end
