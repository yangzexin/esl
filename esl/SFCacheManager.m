//
//  SFCache.m
//  
//
//  Created by yangzexin on 10/15/13.
//  Copyright (c) 2013 __MyCompany__. All rights reserved.
//

#import "SFCacheManager.h"

@interface SFBlockedCacheDecorator ()

@property (nonatomic, copy) NSData *(^decorator)(NSData *originalData);
@property (nonatomic, copy) NSData *(^restorer)(NSData *decoratedData);

@end

@implementation SFBlockedCacheDecorator

+ (instancetype)cacheDecoratorWithDecorator:(NSData *(^)(NSData *originalData))decorator restorer:(NSData *(^)(NSData *decoratedData))restorer
{
    SFBlockedCacheDecorator *cacheDecorator = [SFBlockedCacheDecorator new];
    cacheDecorator.decorator = decorator;
    cacheDecorator.restorer = restorer;
    
    return cacheDecorator;
}

- (NSData *)decoratedDataByDecoratingWithOriginalData:(NSData *)cacheData
{
    if (_decorator) {
        cacheData = _decorator(cacheData);
    }
    
    return cacheData;
}

- (NSData *)originalDataByRestoringWithDecoratedData:(NSData *)decoratedData
{
    if (_restorer) {
        decoratedData = _restorer(decoratedData);
    }
    
    return decoratedData;
}

@end