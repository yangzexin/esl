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

@protocol SFCacheFilter;

@interface ESServiceSession : NSObject <ESService>

+ (instancetype)sessionWithRequestProxy:(id<SFRequestProxy>)requestProxy responseProcessor:(SFRequestProxyResponseProcessor)responseProcessor;

- (void)setParameterWithKey:(NSString *)key value:(NSString *)value;
- (void)removeParameterWithKey:(NSString *)key;

@end
