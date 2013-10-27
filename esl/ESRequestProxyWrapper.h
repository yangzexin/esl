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

+ (instancetype)wrapperWithRequestProxy:(id<SFRequestProxy>)requestProxy resultGetter:(id(^)(NSDictionary *parameters))resultGetter;

@end
