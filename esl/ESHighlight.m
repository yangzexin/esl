//
//  ESHighlight.m
//  esl
//
//  Created by yangzexin on 11/12/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESHighlight.h"

@implementation ESHighlight

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:self.fromIndex forKey:@"fromIndex"];
    [aCoder encodeInteger:self.endIndex forKey:@"endIndex"];
    [aCoder encodeObject:self.text forKey:@"text"];
    [aCoder encodeObject:self.color forKey:@"color"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    self.fromIndex= [aDecoder decodeIntegerForKey:@"fromIndex"];
    self.endIndex = [aDecoder decodeIntegerForKey:@"endIndex"];
    self.text = [aDecoder decodeObjectForKey:@"text"];
    self.color = [aDecoder decodeObjectForKey:@"color"];
    
    return self;
}

@end
