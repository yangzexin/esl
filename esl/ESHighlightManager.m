//
//  ESHighlightManager.m
//  esl
//
//  Created by yangzexin on 11/12/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESHighlightManager.h"
#import "SFFileCacheManager.h"
#import "SFBuildInCacheFilters.h"

@interface ESHighlightManager : NSObject <ESHighlightManager>

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSArray *(^deserializer)(NSData *data);
@property (nonatomic, copy) NSData *(^serializer)(NSArray *highlights);
@property (nonatomic, strong) NSMutableArray *highlights;
@property (nonatomic, strong) SFFileCacheManager *cacheManager;

+ (instancetype)managerWithIdentifier:(NSString *)identifier;

@end

@implementation ESHighlightManager

+ (instancetype)managerWithIdentifier:(NSString *)identifier
{
    ESHighlightManager *mgr = [ESHighlightManager new];
    mgr.identifier = identifier;
    return mgr;
}

- (id)initWithIdentifier:(NSString *)identifier
{
    self = [super init];
    
    _identifier = [NSString stringWithFormat:@"%@-highlight", identifier];
    _cacheManager = [SFFileCacheManager fileCacheManagerWithFolderPath:[NSString stringWithFormat:@"%@/Documents/", NSHomeDirectory()]];
    NSData *cachedData = [_cacheManager cachedDataWithIdentifier:_identifier filter:[SFBuildInCacheFilters foreverCacheFilter]];
    _highlights = [NSMutableArray arrayWithArray:self.deserializer(cachedData)];
    
    return self;
}

- (void)_saveCurrentHighlights
{
    NSData *data = self.serializer(self.highlights);
    [_cacheManager storeCacheWithIdentifier:self.identifier data:data];
}

- (void)addHighlight:(ESHighlight *)highlight
{
    [self.highlights addObject:highlight];
    [self _saveCurrentHighlights];
}

- (void)removeHighlight:(ESHighlight *)highlight
{
    [[self.highlights copy] enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(ESHighlight *obj, NSUInteger idx, BOOL *stop) {
        if ([highlight.text isEqualToString:obj.text] && highlight.fromIndex == obj.fromIndex && highlight.endIndex == obj.endIndex) {
            [self.highlights removeObjectAtIndex:idx];
            *stop = YES;
        }
    }];
    [self _saveCurrentHighlights];
}

- (void)removeHighlightFromIndex:(NSInteger)fromIndex endIndex:(NSInteger)endIndex recursive:(BOOL)recursive
{
    [[self.highlights copy] enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(ESHighlight *obj, NSUInteger idx, BOOL *stop) {
        if (obj.fromIndex >= fromIndex && obj.endIndex <= endIndex) {
            [self.highlights removeObjectAtIndex:idx];
            if (recursive == NO) {
                *stop = YES;
            }
        }
    }];
    [self _saveCurrentHighlights];
}

- (NSArray *)highlightsInFromIndex:(NSInteger)fromIndex endIndex:(NSInteger)endIndex
{
    NSMutableArray *tmpHighlights = [NSMutableArray array];
    for (ESHighlight *highlight in [self.highlights copy]) {
        if (fromIndex >= highlight.fromIndex && endIndex <= highlight.endIndex) {
            [tmpHighlights addObject:highlight];
        }
    }
    return tmpHighlights;
}

- (BOOL)highlightExistsAtFromIndex:(NSInteger)fromIndex endIndex:(NSInteger)endIndex
{
    return [self highlightsInFromIndex:fromIndex endIndex:endIndex].count != 0;
}

@end

@implementation ESSharedHighlightManager

+ (id<ESHighlightManager>)highlightManagerWithIdentifier:(NSString *)identifier
{
    ESHighlightManager *mgr = [ESHighlightManager managerWithIdentifier:identifier];
    [mgr setSerializer:^NSData *(NSArray *highlights) {
        return [NSKeyedArchiver archivedDataWithRootObject:highlights];
    }];
    [mgr setDeserializer:^NSArray *(NSData *data) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }];
    return mgr;
}

@end
