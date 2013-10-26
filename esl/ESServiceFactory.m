//
//  ESServiceFactory.m
//  esl
//
//  Created by yangzexin on 10/26/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESServiceFactory.h"
#import "SFObjectServiceSession.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"

@interface ESRequestProxyAdapter : NSObject <SFRequestProxy, ASIHTTPRequestDelegate>

@property (nonatomic, copy) NSString *URLString;
@property (nonatomic, assign) BOOL useHTTPPost;

@end

@interface ESRequestProxyAdapter ()

@property (nonatomic, retain) ASIHTTPRequest *request;
@property (nonatomic, copy) SFRequestProxyCompletion completion;

@end

@implementation ESRequestProxyAdapter

- (void)dealloc
{
    [_request clearDelegatesAndCancel];
}

+ (instancetype)requestWithURLString:(NSString *)URLString useHTTPPost:(BOOL)useHTTPPost
{
    ESRequestProxyAdapter *adapter = [ESRequestProxyAdapter new];
    adapter.URLString = URLString;
    adapter.useHTTPPost = useHTTPPost;
    return adapter;
}

- (void)requestWithParameters:(NSDictionary *)parameters completion:(SFRequestProxyCompletion)completion
{
    [self cancel];
    self.completion = completion;
    
    self.request = self.useHTTPPost ? [self HTTPPostWithParameters:parameters] : [self HTTPGetWithParameters:parameters];
    self.request.delegate = self;
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

- (void)_notifyResponse:(id)response
{
    if (self.completion) {
        self.completion(response);
    }
}

#pragma mark - ASIHTTPRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request
{
    [self _notifyResponse:request.responseString];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    [self _notifyResponse:request.error];
}

@end

@interface ESServiceSessionAdapter : NSObject <ESService>

@property (nonatomic, copy) NSString *URLString;
@property (nonatomic, assign) BOOL useHTTPPost;
@property (nonatomic, copy) SFRequestProxyResponseProcessor responseProcessor;

@end

@interface ESServiceSessionAdapter ()

@property (nonatomic, retain) SFObjectServiceSession *session;

@end

@implementation ESServiceSessionAdapter

- (void)dealloc
{
    [_session cancel];
}

+ (instancetype)sessionWithURLString:(NSString *)URLString useHTTPPost:(BOOL)useHTTPPost responseProcessor:(SFRequestProxyResponseProcessor)responseProcessor
{
    ESServiceSessionAdapter *adapter = [ESServiceSessionAdapter new];
    adapter.URLString = URLString;
    adapter.useHTTPPost = useHTTPPost;
    adapter.responseProcessor = responseProcessor;
    return adapter;
}

- (id)init
{
    self = [super init];
    
    _session = [SFObjectServiceSession new];
    
    return self;
}

- (void)requestWithCompletion:(ESServiceCompletion)completion
{
    self.session.requestProxy = [ESRequestProxyAdapter requestWithURLString:self.URLString useHTTPPost:self.useHTTPPost];
    [self.session setSessionDidFinishHandler:^(id resultObject) {
        NSError *error = [resultObject isKindOfClass:[NSError class]] ? resultObject : nil;
        if (completion) {
            completion(error == nil ? resultObject : nil, error);
        }
    }];
    [self.session start];
}

- (void)cancel
{
    [self.session cancel];
}

- (BOOL)isExecuting
{
    return [self.session isExexuting];
}

- (void)willRemoveFromObjectRepository
{
    [self.session willRemoveFromObjectRepository];
}

- (BOOL)shouldRemoveFromObjectRepository
{
    return [self.session shouldRemoveFromObjectRepository];
}

- (void)setResponseProcessor:(SFRequestProxyResponseProcessor)responseProcessor
{
    self.session.responseProcessor = responseProcessor;
}

- (SFRequestProxyResponseProcessor)responseProcessor
{
    return self.session.responseProcessor;
}

- (void)setParameterWithKey:(NSString *)key value:(NSString *)value
{
    [self.session setParameterValue:value forKey:key];
}

- (void)removeParameterWithKey:(NSString *)key
{
    [self.session removeParameterValueForKey:key];
}

@end

@implementation ESServiceFactory

+ (id<ESService>)eslEpisodes
{
    ESServiceSessionAdapter *session = [ESServiceSessionAdapter sessionWithURLString:@"http://www.eslpod.com/website/index_new.html" useHTTPPost:NO responseProcessor:^id(id response, NSError *__autoreleasing *error) {
        return response;
    }];
    return session;
}

@end
