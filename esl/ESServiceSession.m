//
//  ESServiceSession.m
//  esl
//
//  Created by yangzexin on 10/26/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESServiceSession.h"

@interface ESServiceSession ()

@property (nonatomic, strong) SFObjectServiceSession *session;
@property (nonatomic, strong) id<SFRequestProxy> requestProxy;
@property (nonatomic, copy) SFRequestProxyResponseProcessor responseProcessor;

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
    self.session.requestProxy = self.requestProxy;
    __block typeof(self) bself = self;
    [self.session setSessionDidStartHandler:self.sessionDidStartHandler];
    [self.session setSessionWillStartHandler:self.sessionWillStartHandler];
    [self.session setSessionDidFinishHandler:^(id resultObject, NSError *error) {
        if (bself.sessionDidFinishHandler) {
            bself.sessionDidFinishHandler(resultObject, error);
        }
        if (completion) {
            completion(resultObject, error);
        }
    }];
    [self.session start];
}

- (void)cancel
{
    [self.session cancel];
}

- (void)setResponseProcessor:(SFRequestProxyResponseProcessor)responseProcessor
{
    [self.session setResponseProcessor:responseProcessor];
}

- (SFRequestProxyResponseProcessor)responseProcessor
{
    return self.session.responseProcessor;
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

- (void)setParameterWithKey:(NSString *)key value:(NSString *)value
{
    [self.session setParameterWithKey:key value:value];
}

- (void)removeParameterWithKey:(NSString *)key
{
    [self.session removeParameterValueWithKey:key];
}

@end
