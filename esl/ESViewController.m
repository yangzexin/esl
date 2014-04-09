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

- (void)dealloc
{
    NSLog(@"%@ dealloc", NSStringFromClass([self class]));
}

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

- (void)stopRequestingServiceWithIdnentifier:(NSString *)identifier
{
    id<ESService> service = [self.keyIdentifierValueService objectForKey:identifier];
    [service cancel];
    [self.keyIdentifierValueService removeObjectForKey:identifier];
}

- (BOOL)shouldSideMenuControllerTriggerGesture:(id)sideMenuController
{
    return self.navigationController.viewControllers.count == 1;
}

- (void)loadView
{
    [super loadView];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)requestService:(id<ESService>)service completion:(ESServiceCompletion)completion
{
    [self requestService:service identifier:nil completion:completion];
}

- (void)requestService:(id<ESService>)service identifier:(NSString *)identifier completion:(ESServiceCompletion)completion
{
    if (service) {
        if (identifier) {
            [self stopRequestingServiceWithIdnentifier:identifier];
            [self.keyIdentifierValueService setObject:service forKey:identifier];
        }
        [self.objectRepository addObject:service];
        [service requestWithCompletion:completion];
    } else {
        if (completion) {
            completion(nil, [NSError errorWithDomain:NSStringFromClass([self class]) code:-1 userInfo:@{NSLocalizedDescriptionKey : @"service cannot be nil"}]);
        }
    }
}

- (CGFloat)startYPositionOfView
{
    return [UIDevice currentDevice].systemVersion.floatValue < 7.0f ? 0.0f : self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
}

@end