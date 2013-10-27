//
//  PlayerControlView.h
//  imysound
//
//  Created by gewara on 12-7-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PlayerStatusView;

@protocol PlayerStatusViewDelegate <NSObject>

@optional
- (void)playerStatusView:(PlayerStatusView *)playerStatusView didChangeToNewPosition:(float)value;

@end

@interface PlayerStatusView : UIView 

@property(nonatomic, assign)id<PlayerStatusViewDelegate> delegate;

@property(nonatomic, assign)NSTimeInterval currentTime;
@property(nonatomic, assign)NSTimeInterval totalTime;

@end
