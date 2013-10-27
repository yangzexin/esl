//
//  ESServiceSession.h
//  esl
//
//  Created by yangzexin on 10/26/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESService.h"
#import "SFObjectServiceSession.h"

@interface ESServiceSession : NSObject <ESService>

+ (instancetype)sessionWithRequestProxy:(id<SFRequestProxy>)requestProxy;
+ (instancetype)sessionWithRequestProxy:(id<SFRequestProxy>)requestProxy responseProcessor:(SFRequestProxyResponseProcessor)responseProcessor;

- (void)setParameterWithKey:(NSString *)key value:(NSString *)value;
- (void)removeParameterWithKey:(NSString *)key;

- (void)setSessionWillStartHandler:(void(^)())handler;
- (void)setSessionDidStartHandler:(void(^)())handler;
- (void)setSessionDidFinishHandler:(void(^)(id resultObject, NSError *error))handler;

@end
