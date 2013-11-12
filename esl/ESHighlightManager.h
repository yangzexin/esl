//
//  ESHighlightManager.h
//  esl
//
//  Created by yangzexin on 11/12/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESHighlight.h"

@protocol ESHighlightManager <NSObject>

- (NSArray *)highlights;
- (void)addHighlight:(ESHighlight *)highlight;
- (void)removeHighlight:(ESHighlight *)highlight;
- (void)removeHighlightFromIndex:(NSInteger)fromIndex endIndex:(NSInteger)endIndex recursive:(BOOL)recursive;
- (BOOL)highlightExistsAtFromIndex:(NSInteger)fromIndex endIndex:(NSInteger)endIndex;

@end

@interface ESSharedHighlightManager : NSObject

+ (id<ESHighlightManager>)highlightManagerWithIdentifier:(NSString *)identifier;

@end
