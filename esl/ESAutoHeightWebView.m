//
//  ESAutoHeightWebView.m
//  esl
//
//  Created by yangzexin on 11/12/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESAutoHeightWebView.h"
#import "UIWebView+SFAddition.h"

@interface ESAutoHeightWebView () <UIWebViewDelegate>

@property (nonatomic, copy) void(^completion)(CGFloat height);
@property (nonatomic, strong) UIWebView *webView;

@end

@implementation ESAutoHeightWebView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    _webView = [[UIWebView alloc] initWithFrame:self.bounds];
    _webView.delegate = self;
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_webView];
    
    [_webView sf_scrollView].bounces = NO;
    
//    [[UIMenuController sharedMenuController] addMenuItemIfNotExistsWithTitle:@"Highlight" action:@selector(_highlightMenuItemTapped)];
//    [[UIMenuController sharedMenuController] addMenuItemIfNotExistsWithTitle:@"Unhighlight" action:@selector(_unhighlightMenuItemTapped)];
    
    return self;
}

- (void)_highlightMenuItemTapped
{
    NSLog(@"%d", [self.webView sf_selectedTextStartOffset]);
    if ([self.delegate respondsToSelector:@selector(autoHeightWebView:highlightingText:)]) {
        [self.delegate autoHeightWebView:self highlightingText:self.webView.sf_selectedText];
    }
}

- (void)_unhighlightMenuItemTapped
{
    if ([self.delegate respondsToSelector:@selector(autoHeightWebView:unhighlightingText:)]) {
        [self.delegate autoHeightWebView:self unhighlightingText:self.webView.sf_selectedText];
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(_highlightMenuItemTapped)) {
        NSString *selectedText = self.webView.sf_selectedText;
        return selectedText.length != 0;
    } else if (action == @selector(_unhighlightMenuItemTapped)) {
        NSString *selectedText = self.webView.sf_selectedText;
        BOOL canPerform = selectedText.length != 0;
        if (canPerform) {
            if ([self.delegate respondsToSelector:@selector(autoHeightWebView:shouldUnhightText:)]) {
                canPerform = [self.delegate autoHeightWebView:self shouldUnhightText:selectedText];
            } else {
                canPerform = NO;
            }
        }
        return canPerform;
    }
    return [super canPerformAction:action withSender:sender];
}

- (void)loadWithURL:(NSURL *)url autoFitHeightCompletion:(void(^)(CGFloat height))completion
{
    self.completion = completion;
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)loadWitHTMLString:(NSString *)HTMLString autoFitHeightCompletion:(void(^)(CGFloat height))completion
{
    self.completion = completion;
    [self.webView loadHTMLString:HTMLString baseURL:nil];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (self.completion) {
        self.completion([webView scrollView].contentSize.height);
    }
}

@end
