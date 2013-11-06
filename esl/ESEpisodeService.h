//
//  ESEpisodeService.h
//  esl
//
//  Created by yangzexin on 10/26/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESService.h"

OBJC_EXPORT NSString *ESEpisodeDidUpdateNotification;
OBJC_EXPORT NSString *ESBackgroundUpdateEpisodeDidFinishNotification;

@interface ESEpisodeService : NSObject <ESService>

@property (nonatomic, assign) BOOL useCache;

@end
