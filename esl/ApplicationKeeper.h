//
//  ApplicationKeeper.h
//  imyvoa
//
//  Created by yangzexin on 9/28/12.
//
//

#import <Foundation/Foundation.h>

@interface ApplicationKeeper : NSObject

+ (id)sharedInstance;
- (void)keep;
- (void)stop;

@end
