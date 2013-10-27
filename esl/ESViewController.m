//
//  ESViewController.m
//  esl
//
//  Created by yangzexin on 10/25/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESViewController.h"
#import <objc/runtime.h>

@interface ESViewController ()

@property (nonatomic, strong) SFObjectRepository *objectRepository;
@property (nonatomic, strong) NSMutableDictionary *keyIdentifierValueService;

@end

@implementation ESViewController

- (SFObjectRepository *)objectRepository
{
    if (_objectRepository == nil) {
        _objectRepository = [SFObjectRepository new];
    }
    return _objectRepository;
}

- (NSMutableDictionary *)keyIdentifierValueService
{
    if (_keyIdentifierValueService == nil) {
        _keyIdentifierValueService = [NSMutableDictionary dictionary];
    }
    return _keyIdentifierValueService;
}

- (void)requestService:(id<ESService>)service completion:(ESServiceCompletion)completion
{
    [self requestService:service identifier:nil completion:completion];
}

- (void)requestService:(id<ESService>)service identifier:(NSString *)identifier completion:(ESServiceCompletion)completion
{
    if (identifier) {
        id<ESService> existService = [self.keyIdentifierValueService objectForKey:identifier];
        [existService cancel];
        [self.keyIdentifierValueService removeObjectForKey:identifier];
        
        [self.keyIdentifierValueService setObject:service forKey:identifier];
    }
    [self.objectRepository addObject:service];
    [service requestWithCompletion:completion];
}

@end