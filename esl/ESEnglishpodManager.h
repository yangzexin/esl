//
//  ESEnglishpodManager.h
//  esl
//
//  Created by yangzexin on 11/6/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESEpisodeManager.h"

@interface ESEnglishpodManager : NSObject <ESEpisodeManager>

@property (nonatomic, copy) NSString *(^lyricsWrapper)(NSString *lyrics);

@end
