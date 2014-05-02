//
//  eslTests.m
//  eslTests
//
//  Created by yangzexin on 10/25/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SFDownloadManager.h"

@interface eslTests : XCTestCase

@end

@implementation eslTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    SFFileWriter *fileWriter = [[SFFileWriter alloc] initWithFilePath:@"/Users/yangzexin/Downloads/test.txt" memoryCacheSizeInMegabyte:1];
    [fileWriter prepareForWriting];
    NSString *str = @"test write append\n";
    [fileWriter appendWithData:[str dataUsingEncoding:NSUTF8StringEncoding]];
    str = @"test write append测试\n";
    [fileWriter appendWithData:[str dataUsingEncoding:NSUTF8StringEncoding]];
    str = @"test write append测试\n";
    [fileWriter appendWithData:[str dataUsingEncoding:NSUTF8StringEncoding]];
    str = @"test write append测试\n";
    [fileWriter appendWithData:[str dataUsingEncoding:NSUTF8StringEncoding]];
    str = @"test write append测试\n";
    [fileWriter appendWithData:[str dataUsingEncoding:NSUTF8StringEncoding]];
    [fileWriter closeFile];
}

@end
