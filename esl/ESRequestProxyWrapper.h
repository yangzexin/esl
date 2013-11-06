//
//  ESRequestProxyWrapper.h
//  esl
//
//  Created by yangzexin on 10/27/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFObjectServiceSession.h"

@interface ESRequestProxyWrapper : NSObject <SFRequestProxy>

@property (nonatomic, assign) BOOL runSynchronously;

+ (instancetype)wrapperWithRequestProxy:(id<SFRequestProxy>)requestProxy resultGetter:(id(^)(NSDictionary *parameters))resultGetter;
+ (instancetype)wrapperWithResultGetter:(id(^)(NSDictionary *parameters))resultGetter;

@end
