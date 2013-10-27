//
//  ESASIHTTPRequestAdapter.m
//  esl
//
//  Created by yangzexin on 10/26/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESHTTPRequest.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "NSString+SFAddition.h"

@interface ESHTTPRequest () <ASIHTTPRequestDelegate, ASIProgressDelegate>

@property (nonatomic, strong) ASIHTTPRequest *request;
@property (nonatomic, copy) SFRequestProxyCompletion completion;
@property (nonatomic, copy) NSString *cacheIdentifier;

@end

@implementation ESHTTPRequest

- (void)dealloc
{
    [_request clearDelegatesAndCancel];
}

+ (instancetype)requestWithURLString:(NSString *)URLString
{
    return [self requestWithURLString:URLString useHTTPPost:NO];
}

+ (instancetype)requestWithURLString:(NSString *)URLString useHTTPPost:(BOOL)useHTTPPost
{
    ESHTTPRequest *adapter = [ESHTTPRequest new];
    adapter.URLString = URLString;
    adapter.useHTTPPost = useHTTPPost;
    return adapter;
}

- (void)requestWithParameters:(NSDictionary *)parameters completion:(void(^)(NSData *responseData, NSError *error))completion
{
    [self cancel];
    self.completion = completion;
    [self _startRequestWithParameters:parameters];
}

- (void)_startRequestWithParameters:(NSDictionary *)parameters
{
    self.request = self.useHTTPPost ? [self HTTPPostWithParameters:parameters] : [self HTTPGetWithParameters:parameters];
    [self.request setTimeOutSeconds:30.0f];
    self.request.delegate = self;
    self.request.downloadProgressDelegate = self;
    [self.request startAsynchronous];
}

- (ASIHTTPRequest *)HTTPGetWithParameters:(NSDictionary *)parameters
{
    NSString *URLString = self.URLString;
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:URLString]];
    return request;
}

- (ASIHTTPRequest *)HTTPPostWithParameters:(NSDictionary *)parameters
{
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:self.URLString]];
    for (NSString *key in [parameters allKeys]) {
        [request setPostValue:[parameters valueForKey:key] forKey:key];
    }
    return request;
}

- (void)cancel
{
    [self.request clearDelegatesAndCancel];
    self.completion = nil;
}

- (void)_notifyResponse:(id)response error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.completion) {
            self.completion(response, error);
        }
    });
}

- (void)_finishWithData:(NSData *)data
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        id responseData = data;
        if (self.responseDataWrapper) {
            responseData = self.responseDataWrapper(responseData);
        }
        [self _notifyResponse:responseData error:nil];
    });
}

#pragma mark - ASIHTTPRequestDelegate
- (void)setProgress:(float)newProgress
{
    if (self.requestProgressDidChange) {
        self.requestProgressDidChange(newProgress);
    }
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    NSData *data = request.responseData;
    [self _finishWithData:data];
    self.request = nil;
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    [self _notifyResponse:nil error:request.error];
    self.request = nil;
}

@end
