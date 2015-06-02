//
//  SFObjectServiceSession.m
//  
//
//  Created by yangzexin on 10/25/13.
//  Copyright (c) 2013 __MyCompany__. All rights reserved.
//

#import "SFObjectServiceSession.h"

@interface SFObjectServiceSession ()

@property (nonatomic, retain) NSMutableDictionary *parameters;
@property (nonatomic, assign) BOOL executing;
@property (atomic, assign) BOOL isCancelled;
@property (nonatomic, assign) BOOL sessionUsed;

@end

@implementation SFObjectServiceSession

- (void)dealloc
{
    [_requestProxy cancel]; [_requestProxy release]; _requestProxy = nil;
    _delegate = nil;
    [_parameters release]; _parameters = nil;
    [super dealloc];
}

+ (instancetype)sessionWithRequestProxy:(id<SFRequestProxy>)requestProxy
{
    SFObjectServiceSession *session = [[SFObjectServiceSession new] autorelease];
    session.requestProxy = requestProxy;
    return session;
}

- (id)init
{
    self = [super init];
    
    _parameters = [NSMutableDictionary new];
    _sessionUsed = NO;
    
    return self;
}

- (void)start
{
    [self _startDiscardingExecutionIsRunning:NO];
}

- (void)startDiscardingExecutionIsRunning
{
    [self _startDiscardingExecutionIsRunning:YES];
}

- (void)_startDiscardingExecutionIsRunning:(BOOL)discardingExecutionIsRunning
{
    @synchronized(self){
        self.sessionUsed = YES;
        if (self.executing == YES && discardingExecutionIsRunning == YES) {
            [self _cancelSession];
        }
        if (self.executing == NO) {
            self.isCancelled = NO;
            [self sessionWillStart];
            self.executing = YES;
            if (self.requestProxy != nil) {
                __block typeof(self) bself = self;
                [self.requestProxy requestWithParameters:self.parameters completion:^(id response, NSError *error) {
                    if (error) {
                        [bself _sessionFinishWithResultObject:nil error:error];
                    } else {
                        [bself _handleRequestProxyResponse:response];
                    }
                }];
                [self sessionDidStart];
            } else {
                [self sessionDidFinishWithResultObject:nil error:[self _requestProxyNilError]];
                // finish by error
                self.executing = NO;
            }
        }
    }
}

- (void)_cancelSession
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.requestProxy cancel];
        self.isCancelled = YES;
        // finish by cancellation
        self.executing = NO;
    });
}

- (BOOL)isExecuting
{
    return self.executing;
}

- (void)cancel
{
    [self _cancelSession];
}

- (void)_sessionFinishWithResultObject:(id)resultObject error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self sessionDidFinishWithResultObject:resultObject error:error];
        // finish by session finish
        self.executing = NO;
    });
}

- (void)_handleRequestProxyResponse:(id)response
{
    __block typeof(self) bself = self;
    [self _asyncHandleRequestProxyResponse:response completion:^(id resultObject, NSError *error) {
        if (bself.isCancelled == NO) {
            [bself _sessionFinishWithResultObject:resultObject error:error];
        }
    }];
}

- (void)_asyncHandleRequestProxyResponse:(id)response completion:(void(^)(id resultObject, NSError *error))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        id resultObject = nil;
        if ([self.delegate respondsToSelector:@selector(objectServiceSession:objectByProcessingWithResponse:outError:)]) {
            resultObject = [self.delegate objectServiceSession:self objectByProcessingWithResponse:response outError:&error];
        }
        completion(resultObject, error);
    });
}

- (NSError *)_requestProxyNilError
{
    return [NSError errorWithDomain:NSStringFromClass([self class])
                               code:SFObjectServiceSessionErrorNilRequestPorxy
                           userInfo:@{NSLocalizedDescriptionKey : @"error when starting session using nil requestProxy"}];
}

#pragma mark - SFRepositionSupportedObject
- (BOOL)shouldRemoveDepositable
{
    return self.sessionUsed && self.executing == NO;
}

- (void)depositableWillRemove
{
    [self cancel];
}

#pragma mark - LifeCycle
- (void)sessionWillStart
{
    if ([self.delegate respondsToSelector:@selector(objectServiceSessionWillStart:)]) {
        [self.delegate objectServiceSessionWillStart:self];
    }
}

- (void)sessionDidStart
{
    if ([self.delegate respondsToSelector:@selector(objectServiceSessionDidStart:)]) {
        [self.delegate objectServiceSessionDidStart:self];
    }
}

- (void)sessionDidFinishWithResultObject:(id)resultObject error:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(objectServiceSession:didFinishWithResultObject:error:)]) {
        [self.delegate objectServiceSession:self didFinishWithResultObject:resultObject error:error];
    }
}

#pragma mark - KeyValueParameter
- (void)setParameterWithKey:(NSString *)key value:(id)value
{
    if(value == nil){
        [self removeParameterValueWithKey:key];
    }else{
        [_parameters setObject:value forKey:key];
    }
}

- (id)parameterValueForKey:(NSString *)key
{
    return [self.parameters objectForKey:key];
}

- (void)removeParameterValueWithKey:(NSString *)key
{
    [_parameters removeObjectForKey:key];
}

- (void)setParametersFromDictionary:(NSDictionary *)dictionary
{
    [_parameters addEntriesFromDictionary:dictionary];
}

- (void)removeAllParameters
{
    [_parameters removeAllObjects];
}

@end