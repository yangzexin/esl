//
//  ESService.h
//  esl
//
//  Created by yangzexin on 10/26/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^ESServiceCompletion)(id resultObject, NSError *error);

@protocol ESService <SFDepositable>

- (void)requestWithCompletion:(ESServiceCompletion)completion;
- (BOOL)isExecuting;
- (void)cancel;

@end
