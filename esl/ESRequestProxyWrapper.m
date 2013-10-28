//
//  ESRequestProxyWrapper.m
//  esl
//
//  Created by yangzexin on 10/27/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESRequestProxyWrapper.h"

@interface ESRequestProxyWrapper ()

@property (nonatomic, strong) id<SFRequestProxy> requestProxy;
@property (nonatomic, copy) id(^resultGetter)(NSDictionary *parameters);
@property (nonatomic, copy) SFRequestProxyCompletion completion;

@end

@implementation ESRequestProxyWrapper

+ (instancetype)wrapperWithRequestProxy:(id<SFRequestProxy>)requestProxy resultGetter:(id(^)(NSDictionary *parameters))resultGetter
{
    ESRequestProxyWrapper *wrapper = [ESRequestProxyWrapper new];
    wrapper.requestProxy = requestProxy;
    wrapper.resultGetter = resultGetter;
    
    return wrapper;
}

- (void)requestWithParameters:(NSDictionary *)parameters completion:(SFRequestProxyCompletion)completion
{
    self.completion = completion;
    if (self.resultGetter) {
        if (self.runSynchronously) {
            [self _useResultGetterWithParameters:parameters];
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self _useResultGetterWithParameters:parameters];
            });
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
        });
    } else {
        [self _useRequestProxyWithParameters:parameters];
    }
}

- (void)_useResultGetterWithParameters:(NSDictionary *)parameters
{
    id result = self.resultGetter(parameters);
    if (result == nil) {
        [self _useRequestProxyWithParameters:parameters];
    } else {
        [self _notifyResponse:result error:nil];
    }
}

- (void)_useRequestProxyWithParameters:(NSDictionary *)parameters
{
    __weak typeof(self) weakSelf = self;
    [self.requestProxy requestWithParameters:parameters completion:^(id response, NSError *error) {
        [weakSelf _notifyResponse:response error:error];
    }];
}

- (void)_notifyResponse:(id)response error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.completion) {
            self.completion(response, error);
        }
    });
}

- (void)cancel
{
    self.completion = nil;
    [self.requestProxy cancel];
}

@end
