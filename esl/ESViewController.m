//
//  ESViewController.m
//  esl
//
//  Created by yangzexin on 10/25/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESViewController.h"

#import <objc/runtime.h>

#import "AppDelegate.h"

@interface ESViewController ()

@property (nonatomic, strong) NSMutableDictionary *keyIdentifierValueService;

@end

@implementation ESViewController

- (void)dealloc
{
    NSLog(@"%@ dealloc", NSStringFromClass([self class]));
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
    self.toolbarHidden = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:self.toolbarHidden animated:animated];
}

- (void)requestService:(id<ESService>)service completion:(ESServiceCompletion)completion
{
    [self requestService:service identifier:nil completion:completion];
}

- (void)requestService:(id<ESService>)service identifier:(NSString *)identifier completion:(ESServiceCompletion)completion
{
    if (service) {
        [self sf_deposit:service identifier:identifier];
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

- (void)setLeftBarButtonItemAsSideMenuSwitcher
{
    UIView *showSideMenuImage = [[[NSBundle mainBundle] loadNibNamed:@"ShowSideMenuImage" owner:nil options:nil] lastObject];
    if (SFDeviceSystemVersion >= 7.0f) {
        for (UIView *view in [showSideMenuImage subviews]) {
            for (UIView *subview in [view subviews]) {
                subview.backgroundColor = [UIColor darkGrayColor];
            }
        }
    }
    showSideMenuImage.opaque = NO;
    UIImage *image = [showSideMenuImage sf_toImageLegacy];
    self.navigationItem.leftBarButtonItem = [SFBlockedBarButtonItem blockedBarButtonItemWithCustomView:({
        SFBlockedButton *button = [SFBlockedButton blockedButtonWithTapHandler:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:ESShowSideMenuNotification object:nil];
        }];
        [button setImage:image forState:UIControlStateNormal];
        button.frame = CGRectMake(0, 0, 60, 40);
        button;
    })];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    if ([self isViewLoaded] && self.view.window == nil) {
        self.view = nil;
    }
}

@end