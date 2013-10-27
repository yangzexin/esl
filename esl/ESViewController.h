//
//  ESViewController.h
//  esl
//
//  Created by yangzexin on 10/25/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFViewController.h"
#import "ESService.h"

@interface ESViewController : SFViewController

- (void)requestService:(id<ESService>)service identifier:(NSString *)identifier completion:(ESServiceCompletion)completion;
- (void)requestService:(id<ESService>)service completion:(ESServiceCompletion)completion;

@end