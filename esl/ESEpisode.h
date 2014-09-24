//
//  ESEpisode.h
//  esl
//
//  Created by yangzexin on 10/25/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SFImageLabelText;

typedef NSString *(^ESEpisodeIntrodutionFormatter)(NSString *introdution);

@interface ESEpisode : NSObject

@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *date;
@property (nonatomic, copy) NSString *introdution;
@property (nonatomic, copy) NSString *formattedIntrodution;
@property (nonatomic, copy) NSString *soundURLString;
@property (nonatomic, copy) NSString *contentURLString;

@property (nonatomic, assign) NSInteger sort;

@property (nonatomic, copy) ESEpisodeIntrodutionFormatter introdutionFormatter;

- (SFImageLabelText *)titleFormatted;

- (SFImageLabelText *)titleFormattedWithWidth:(CGFloat)width;

- (NSString *)simpleTitle;

- (SFImageLabelText *)simpleTitleTextWithWidth:(CGFloat)width;

@end
