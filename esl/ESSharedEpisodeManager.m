//
//  ESSharedEpisodeManager.m
//  esl
//
//  Created by yangzexin on 11/6/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESSharedEpisodeManager.h"
#import "ESESLEpisodeManager.h"
#import "ESEnglishpodManager.h"

@implementation ESSharedEpisodeManager

+ (id<ESEpisodeManager>)defaultManager
{
    return [self englishpodEpisodeManager];
}

+ (id<ESEpisodeManager>)eslEpisodeManager
{
    return [ESESLEpisodeManager new];
}

+ (id<ESEpisodeManager>)englishpodEpisodeManager
{
    return [ESEnglishpodManager new];
}

@end
