//
//  SFURLConnectionSkipableURLDownloader.m
//  esl
//
//  Created by yangzexin on 11/10/14.
//  Copyright (c) 2014 yangzexin. All rights reserved.
//

#import "SFURLConnectionSkipableURLDownloader.h"

@interface SFURLConnectionSkipableURLDownloader ()

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, assign) unsigned long long offset;
@property (nonatomic, assign) unsigned long long contentLength;

@end

@implementation SFURLConnectionSkipableURLDownloader

@synthesize delegate;

- (void)startWithURLString:(NSString *)URLString offset:(unsigned long long)offset
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    if (offset != 0) {
        [request setValue:[NSString stringWithFormat:@"bytes=%llu-", self.offset] forHTTPHeaderField:@"Range"];
    }
    
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

- (void)cancel
{
    [self.connection cancel];
}

- (BOOL)_isSkipedBytesEqualsDownloadBytesWithHeaders:(NSDictionary *)headers
{
    BOOL equals = NO;
    
    NSString *contentRange = [headers objectForKey:@"Content-Range"];
    NSString *AcceptRanges = [headers objectForKey:@"Accept-Ranges"];
    
    if (AcceptRanges) {
        if (self.offset == 0) {
            equals = ![[AcceptRanges uppercaseString] isEqualToString:@"NONE"];
        } else {
            contentRange = [contentRange stringByReplacingOccurrencesOfString:AcceptRanges withString:@""];
            contentRange = [contentRange stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSArray *attrs = [contentRange componentsSeparatedByString:@"-"];
            if (attrs.count != 0) {
                unsigned long long skipedBytes = [[attrs objectAtIndex:0] longLongValue];
                equals = skipedBytes == self.offset;
            }
        }
    }
    
    return equals;
}

#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
    self.contentLength = [[headers objectForKey:@"Content-Length"] longLongValue] + self.offset;
    [self.delegate skipableURLDownloader:self didReceiveResponse:response
                           contentLength:self.contentLength
                                skipable:[self _isSkipedBytesEqualsDownloadBytesWithHeaders:[(NSHTTPURLResponse *)response allHeaderFields]]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.delegate skipableURLDownloader:self didDownloadData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self.delegate skipableURLDownloaderDidFinishDownloading:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.delegate skipableURLDownloader:self didFailWithError:error];
}

@end
