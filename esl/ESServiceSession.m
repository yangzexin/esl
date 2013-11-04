//
//  ESServiceSession.m
//  esl
//
//  Created by yangzexin on 10/26/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESServiceSession.h"

@interface ESServiceSession () <SFObjectServiceSessionDelegate>

@property (nonatomic, strong) SFObjectServiceSession *session;
@property (nonatomic, strong) id<SFRequestProxy> requestProxy;
@property (nonatomic, copy) SFRequestProxyResponseProcessor responseProcessor;
@property (nonatomic, copy) ESServiceCompletion completion;

@property (nonatomic, copy) void(^sessionWillStartHandler)();
@property (nonatomic, copy) void(^sessionDidStartHandler)();
@property (nonatomic, copy) void(^sessionDidFinishHandler)(id resultObject, NSError *error);

@end

@implementation ESServiceSession

- (void)dealloc
{
    [_session cancel];
}

+ (instancetype)sessionWithRequestProxy:(id<SFRequestProxy>)requestProxy
{
    return [self sessionWithRequestProxy:requestProxy responseProcessor:nil];
}

+ (instancetype)sessionWithRequestProxy:(id<SFRequestProxy>)requestProxy responseProcessor:(SFRequestProxyResponseProcessor)responseProcessor
{
    ESServiceSession *adapter = [ESServiceSession new];
    adapter.requestProxy = requestProxy;
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
    self.completion = completion;
    self.session.requestProxy = self.requestProxy;
    self.session.delegate = self;
    [self.session start];
}

- (void)cancel
{
    [self.session cancel];
}

- (BOOL)isExecuting
{
    return [self.session isExecuting];
}

- (void)willRemoveFromObjectRepository
{
    [self.session willRemoveFromObjectRepository];
}

- (BOOL)shouldRemoveFromObjectRepository
{
    return [self.session shouldRemoveFromObjectRepository];
}

- (void)setParameterWithKey:(NSString *)key value:(NSString *)value
{
    [self.session setParameterWithKey:key value:value];
}

- (void)removeParameterWithKey:(NSString *)key
{
    [self.session removeParameterValueWithKey:key];
}

#pragma mark - SFObjectServiceSession
- (id)objectServiceSession:(SFObjectServiceSession *)session objectByProcessingWithResponse:(id)response outError:(NSError **)outError
{
    if (self.responseProcessor) {
        self.responseProcessor(response, outError);
    }
    return response;
}

- (void)objectServiceSessionWillStart:(SFObjectServiceSession *)session
{
    if (self.sessionWillStartHandler) {
        self.sessionWillStartHandler();
    }
}

- (void)objectServiceSessionDidStart:(SFObjectServiceSession *)session
{
    if (self.sessionDidStartHandler) {
        self.sessionDidStartHandler();
    }
}

- (void)objectServiceSession:(SFObjectServiceSession *)session didFinishWithResultObject:(id)resultObject error:(NSError *)error
{
    if (self.sessionDidFinishHandler) {
        self.sessionDidFinishHandler(resultObject, error);
    }
    if (self.completion) {
        self.completion(resultObject, error);
    }
}

@end
