//
//  ESASIHTTPRequestAdapter.h
//  esl
//
//  Created by yangzexin on 10/26/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SFObjectServiceSession.h"

@interface ESHTTPRequest : NSObject <SFRequestProxy>

@property (nonatomic, copy) NSString *URLString;
@property (nonatomic, assign) BOOL useHTTPPost;
@property (nonatomic, copy) id(^responseDataWrapper)(NSData *responseData);

@property (nonatomic, copy) void(^requestProgressDidChange)(float percent);

+ (instancetype)requestWithURLString:(NSString *)URLString;
+ (instancetype)requestWithURLString:(NSString *)URLString useHTTPPost:(BOOL)useHTTPPost;

- (void)requestWithParameters:(NSDictionary *)parameters completion:(void(^)(NSData *responseData, NSError *error))completion;

@end
