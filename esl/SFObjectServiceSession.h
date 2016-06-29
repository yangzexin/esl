//
//  SFObjectServiceSession.h
//  
//
//  Created by yangzexin on 10/25/13.
//  Copyright (c) 2013 __MyCompany__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^SFRequestProxyCompletion)(id response, NSError *error);

@protocol SFRequestProxy <NSObject>

- (void)requestWithParameters:(NSDictionary *)parameters completion:(SFRequestProxyCompletion)completion;
- (void)cancel;

@end

typedef id(^SFRequestProxyResponseProcessor)(id response, NSError **error);

typedef NS_ENUM(NSUInteger, SFObjectServiceSessionError) {
    SFObjectServiceSessionErrorNilRequestPorxy
};

@class SFObjectServiceSession;

@protocol SFObjectServiceSessionDelegate <NSObject>

@optional
- (id)objectServiceSession:(SFObjectServiceSession *)session objectByProcessingWithResponse:(id)response outError:(NSError **)outError;
- (void)objectServiceSessionWillStart:(SFObjectServiceSession *)session;
- (void)objectServiceSessionDidStart:(SFObjectServiceSession *)session;
- (void)objectServiceSession:(SFObjectServiceSession *)session didFinishWithResultObject:(id)resultObject error:(NSError *)error;

@end

@interface SFObjectServiceSession : NSObject <SFDepositable>

@property (nonatomic, retain) id<SFRequestProxy> requestProxy;
@property (nonatomic, assign) id<SFObjectServiceSessionDelegate> delegate;

+ (instancetype)sessionWithRequestProxy:(id<SFRequestProxy>)requestProxy;

- (void)start;
- (void)startDiscardingExecutionIsRunning;
- (BOOL)isExecuting;
- (void)cancel;

@end

@interface SFObjectServiceSession (LifeCycle)

- (void)sessionWillStart;
- (void)sessionDidStart;
- (void)sessionDidFinishWithResultObject:(id)resultObject error:(NSError *)error;

@end

@interface SFObjectServiceSession (ParameterSupport)

- (void)setParameterWithKey:(NSString *)key value:(id)value;
- (id)parameterValueForKey:(NSString *)key;
- (void)removeParameterValueWithKey:(NSString *)key;
- (void)setParametersFromDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)parameters;
- (void)removeAllParameters;

@end
