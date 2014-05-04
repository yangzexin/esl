//
//  SFDBCacheManager.m
//  DemoProject
//
//  Created by yangzexin on 5/1/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "SFDBCacheManager.h"
#import <Objective-LevelDB/LevelDB.h>
#import "SFCacheUtils.h"

@interface SFDBCache : NSObject <SFCache>

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, strong) NSDate *createDate;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, copy) NSString *applicationIdentifier;

@end

@implementation SFDBCache

- (NSDictionary *)toDictionary
{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return @{@"identifier" : _identifier
             , @"createDate" : [dateFormatter stringFromDate:_createDate]
             , @"data" : _data
             , @"applicationIdentifier" : _applicationIdentifier};
}

+ (instancetype)DBCacheFromDictionary:(NSDictionary *)dictionary
{
    SFDBCache *cache = [SFDBCache new];
    cache.identifier = [dictionary objectForKey:@"identifier"];
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    cache.createDate = [dateFormatter dateFromString:[dictionary objectForKey:@"createDate"]];
    cache.data = [dictionary objectForKey:@"data"];
    cache.applicationIdentifier = [dictionary objectForKey:@"applicationIdentifier"];
    
    return cache;
}

@end

@interface SFDBCacheManager ()

@property (nonatomic, strong) LevelDB *db;

@end

@implementation SFDBCacheManager

+ (instancetype)cacheManagerInLibraryWithName:(NSString *)name
{
    SFDBCacheManager *mgr = [[SFDBCacheManager alloc] initWithName:name];
    
    return mgr;
}

- (id)initWithName:(NSString *)name
{
    self = [super init];
    
    self.db = [LevelDB databaseInLibraryWithName:name];
    __weak typeof(self) weakSelf = self;
    _db.encoder = ^NSData *(LevelDBKey * key, id object){
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.cacheDecorator) {
            data = [strongSelf.cacheDecorator decoratedDataByDecoratingWithOriginalData:data];
        }
        return data;
    };
    _db.decoder = ^id(LevelDBKey *key, id data) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.cacheDecorator) {
            data = [strongSelf.cacheDecorator originalDataByRestoringWithDecoratedData:data];
        }
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    };
    
    return self;
}

- (NSData *)cachedDataWithIdentifier:(NSString *)identifier filter:(id<SFCacheFilter>)filter
{
    NSData *data = nil;
    
    NSDictionary *cacheDictioanry = [_db objectForKey:identifier];
    SFDBCache *cache = [SFDBCache DBCacheFromDictionary:cacheDictioanry];
    if ([filter isCacheValid:cache]) {
        data = [cache data];
    }
    return data;
}

- (void)storeCacheWithIdentifier:(NSString *)identifier data:(NSData *)data
{
    SFDBCache *cache = [SFDBCache new];
    cache.data = data;
    cache.identifier = identifier;
    cache.applicationIdentifier = [SFCacheUtils applicationIdentifier];
    cache.createDate = [NSDate new];
    
    [_db setObject:[cache toDictionary] forKey:identifier];
}

- (void)clearCacheWithIdentifier:(NSString *)identifier
{
    [_db removeObjectForKey:identifier];
}

- (BOOL)isCacheExistsWithIdentifier:(NSString *)identifier
{
    return [_db objectExistsForKey:identifier];
}

@end
