//
//  ESSharedEpisodeManager.h
//  esl
//
//  Created by yangzexin on 11/6/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESEpisodeManager.h"

@interface ESSharedEpisodeManager : NSObject

+ (id<ESEpisodeManager>)defaultManager;

+ (id<ESEpisodeManager>)eslEpisodeManager;
+ (id<ESEpisodeManager>)englishpodEpisodeManager;

@end
