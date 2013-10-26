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

@interface ESBlockHTTPRequestCacheOperator ()

@property (nonatomic, copy) NSData *(^reader)(NSString *);
@property (nonatomic, copy) void (^writer)(NSData *, NSString *);

@end

@implementation ESBlockHTTPRequestCacheOperator

- (NSData *)cachedDataWithIdentifier:(NSString *)identifier
{
    return self.reader(identifier);
}

- (void)storeCacheData:(NSData *)data identifier:(NSString *)identifier
{
    self.writer(data, identifier);
}

+ (instancetype)cacheOpeartorWithReader:(NSData *(^)(NSString *identifier))reader writer:(void(^)(NSData *data, NSString *identifier))writer
{
    ESBlockHTTPRequestCacheOperator *operator = [ESBlockHTTPRequestCacheOperator new];
    operator.reader = reader;
    operator.writer = writer;
    return operator;
}

@end

@interface ESHTTPRequest () <ASIHTTPRequestDelegate>

@property (nonatomic, retain) ASIHTTPRequest *request;
@property (nonatomic, copy) SFRequestProxyCompletion completion;
@property (nonatomic, copy) NSString *cacheIdentifier;

@end

@implementation ESHTTPRequest

- (void)dealloc
{
    [_request clearDelegatesAndCancel];
}

+ (instancetype)requestWithURLString:(NSString *)URLString useHTTPPost:(BOOL)useHTTPPost
{
    ESHTTPRequest *adapter = [ESHTTPRequest new];
    adapter.URLString = URLString;
    adapter.useHTTPPost = useHTTPPost;
    return adapter;
}

- (void)requestWithParameters:(NSDictionary *)parameters completion:(SFRequestProxyCompletion)completion
{
    [self cancel];
    self.completion = completion;
    
    if (self.useCache && self.cacheOperator != nil) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.cacheIdentifier = [self _cacheUniqueIdentifierWithParameters:parameters];
            NSData *data = [self.cacheOperator cachedDataWithIdentifier:self.cacheIdentifier];
            if (data != nil && data.length != 0) {
                [self _finishWithData:data fromCache:YES];
            } else {
                [self _startRequestWithParameters:parameters];
            }
        });
    } else {
        [self _startRequestWithParameters:parameters];
    }
}

- (void)_startRequestWithParameters:(NSDictionary *)parameters
{
    self.request = self.useHTTPPost ? [self HTTPPostWithParameters:parameters] : [self HTTPGetWithParameters:parameters];
    [self.request setTimeOutSeconds:30.0f];
    self.request.delegate = self;
    [self.request startAsynchronous];
}

- (NSString *)_cacheUniqueIdentifierWithParameters:(NSDictionary *)parameters
{
    NSMutableString *string = [NSMutableString stringWithString:self.URLString];
    [string appendString:@"{"];
    NSMutableString *paramString = [NSMutableString string];
    for (NSString *key in [parameters allKeys]) {
        [paramString appendFormat:@"%@:%@,", key, [parameters objectForKey:key]];
    }
    if (paramString.length != 0) {
        [paramString deleteCharactersInRange:NSMakeRange(paramString.length - 1, 1)];
    }
    [string appendString:paramString];
    [string appendString:@"}"];
    return [string stringByEncryptingUsingMD5];
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

- (void)_finishWithData:(NSData *)data fromCache:(BOOL)fromCache
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        id responseData = data;
        if (self.responseDataWrapper) {
            responseData = self.responseDataWrapper(responseData);
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (self.requestDidFinish) {
                self.requestDidFinish(responseData, fromCache);
            }
        });
        [self _notifyResponse:responseData error:nil];
    });
}

#pragma mark - ASIHTTPRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request
{
    NSData *data = request.responseData;
    [self _finishWithData:data fromCache:NO];
    if (self.useCache && self.cacheOperator != nil) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.cacheOperator storeCacheData:data identifier:self.cacheIdentifier];
        });
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    [self _notifyResponse:nil error:request.error];
}

@end
