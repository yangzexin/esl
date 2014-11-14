//
//  ESEpisode.m
//  esl
//
//  Created by yangzexin on 10/25/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESEpisode.h"

#import "SFImageLabel.h"

#import "SFFoundation.h"

@implementation ESEpisode {
    SFImageLabelText *_titleFormatted;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@-%@", self.uid, self.title, self.date];
}

- (void)setTitle:(NSString *)title
{
    _title = [title copy];
//    if (_introdution != nil) {
//        [self _build];
//    }
    
    NSString *simpleTitle = [self simpleTitle];
    NSInteger sortIndex = [simpleTitle sf_find:@" –"];
    NSString *const cafePrefix = @"English Café";
    if (sortIndex != -1) {
        NSString *sortString = [simpleTitle substringToIndex:sortIndex];
        self.sort = [sortString integerValue] + 10000;
    } else if ([simpleTitle hasPrefix:cafePrefix]) {
        self.sort = [[simpleTitle substringFromIndex:cafePrefix.length] integerValue] + 1000;
    }
}

- (void)setIntrodution:(NSString *)introdution
{
    _introdution = [introdution copy];
//    if (_title != nil) {
//        [self _build];
//    }
}

- (void)_buildWithWidth:(CGFloat)width
{
    NSString *text = [NSString stringWithFormat:@"%@\n", self.simpleTitle];
    _titleFormatted = [SFImageLabelText textFromString:text constraitsWidth:width imageSizeCalculator:^CGSize(NSString *imageName) {
        return CGSizeMake(27, 20);
    }];
    _titleFormatted.font = [UIFont boldSystemFontOfSize:15.0f];
    _titleFormatted.imageMatchingLeft = @"[";
    _titleFormatted.imageMatchingRight = @"]";
    [_titleFormatted build];
    
    SFImageLabelText *dateText = [SFImageLabelText textFromString:[NSString stringWithFormat:@"%@\n", _date] constraitsWidth:width imageSizeCalculator:^CGSize(NSString *imageName) {
        return CGSizeMake(27, 20);
    }];
    dateText.textColor = [UIColor grayColor];
    dateText.font = [UIFont systemFontOfSize:12.0f];
    dateText.imageMatchingLeft = @"[";
    dateText.imageMatchingRight = @"]";
    [dateText build];
    _titleFormatted = [_titleFormatted textByAppendingText:dateText];
    
    SFImageLabelText *introText = [SFImageLabelText textFromString:[NSString stringWithFormat:@"%@", _introdution] constraitsWidth:width imageSizeCalculator:^CGSize(NSString *imageName) {
        return CGSizeMake(width, 82);
    }];
    introText.textColor = [UIColor darkGrayColor];
    introText.imageMatchingLeft = @"[";
    introText.imageMatchingRight = @"]";
    [introText build];
    _titleFormatted = [_titleFormatted textByAppendingText:introText];
}

- (SFImageLabelText *)titleFormatted
{
    return [self titleFormattedWithWidth:[UIScreen mainScreen].bounds.size.width - 10];
}

- (SFImageLabelText *)titleFormattedWithWidth:(CGFloat)width
{
    if (_titleFormatted == nil) {
        [self _buildWithWidth:width];
    }
    return _titleFormatted;
}

- (NSString *)simpleTitle
{
    NSString *simpleTitle = [self sf_associatedObjectWithKey:@"simpleTitle"];
    
    if (simpleTitle == nil) {
        simpleTitle = [[self.title lowercaseString] hasPrefix:@"esl podcast "] ? [self.title substringFromIndex:12] : self.title;
        [self sf_setAssociatedObject:simpleTitle key:@"simpleTitle"];
    }
    
    return simpleTitle;
}

- (SFImageLabelText *)simpleTitleTextWithWidth:(CGFloat)width
{
    NSString *key = [NSString stringWithFormat:@"simpleTitleText-%.0f", width];
    
    SFImageLabelText *text = [self sf_associatedObjectWithKey:key];
    
    if (text == nil) {
        text = [SFImageLabelText textFromString:self.simpleTitle constraitsWidth:width];
        [text build];
        [self sf_setAssociatedObject:text key:key];
    }
    
    return text;
}

@end
