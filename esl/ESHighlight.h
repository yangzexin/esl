//
//  ESHighlight.h
//  esl
//
//  Created by yangzexin on 11/12/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ESHighlight : NSObject <NSCoding>

@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) NSInteger fromIndex;
@property (nonatomic, assign) NSInteger endIndex;

@end
