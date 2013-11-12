//
//  ESEnglishpodManager.m
//  esl
//
//  Created by yangzexin on 11/6/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "ESEnglishpodManager.h"
#import "ESRequestProxyWrapper.h"
#import "ESServiceSession.h"
#import "ESEpisode.h"
#import <AVFoundation/AVFoundation.h>

@implementation ESEnglishpodManager

- (BOOL)isEpisodeDownloaded:(ESEpisode *)episode
{
    return [[NSFileManager defaultManager] fileExistsAtPath:episode.soundURLString];
}

- (id<ESService>)soundPathWithEpisode:(ESEpisode *)episode
{
    ESRequestProxyWrapper *wrapper = [ESRequestProxyWrapper wrapperWithResultGetter:^id(NSDictionary *parameters) {
        return episode.soundURLString;
    }];
    
    return [ESServiceSession sessionWithRequestProxy:wrapper];
}

- (id<ESService>)episodes
{
    ESRequestProxyWrapper *wrapper = [ESRequestProxyWrapper wrapperWithResultGetter:^id(NSDictionary *parameters) {
        NSMutableArray *episodes = [NSMutableArray array];
        NSString *documentPath = [NSString stringWithFormat:@"%@/Documents", NSHomeDirectory()];
        NSArray *documentFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentPath error:nil];
        
        NSMutableDictionary *keyEpisodeUidValueSoundPath = [NSMutableDictionary dictionary];
        for (NSString *fileName in documentFiles) {
            if ([[fileName lowercaseString] hasSuffix:@".mp3"]) {
                NSMutableString *string = [NSMutableString string];
                NSString *fileNameWithoutExtension = [fileName stringByDeletingPathExtension];
                for (NSInteger i = 0; i < fileNameWithoutExtension.length; ++i) {
                    unichar ch = [fileNameWithoutExtension characterAtIndex:i];
                    if (ch >= 48 && ch <= 57) {
                        [string appendFormat:@"%c", ch];
                    }
                }
                
                NSString *uid = string;
                NSString *soudFilePath = [documentPath stringByAppendingPathComponent:fileName];
                BOOL isDir = NO;
                [[NSFileManager defaultManager] fileExistsAtPath:soudFilePath isDirectory:&isDir];
                if (isDir == NO) {
                    [keyEpisodeUidValueSoundPath setObject:soudFilePath forKey:uid];
                }
            }
        }
        
        NSMutableArray *allUids = [NSMutableArray arrayWithArray:[keyEpisodeUidValueSoundPath allKeys]];
        [allUids sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
            return obj1.integerValue > obj2.integerValue ? NSOrderedDescending : NSOrderedAscending;
        }];
        
        for (NSString *uid in allUids) {
            @autoreleasepool {
                NSString *soundPath = [keyEpisodeUidValueSoundPath objectForKey:uid];
                
                NSString *soundTitle = nil;
                NSString *trackNo = nil;
                NSString *year = nil;
                NSString *lyrics = nil;
                
                AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:soundPath] options:nil];
                lyrics = asset.lyrics;
                NSArray *metadata = asset.commonMetadata;
                for (AVMetadataItem *item in metadata) {
                    if ([item.commonKey isEqualToString:@"title"]) {
                        soundTitle = item.stringValue;
                    } else if ([item.commonKey isEqualToString:@"creator"]) {
                        year = item.stringValue;
                    }
                }
                
                if (soundTitle.length == 0) {
                    soundTitle = [soundPath lastPathComponent];
                }
                if (trackNo.length == 0) {
                    trackNo = [NSString stringWithFormat:@"E%d", [uid integerValue]];
                }
                if (year.length == 0) {
                    year = @"";
                }
                if (lyrics.length == 0) {
                    lyrics = @"";
                }
                ESEpisode *episode = [ESEpisode new];
                episode.uid = uid;
                episode.soundURLString = soundPath;
                episode.title = soundTitle;
                episode.date = [NSString stringWithFormat:@"%@ - %@", trackNo, year];
                NSString *(^lyricsWrapper)(NSString *) = self.lyricsWrapper;
                if (lyricsWrapper == nil) {
                    lyricsWrapper = _defaultHTMLLyricsWrapper;
                }
                episode.introdution = lyrics;
                lyrics = lyricsWrapper(lyrics);
                episode.formattedIntrodution = lyrics;
                [episodes addObject:episode];
            }
        }
        
        return episodes;
    }];
    return [ESServiceSession sessionWithRequestProxy:wrapper];
}

- (id<ESService>)newestEpisodes
{
    return [self episodes];
}

- (id<ESService>)soundPathWithEpisode:(ESEpisode *)episode progressTracker:(id<ESProgressTracker>)progressTracker
{
    return [self soundPathWithEpisode:episode];
}

NSString *(^_defaultHTMLLyricsWrapper)(NSString *lyrics) = ^NSString *(NSString *lyrics){
    NSString *HTMLString = [NSString stringWithFormat:@"<html><head>$header</head><body style=\"$bodyStyle\">$content</body></html>"];
    lyrics = [lyrics stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
    HTMLString = [HTMLString stringByReplacingOccurrencesOfString:@"$content" withString:lyrics];
    HTMLString = [HTMLString stringByReplacingOccurrencesOfString:@"$header"
                                                       withString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" /><meta name=\"viewport\" content=\"width=device-width,minimum-scale=1.0,maximum-scale=1.0\"/>"];
    HTMLString = [HTMLString stringByReplacingOccurrencesOfString:@"$bodyStyle" withString:@"padding-bottom:20px;font-family:Verdana;padding-top:10px;"];
    return HTMLString;
};

@end
