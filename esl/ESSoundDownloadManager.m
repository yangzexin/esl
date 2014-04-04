//
//  ESSoundDownloadManager.m
//  esl
//
//  Created by yangzexin on 4/4/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "ESSoundDownloadManager.h"

NSString *const ESSoundDownloadManagerDidFinishDownloadEpisodeNotification = @"ESSoundDownloadManagerDidFinishDownloadEpisodeNotification";

@implementation ESSoundDownloadManager

+ (instancetype)sharedManager
{
    static id instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self class] new];
    });
    return instance;
}

- (ESSoundDownloadState)stateForEpisode:(ESEpisode *)episode
{
    return ESSoundDownloadStateNotDownloaded;
}

- (void)downloadEpisode:(ESEpisode *)episode
{
}

- (float)downloadedPercentForEpisode:(ESEpisode *)episode
{
    return 0.0f;
}

- (NSString *)soundFilePathForEpisode:(ESEpisode *)episode
{
    return nil;
}

@end
