//
//  ESASIHTTPRequestAdapter.h
//  esl
//
//  Created by yangzexin on 10/26/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFObjectServiceSession.h"

@protocol ESHTTPRequestCacheOperator <NSObject>

- (NSData *)cachedDataWithIdentifier:(NSString *)identifier;
- (void)storeCacheData:(NSData *)data identifier:(NSString *)identifier;

@end

@interface ESBlockHTTPRequestCacheOperator : NSObject <ESHTTPRequestCacheOperator>

+ (instancetype)cacheOpeartorWithReader:(NSData *(^)(NSString *identifier))reader writer:(void(^)(NSData *data, NSString *identifier))writer;

@end

@interface ESHTTPRequest : NSObject <SFRequestProxy>

@property (nonatomic, copy) NSString *URLString;
@property (nonatomic, assign) BOOL useHTTPPost;
@property (nonatomic, copy) id(^responseDataWrapper)(NSData *responseData);

@property (nonatomic, assign) BOOL useCache;
@property (nonatomic, retain) id<ESHTTPRequestCacheOperator> cacheOperator;

@property (nonatomic, copy) void(^requestDidFinish)(id response, BOOL fromCache);

+ (instancetype)requestWithURLString:(NSString *)URLString useHTTPPost:(BOOL)useHTTPPost;

@end
