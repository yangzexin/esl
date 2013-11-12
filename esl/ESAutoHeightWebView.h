//
//  ESAutoHeightWebView.h
//  esl
//
//  Created by yangzexin on 11/12/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ESAutoHeightWebView;

@protocol ESAutoHeightWebViewDelegate <NSObject>

- (void)autoHeightWebView:(ESAutoHeightWebView *)webView highlightingText:(NSString *)text;
- (void)autoHeightWebView:(ESAutoHeightWebView *)webView unhighlightingText:(NSString *)text;
- (BOOL)autoHeightWebView:(ESAutoHeightWebView *)web shouldUnhightText:(NSString *)text;

@end

@interface ESAutoHeightWebView : UIView

@property (nonatomic, weak) id<ESAutoHeightWebViewDelegate> delegate;

- (void)loadWithURL:(NSURL *)url autoFitHeightCompletion:(void(^)(CGFloat height))completion;
- (void)loadWitHTMLString:(NSString *)HTMLString autoFitHeightCompletion:(void(^)(CGFloat height))completion;

@end
