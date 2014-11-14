//
//  PlayerControlView.m
//  imysound
//
//  Created by gewara on 12-7-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PlayerStatusView.h"
#import "NSString+SFiOSAddition.h"

@interface PlayerStatusView ()

@property(nonatomic, strong)UIView *topBlackBar;
@property(nonatomic, strong)UIView *bottomLine;
@property(nonatomic, strong)UILabel *currentTimeLabel;
@property(nonatomic, strong)UILabel *totalTimeLabel;
@property(nonatomic, strong)UISlider *positionSilder;

@property(nonatomic, assign)BOOL positionSilderTouching;

@end

@implementation PlayerStatusView

- (void)dealloc
{
}

- (id)init
{
    self = [self initWithFrame:CGRectZero];
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    // position slider
    self.topBlackBar = [[UIView alloc] init];
    [self addSubview:self.topBlackBar];
    self.topBlackBar.backgroundColor = [UIColor blackColor];
    self.topBlackBar.alpha = 0.72f;
    
    self.bottomLine = [[UIView alloc] init];
    [self addSubview:self.bottomLine];
    self.bottomLine.backgroundColor = [UIColor darkGrayColor];
    self.bottomLine.alpha = 0.32f;
    
    self.positionSilder = [[UISlider alloc] init];
    [self.positionSilder addTarget:self 
                            action:@selector(onPositionSilderDragEnter) 
                  forControlEvents:UIControlEventTouchDown];
    [self.positionSilder addTarget:self 
                            action:@selector(onPositionSilderDragExit) 
                  forControlEvents:UIControlEventTouchUpInside];
    [self.positionSilder addTarget:self 
                            action:@selector(onPositionSilderDragExit) 
                  forControlEvents:UIControlEventTouchUpOutside];
    [self.positionSilder addTarget:self 
                            action:@selector(onPositionSliderDragging) 
                  forControlEvents:UIControlEventTouchDragInside];
    [self.positionSilder addTarget:self 
                            action:@selector(onPositionSliderDragging) 
                  forControlEvents:UIControlEventTouchDragOutside];
    [self addSubview:self.positionSilder];
    
    // time labels
    UIFont *timeFont = [UIFont systemFontOfSize:12.0f];
    self.currentTimeLabel = [[UILabel alloc] init];
    [self addSubview:self.currentTimeLabel];
    self.currentTimeLabel.backgroundColor = [UIColor clearColor];
    self.currentTimeLabel.textColor = [UIColor whiteColor];
    self.currentTimeLabel.font = timeFont;
    
    self.totalTimeLabel = [[UILabel alloc] init];
    [self addSubview:self.totalTimeLabel];
    self.totalTimeLabel.backgroundColor = [UIColor clearColor];
    self.totalTimeLabel.textColor = [UIColor whiteColor];
    self.totalTimeLabel.font = timeFont;
    self.totalTimeLabel.textAlignment = NSTextAlignmentRight;
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.topBlackBar.frame = self.bounds;
    self.bottomLine.frame = CGRectMake(0, self.bounds.size.height - 1, self.bounds.size.width, 1);
    
    CGRect frame;
    frame.origin.x = 47;
    frame.size.width = self.bounds.size.width - (frame.origin.x * 2);
    frame.size.height = 20.0f;
    frame.origin.y = (self.bounds.size.height - frame.size.height) / 2;
    self.positionSilder.frame = frame;
    
    frame.size.width = [@"000:00" sf_sizeWithFont:self.currentTimeLabel.font].width;
    frame.origin.x = self.positionSilder.frame.origin.x - frame.size.width - 2;
    frame.origin.y = self.positionSilder.frame.origin.y;
    frame.size.height = self.positionSilder.frame.size.height;
    self.currentTimeLabel.frame = frame;
    
    frame = self.currentTimeLabel.frame;
    frame.origin.x = self.positionSilder.frame.origin.x + self.positionSilder.frame.size.width + 2;
    self.totalTimeLabel.frame = frame;
}

#pragma mark - events
- (void)onPositionSilderDragEnter
{
    self.positionSilderTouching = YES;
}

- (void)onPositionSilderDragExit
{
    self.positionSilderTouching = NO;
    if([self.delegate respondsToSelector:@selector(playerStatusView:didChangeToNewPosition:)]){
        [self.delegate playerStatusView:self didChangeToNewPosition:self.positionSilder.value];
    }
}

+ (NSString *)formatNumber:(NSUInteger)number
{
    if(number < 10){
        return [NSString stringWithFormat:@"0%d", number];
    }
    return [NSString stringWithFormat:@"%d", number];
}

- (void)onPositionSliderDragging
{
    NSTimeInterval currentTime = self.positionSilder.value;
    NSInteger minute = currentTime / 60;
    NSInteger second = (NSInteger)currentTime % 60;
    self.currentTimeLabel.text = [NSString stringWithFormat:@"%@:%@", [[self class] formatNumber:minute],
                                  [[self class] formatNumber:second]];
}

#pragma mark - instance methods
- (void)setCurrentTime:(NSTimeInterval)currentTime
{
    if(!self.positionSilderTouching){
        NSInteger minute = currentTime / 60;
        NSInteger second = (NSInteger)currentTime % 60;
        self.currentTimeLabel.text = [NSString stringWithFormat:@"%@:%@", [[self class] formatNumber:minute],
                                      [[self class] formatNumber:second]];
        self.positionSilder.value = currentTime;
    }
}

- (NSTimeInterval)currentTime
{
    return 0.0f;
}

- (void)setTotalTime:(NSTimeInterval)totalTime
{
    NSInteger minute = totalTime / 60;
    NSInteger second = (NSInteger)totalTime % 60;
    self.totalTimeLabel.text = [NSString stringWithFormat:@"%@:%@", [[self class] formatNumber:minute],
                                [[self class] formatNumber:second]];
    self.positionSilder.minimumValue = 0.0f;
    self.positionSilder.maximumValue = totalTime;
}

- (NSTimeInterval)totalTime
{
    return 0.0f;
}

@end
