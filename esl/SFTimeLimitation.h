//
//  SFTimeLimitation.h
//  esl
//
//  Created by yangzexin on 5/6/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SFTimeLimitation : NSObject

+ (instancetype)sharedTimeLimitation;

- (void)limitWithIdentifier:(NSString *)identifier limitTimeInterval:(NSTimeInterval)limitTimeInterval doBlock:(void(^)())doBlock;

@end
