//
//  ESEpisode.m
//  esl
//
//  Created by yangzexin on 10/25/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESEpisode.h"

@implementation ESEpisode

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@-%@", self.uid, self.title, self.date];
}

@end
