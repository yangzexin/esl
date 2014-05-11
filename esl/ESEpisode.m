//
//  ESEpisode.m
//  esl
//
//  Created by yangzexin on 10/25/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESEpisode.h"

#import "SFImageLabel.h"

@implementation ESEpisode

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
}

- (void)setIntrodution:(NSString *)introdution
{
    _introdution = [introdution copy];
//    if (_title != nil) {
//        [self _build];
//    }
}

- (void)_build
{
    NSString *text = [NSString stringWithFormat:@"[title]%@\n", _title];
    self.titleFormatted = [SFImageLabelText textFromString:text constraitsWidth:310 imageSizeCalculator:^CGSize(NSString *imageName) {
        return CGSizeMake(25, 25);
    }];
    _titleFormatted.font = [UIFont boldSystemFontOfSize:17.0f];
    _titleFormatted.imageMatchingLeft = @"[";
    _titleFormatted.imageMatchingRight = @"]";
    [_titleFormatted build];
    
    SFImageLabelText *dateText = [SFImageLabelText textFromString:[NSString stringWithFormat:@"[date]%@\n", _date] constraitsWidth:310 imageSizeCalculator:^CGSize(NSString *imageName) {
        return CGSizeMake(25, 25);
    }];
    dateText.textColor = [UIColor lightGrayColor];
    dateText.font = [UIFont systemFontOfSize:12.0f];
    dateText.imageMatchingLeft = @"[";
    dateText.imageMatchingRight = @"]";
    [dateText build];
    self.titleFormatted = [_titleFormatted textByAppendingText:dateText];
    
    SFImageLabelText *introText = [SFImageLabelText textFromString:[NSString stringWithFormat:@"[introdution]%@", _introdution] constraitsWidth:310 imageSizeCalculator:^CGSize(NSString *imageName) {
        return CGSizeMake(310, 82);
    }];
    introText.textColor = [UIColor darkGrayColor];
    introText.imageMatchingLeft = @"[";
    introText.imageMatchingRight = @"]";
    [introText build];
    self.titleFormatted = [_titleFormatted textByAppendingText:introText];
}

- (SFImageLabelText *)titleFormatted
{
    if (_titleFormatted == nil) {
        [self _build];
    }
    return _titleFormatted;
}

@end
