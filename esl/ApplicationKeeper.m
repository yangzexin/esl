//
//  ApplicationKeeper.m
//  imyvoa
//
//  Created by yangzexin on 9/28/12.
//
//

#import "ApplicationKeeper.h"
#import <AVFoundation/AVFoundation.h>

@interface ApplicationKeeper () <AVAudioPlayerDelegate>

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@end

@implementation ApplicationKeeper

+ (id)sharedInstance
{
    static ApplicationKeeper *instance = nil;
    if(instance == nil){
        instance = [[ApplicationKeeper alloc] init];
    }
    return instance;
}

- (id)init
{
    self = [super init];
    
    return self;
}

- (void)keep
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ApplicationKeeper" ofType:@"mp3"];
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:filePath] error:nil];
    self.audioPlayer.delegate = self;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    [self.audioPlayer play];
}

- (void)stop
{
    [self.audioPlayer stop];
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    self.audioPlayer.currentTime = 0.0f;
    [self.audioPlayer play];
}

@end
