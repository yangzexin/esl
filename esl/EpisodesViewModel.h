//
//  EpisodesViewModel.h
//  esl
//
//  Created by yangzexin on 3/27/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseViewModel.h"

@interface EpisodesViewModel : BaseViewModel

@property (nonatomic, strong, readonly) NSArray *episodes;

@property (nonatomic, strong, readonly) RACSignal *refreshEpisodesSignal;

@end
