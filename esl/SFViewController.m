//
//  SFViewController.m
//  SimpleFramework
//
//  Created by yangzexin on 13-7-4.
//  Copyright (c) 2013年 __MyCompanyName__. All rights reserved.
//

#import "SFViewController.h"

#pragma mark - SFViewControllerBaseObserverWrapper
@interface SFViewControllerBaseObserverWrapper : NSObject

@property(nonatomic, assign)id observer;

@end

@implementation SFViewControllerBaseObserverWrapper

@end

#pragma mark - SFViewControllerObserverAnimatedBlockWrapper
@interface SFViewControllerObserverAnimatedBlockWrapper : SFViewControllerBaseObserverWrapper

@property(nonatomic, copy)void(^block)(BOOL animated);

+ (id)wrapperWithObserver:(id)observer block:(void(^)(BOOL animated))block;

@end

@implementation SFViewControllerObserverAnimatedBlockWrapper

- (void)dealloc
{
    Block_release(_block);
    [super dealloc];
}

+ (id)wrapperWithObserver:(id)observer block:(void(^)(BOOL animated))block
{
    SFViewControllerObserverAnimatedBlockWrapper *wrapper = [[SFViewControllerObserverAnimatedBlockWrapper new] autorelease];
    wrapper.observer = observer;
    wrapper.block = block;
    return wrapper;
}

@end

#pragma mark - SFViewControllerObserverBlockWrapper
@interface SFViewControllerObserverBlockWrapper : SFViewControllerBaseObserverWrapper

@property(nonatomic, copy)void(^block)();

+ (id)wrapperWithObserver:(id)observer block:(void(^)())block;

@end

@implementation SFViewControllerObserverBlockWrapper

- (void)dealloc
{
    Block_release(_block);
    [super dealloc];
}

+ (id)wrapperWithObserver:(id)observer block:(void(^)())block
{
    SFViewControllerObserverBlockWrapper *wrapper = [[SFViewControllerObserverBlockWrapper new] autorelease];
    wrapper.observer = observer;
    wrapper.block = block;
    return wrapper;
}

@end

#pragma mark - SFViewControllerObservers
@interface SFViewControllerObservers : NSObject

@property(nonatomic, retain)NSMutableArray *observers;

@end

@implementation SFViewControllerObservers

- (void)dealloc
{
    [_observers release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    
    self.observers = [NSMutableArray array];
    
    return self;
}

- (void)addObserverWithWrapper:(SFViewControllerBaseObserverWrapper *)wrapper
{
    SFViewControllerBaseObserverWrapper *existWrapper = nil;
    for(SFViewControllerBaseObserverWrapper *tmpWrapper in self.observers){
        if(tmpWrapper.observer == wrapper.observer){
            existWrapper = tmpWrapper;
            break;
        }
    }
    if(existWrapper != nil){
        if([wrapper isKindOfClass:[SFViewControllerObserverAnimatedBlockWrapper class]]){
            SFViewControllerObserverAnimatedBlockWrapper *convertedExistWrapper = (id)existWrapper;
            SFViewControllerObserverAnimatedBlockWrapper *convertedWrapper = (id)wrapper;
            convertedExistWrapper.block = convertedWrapper.block;
        }else if([wrapper isKindOfClass:[SFViewControllerObserverBlockWrapper class]]){
            SFViewControllerObserverBlockWrapper *convertedExistWrapper = (id)existWrapper;
            SFViewControllerObserverBlockWrapper *convertedWrapper = (id)wrapper;
            convertedExistWrapper.block = convertedWrapper.block;
        }
    }else{
        [self.observers addObject:wrapper];
    }
}

- (void)removeObserverWithWrapper:(SFViewControllerObserverBlockWrapper *)wrapper
{
    [self removeObserverWrapperWithObserver:wrapper.observer];
}

- (void)removeObserverWrapperWithObserver:(id)observer
{
    SFViewControllerBaseObserverWrapper *existWrapper = nil;
    for(SFViewControllerBaseObserverWrapper *tmpWrapper in self.observers){
        if(tmpWrapper.observer == observer){
            existWrapper = tmpWrapper;
            break;
        }
    }
    if(existWrapper != nil){
        [self.observers removeObject:existWrapper];
    }
}

- (void)enumerateWrapperUsingBlock:(void(^)(SFViewControllerBaseObserverWrapper *wrapper))block
{
    NSArray *tmpObservers = [self.observers copy];
    [tmpObservers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        block(obj);
    }];
}

@end

#pragma mark - SFViewController
@interface SFViewController ()

@property(nonatomic, retain)SFViewControllerObservers *viewWillAppearObservers;
@property(nonatomic, retain)SFViewControllerObservers *viewDidAppearObservers;
@property(nonatomic, retain)SFViewControllerObservers *viewDidDisappearObservers;
@property(nonatomic, retain)SFViewControllerObservers *viewWillDisappearObservers;
@property(nonatomic, retain)SFViewControllerObservers *viewDidLoadObservers;
@property(nonatomic, retain)SFViewControllerObservers *loadViewObservers;

@end

@implementation SFViewController

- (void)dealloc
{
    [_viewWillAppearObservers release];
    [_viewDidAppearObservers release];
    [_viewDidDisappearObservers release];
    [_viewWillDisappearObservers release];
    [_viewDidLoadObservers release];
    [_loadViewObservers release];
    [super dealloc];
}

#pragma mark - Observers

#pragma mark - viewWillAppear
- (void)addViewWillAppearObserver:(id)observer usingBlock:(void(^)(BOOL animated))block
{
    if(self.viewWillAppearObservers == nil){
        self.viewWillAppearObservers = [[SFViewControllerObservers new] autorelease];
    }
    [self.viewWillAppearObservers addObserverWithWrapper:[SFViewControllerObserverAnimatedBlockWrapper wrapperWithObserver:observer block:block]];
}

- (void)removeViewWillAppearObserver:(id)observer
{
    [self.viewWillAppearObservers removeObserverWrapperWithObserver:observer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.viewWillAppearObservers enumerateWrapperUsingBlock:^(SFViewControllerBaseObserverWrapper *wrapper) {
        SFViewControllerObserverAnimatedBlockWrapper *animatedBlockWrapper = (id)wrapper;
        if(animatedBlockWrapper.block){
            animatedBlockWrapper.block(animated);
        }
    }];
}

#pragma mark - viewDidAppear
- (void)addViewDidAppearObserver:(id)observer usingBlock:(void(^)(BOOL animated))block
{
    if(self.viewDidAppearObservers == nil){
        self.viewDidAppearObservers = [[SFViewControllerObservers new] autorelease];
    }
    [self.viewDidAppearObservers addObserverWithWrapper:[SFViewControllerObserverAnimatedBlockWrapper wrapperWithObserver:observer block:block]];
}

- (void)removeViewDidAppearObserver:(id)observer
{
    [self.viewDidAppearObservers removeObserverWrapperWithObserver:observer];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.viewDidAppearObservers enumerateWrapperUsingBlock:^(SFViewControllerBaseObserverWrapper *wrapper) {
        SFViewControllerObserverAnimatedBlockWrapper *animatedBlockWrapper = (id)wrapper;
        if(animatedBlockWrapper.block){
            animatedBlockWrapper.block(animated);
        }
    }];
}

#pragma mark - viewDidDisappear
- (void)addViewDidDisappearObserver:(id)observer usingBlock:(void(^)(BOOL animated))block
{
    if(self.viewDidDisappearObservers == nil){
        self.viewDidDisappearObservers = [[SFViewControllerObservers new] autorelease];
    }
    [self.viewDidDisappearObservers addObserverWithWrapper:[SFViewControllerObserverAnimatedBlockWrapper wrapperWithObserver:observer block:block]];
}

- (void)removeViewDidDisappearObserver:(id)observer
{
    [self.viewDidDisappearObservers removeObserverWrapperWithObserver:observer];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.viewDidDisappearObservers enumerateWrapperUsingBlock:^(SFViewControllerBaseObserverWrapper *wrapper) {
        SFViewControllerObserverAnimatedBlockWrapper *animatedBlockWrapper = (id)wrapper;
        if(animatedBlockWrapper.block){
            animatedBlockWrapper.block(animated);
        }
    }];
}

#pragma mark - viewWillDisappear
- (void)addViewWillDisappearObserver:(id)observer usingBlock:(void(^)(BOOL animated))block
{
    if(self.viewWillDisappearObservers == nil){
        self.viewWillDisappearObservers = [[SFViewControllerObservers new] autorelease];
    }
    [self.viewWillDisappearObservers addObserverWithWrapper:[SFViewControllerObserverAnimatedBlockWrapper wrapperWithObserver:observer block:block]];
}

- (void)removeViewWillDisappearObserver:(id)observer
{
    [self.viewWillDisappearObservers removeObserverWrapperWithObserver:observer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.viewWillDisappearObservers enumerateWrapperUsingBlock:^(SFViewControllerBaseObserverWrapper *wrapper) {
        SFViewControllerObserverAnimatedBlockWrapper *animatedBlockWrapper = (id)wrapper;
        if(animatedBlockWrapper.block){
            animatedBlockWrapper.block(animated);
        }
    }];
}

#pragma mark - viewDidLoad
- (void)addViewDidLoadObserver:(id)observer usingBlock:(void(^)())block
{
    if(self.viewDidLoadObservers == nil){
        self.viewDidLoadObservers = [[SFViewControllerObservers new] autorelease];
    }
    [self.viewDidLoadObservers addObserverWithWrapper:[SFViewControllerObserverBlockWrapper wrapperWithObserver:observer block:block]];
}

- (void)removeViewDidLoadObserver:(id)observer
{
    [self.viewDidLoadObservers removeObserverWrapperWithObserver:observer];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.viewDidLoadObservers enumerateWrapperUsingBlock:^(SFViewControllerBaseObserverWrapper *wrapper) {
        SFViewControllerObserverBlockWrapper *tmpWrapper = (id)wrapper;
        if(tmpWrapper.block){
            tmpWrapper.block();
        }
    }];
}

#pragma mark - loadView
- (void)addLoadViewObserver:(id)observer usingBlock:(void(^)())block
{
    if(self.loadViewObservers == nil){
        self.loadViewObservers = [[SFViewControllerObservers new] autorelease];
    }
    [self.loadViewObservers addObserverWithWrapper:[SFViewControllerObserverBlockWrapper wrapperWithObserver:observer block:block]];
}

- (void)removeLoadViewObserver:(id)observer
{
    [self.loadViewObservers removeObserverWrapperWithObserver:observer];
}

- (void)loadView
{
    [super loadView];
    [self.loadViewObservers enumerateWrapperUsingBlock:^(SFViewControllerBaseObserverWrapper *wrapper) {
        SFViewControllerObserverBlockWrapper *tmpWrapper = (id)wrapper;
        if(tmpWrapper.block){
            tmpWrapper.block();
        }
    }];
}

@end
