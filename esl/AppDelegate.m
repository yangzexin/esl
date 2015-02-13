//
//  AppDelegate.m
//  esl
//
//  Created by yangzexin on 10/25/13.
//  Copyright (c) 2013 yangzexin. All rights reserved.
//

#import "AppDelegate.h"
#import "ESNewEpisodesController.h"
#import "ESLocalEpisodesController.h"
#import "EpisodesViewController.h"
#import "SFSideMenuController.h"
#import "DownloadsViewController.h"
#import "SFCompatibleTabController.h"
#import "LocalEpisodesViewController.h"
#import "MenuController.h"
#import "SettingsViewController.h"
#import "SFSwitchTabController.h"

#import "SFBlockedBarButtonItem.h"

#import "ESUIDefaults.h"
#import "ESSoundPlayContext.h"
#import "ESSharedEpisodeManager.h"

#import "UIImage+SFAddition.h"

#import "SFFoundation.h"
#import "SFiOSKit.h"
#import "SFDownloadManager.h"

#import "SFDict2Object.h"
#import "ESEpisode.h"

#import "SFURLConnectionSkipableURLDownloader.h"
#import "SFSingleThreadHandler.h"
#import "SFFileFragment.h"
#import "SFPreparedFileWriter.h"
#import "SFMultiThreadURLDownloader.h"

NSString *const ESEnableSideMenuGestureNotification = @"ESEnableSideMenuGestureNotification";
NSString *const ESDisableSideMenuGestureNotification = @"ESDisableSideMenuGestureNotification";
NSString *const ESShowSideMenuNotification = @"ESShowSideMenuNotification";

@interface AppDelegate () <SFSideMenuControllerDelegate, SFURLDownloaderDelegate, SFImageLabelDelegate, SFSwitchTabControllerDelegate, SFSkipableURLDownloaderDelegate, SFSingleThreadHandlerDelegate>

@end

@implementation AppDelegate

- (UIImage *)imageLabel:(SFImageLabel *)imageLabel imageWithName:(NSString *)imageName
{
    return [UIImage sf_imageWithColor:[UIColor redColor] size:CGSizeMake(20, 20)];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor darkGrayColor];
    [self.window makeKeyAndVisible];
    
//    ESNewEpisodesController *englishpodController = [ESNewEpisodesController new];
//    englishpodController.tabBarItem.image = [UIImage imageNamed:@"icon_local_list"];
//    englishpodController.title = @"Englishpod";
//    englishpodController.episodeManager = [ESSharedEpisodeManager englishpodEpisodeManager];
//    
//    ESNewEpisodesController *eslController = [ESNewEpisodesController new];
//    eslController.tabBarItem.image = [UIImage imageNamed:@"icon_news_list"];
//    eslController.title = @"ESL";
//    eslController.episodeManager = [ESSharedEpisodeManager eslEpisodeManager];
//    __weak typeof(eslController) weakEslController = eslController;
//    eslController.navigationItem.leftBarButtonItem = [SFBlockedBarButtonItem blockedBarButtonItemWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks eventHandler:^{
//        ESLocalEpisodesController *controller = [ESLocalEpisodesController new];
//        [weakEslController presentViewController:[ESUIDefaults navigationControllerWithRootViewController:controller] animated:YES completion:nil];
//    }];
//    
//    UITabBarController *tabController = [UITabBarController new];
//    tabController.viewControllers = @[
//                                      [ESUIDefaults navigationControllerWithRootViewController:eslController]
//                                      , [ESUIDefaults navigationControllerWithRootViewController:englishpodController]
//                                      ];
//    
//    self.window.rootViewController = tabController;
//    
//    SFCompatibleTabController *tabBarController = [SFCompatibleTabController new];
//    tabBarController.viewControllers = @[
//                                         [ESUIDefaults navigationControllerWithRootViewController:[EpisodesViewController new]]
//                                         , [ESUIDefaults navigationControllerWithRootViewController:[DownloadsViewController new]]
//                                         , [ESUIDefaults navigationControllerWithRootViewController:[SettingsViewController new]]
//                                         ];
//    
//    NSString *menuItemTitleNews = NSLocalizedString(@"News", nil);
//    NSString *menuItemTitleDownloads = NSLocalizedString(@"Downloads", nil);
//    NSString *menuItemTitleSettings = NSLocalizedString(@"Settings", nil);
//    MenuController *menuController = [MenuController controllerWithMenuItemTitles:@[
//                                                                                    menuItemTitleNews
//                                                                                    , menuItemTitleDownloads
//                                                                                    , menuItemTitleSettings
//                                                                                    ]];
//    
//    SFSideMenuController *sideMenuController = [[SFSideMenuController alloc] initWithMenuViewController:menuController contentViewController:tabBarController];
//    sideMenuController.leftPanDistance = [[UIScreen mainScreen] bounds].size.width;
//    self.window.rootViewController = sideMenuController;
//    
//    [[NSNotificationCenter defaultCenter] addObserverForName:ESEnableSideMenuGestureNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
//        sideMenuController.disableGestureShowMenu = NO;
//    }];
//    [[NSNotificationCenter defaultCenter] addObserverForName:ESDisableSideMenuGestureNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
//        sideMenuController.disableGestureShowMenu = YES;
//    }];
//    [[NSNotificationCenter defaultCenter] addObserverForName:ESShowSideMenuNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
//        [sideMenuController showMenuViewControllerAnimated:YES completion:nil];
//    }];
//    
//    @weakify(menuController);
//    [menuController setMenuItemSelectHandler:^(NSString *menuItemTitle) {
//        @strongify(menuController);
//        NSUInteger indexOfMenuItemTitle = [menuController.menuItemTitles indexOfObject:menuItemTitle];
//        if (indexOfMenuItemTitle != NSNotFound) {
//            tabBarController.selectedIndex = indexOfMenuItemTitle;
//            [sideMenuController showContentViewControllerAnimated:YES completion:nil];
//        }
//    }];
    
    self.window.rootViewController = ({
        UITabBarController *tabBarController = [[UITabBarController alloc] init];
        EpisodesViewController *episodesViewController = [EpisodesViewController new];
        episodesViewController.tabBarItem.image = [UIImage imageNamed:@"icon_news_list"];
        
        DownloadsViewController *downloadsViewController = [DownloadsViewController new];
        downloadsViewController.tabBarItem.image = [UIImage imageNamed:@"icon_local_list"];
        
        tabBarController.viewControllers = @[[ESUIDefaults navigationControllerWithRootViewController:episodesViewController]
                                             , [ESUIDefaults navigationControllerWithRootViewController:downloadsViewController]
                                             ];
        
        tabBarController;
    });
    
    return YES;
}

- (void)switchTabController:(SFSwitchTabController *)switchTabController willSwitchToIndex:(NSInteger)index
{
    NSLog(@"willSwitchToIndex:%d", index);
}

- (void)switchTabController:(SFSwitchTabController *)switchTabController didSwitchToIndex:(NSInteger)index
{
    NSLog(@"didSwitchToIndex:%d", index);
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    [[ESSoundPlayContext sharedContext] remoteControlReceivedWithEvent:event];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark - SFSideMenuControllerDelegate
- (void)sideMenuControllerMenuViewControllerDidShown:(SFSideMenuController *)sideMenuController
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)sideMenuControllerContentViewControllerDidShown:(SFSideMenuController *)sideMenuController
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

#pragma mark - SFURLDownloaderDelegate
- (void)downloaderDidStartDownloading:(id<SFURLDownloader>)downloader
{
    NSLog(@"downloaderDidStartDownloading");
}

- (void)downloader:(id<SFURLDownloader>)downloader progress:(float)progress
{
    NSLog(@"%f", progress);
}

- (void)downloaderDidFinishDownloading:(id<SFURLDownloader>)downloader filePath:(NSString *)filePath
{
    NSLog(@"downloaderDidFinishDownloading");
}

- (void)downloader:(id<SFURLDownloader>)downloader didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError");
}

- (void)skipableURLDownloader:(id<SFSkipableURLDownloader>)skipableURLDownloader didReceiveResponse:(NSURLResponse *)response contentLength:(unsigned long long)contentLength skipable:(BOOL)skipable
{
    NSLog(@"%@, %lld, %@", response, contentLength, skipable ? @"skipable" : @"not skipable");
}

- (void)skipableURLDownloader:(id<SFSkipableURLDownloader>)skipableURLDownloader didDownloadData:(NSData *)data
{
    NSLog(@"%d", data.length);
}

- (void)skipableURLDownloaderDidFinishDownloading:(id<SFSkipableURLDownloader>)skipableURLDownloader
{
}

- (void)skipableURLDownloader:(id<SFSkipableURLDownloader>)skipableURLDownloader didFailWithError:(NSError *)error
{
}

#pragma mark - SFSingleThreadHandlerDelegate
- (void)singleThreadHandler:(SFSingleThreadHandler *)singleThreadHandler didReceiveResponse:(NSURLResponse *)response contentLength:(unsigned long long)contentLength skipable:(BOOL)skipable
{
    id<SFPreparedFileWritable> fileWritable = [self sf_associatedObjectWithKey:@"fileWriter"];
    [fileWritable preparingForFileWritingWithFileSize:contentLength];
    [singleThreadHandler.fragment setContentLength:contentLength];
    NSLog(@"%@, %lld, %@", response, contentLength, skipable ? @"skipable" : @"not skipable");
}

- (void)singleThreadHandler:(SFSingleThreadHandler *)singleThreadHandler didFinishDownloadingFragment:(SFFileFragment *)fragment
{
    NSLog(@"didFinishDownloadingFragment:%@", fragment);
}

- (void)singleThreadHandler:(SFSingleThreadHandler *)singleThreadHandler didFailDownloadingFragment:(SFFileFragment *)fragment
{
    NSLog(@"didFailDownloadingFragment:%@", fragment);
}

@end
