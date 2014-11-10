//
//  SFCache.h
//  
//
//  Created by yangzexin on 10/15/13.
//  Copyright (c) 2013 __MyCompany__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SFCacheDecorator <NSObject>

- (NSData *)decoratedDataByDecoratingWithOriginalData:(NSData *)cacheData;
- (NSData *)originalDataByRestoringWithDecoratedData:(NSData *)decoratedData;

@end

@interface SFBlockedCacheDecorator : NSObject <SFCacheDecorator>

+ (instancetype)cacheDecoratorWithDecorator:(NSData *(^)(NSData *originalData))decorator restorer:(NSData *(^)(NSData *decoratedData))restorer;

@end

@protocol SFCache <NSObject>

@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) NSDate *createDate;
@property (nonatomic, strong, readonly) NSData *data;
@property (nonatomic, copy, readonly) NSString *applicationIdentifier;

@end

@protocol SFCacheFilter <NSObject>

- (BOOL)isCacheValid:(id<SFCache>)cache;

@end

@protocol SFCacheManager <NSObject>

- (NSData *)cachedDataWithIdentifier:(NSString *)identifier filter:(id<SFCacheFilter>)filter;
- (void)storeCacheWithIdentifier:(NSString *)identifier data:(NSData *)data;
- (void)clearCacheWithIdentifier:(NSString *)identifier;
- (BOOL)isCacheExistsWithIdentifier:(NSString *)identifier;

@end
