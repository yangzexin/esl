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

@end

@implementation ESViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.objectRepository = [SFObjectRepository new];
}

- (void)requestService:(id<ESService>)service completion:(ESServiceCompletion)completion
{
    [self.objectRepository addObject:service];
    [service requestWithCompletion:completion];
}

@end