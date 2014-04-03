//
//  ESEpisode.h
//  esl
//
//  Created by yangzexin on 10/25/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSString *(^ESEpisodeIntrodutionFormatter)(NSString *introdution);

@interface ESEpisode : NSObject

@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *date;
@property (nonatomic, copy) NSString *introdution;
@property (nonatomic, copy) NSString *formattedIntrodution;
@property (nonatomic, copy) NSString *soundURLString;
@property (nonatomic, copy) NSString *contentURLString;

@property (nonatomic, copy) ESEpisodeIntrodutionFormatter introdutionFormatter;

@end
