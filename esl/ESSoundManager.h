//
//  ESSoundManager.h
//  esl
//
//  Created by yangzexin on 10/27/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESService.h"

@protocol ESProgressTracker <NSObject>

- (void)progressUpdatingWithPercent:(float)percent;

@end

@interface ESSoundManager : NSObject

+ (id<ESService>)soundWithURLString:(NSString *)URLString progressTracker:(id<ESProgressTracker>)progressTracker;

@end
