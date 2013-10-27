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
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        
        AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, audioRouteChange, (__bridge void *)(self));
        
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
        if (self.playStateChanged) {
            self.playStateChanged();
        }
    }
}

- (void)resume
{
    if (self.isPaused) {
        self.currentTime = self.pausedTime - 2.0f;
        [self.audioPlayer play];
        self.paused = NO;
        if (self.playStateChanged) {
            self.playStateChanged();
        }
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
        [(__bridge id)inClientData pause];
    }else if(routeChangeReason == kAudioSessionRouteChangeReason_NewDeviceAvailable){
    }
}

@end
