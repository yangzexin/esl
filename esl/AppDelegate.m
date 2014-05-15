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

#import "SFBlockedBarButtonItem.h"

#import "ESUIDefaults.h"
#import "ESSoundPlayContext.h"
#import "ESSharedEpisodeManager.h"

#import "UIImage+SFAddition.h"
#import <RESideMenu/RESideMenu.h>

#import "SFFoundation.h"
#import "SFiOSKit.h"
#import "SFDownloadManager.h"

NSString *const ESEnableSideMenuGestureNotification = @"ESEnableSideMenuGestureNotification";
NSString *const ESDisableSideMenuGestureNotification = @"ESDisableSideMenuGestureNotification";
NSString *const ESShowSideMenuNotification = @"ESShowSideMenuNotification";

@interface AppDelegate () <SFSideMenuControllerDelegate, SFURLDownloaderDelegate, SFImageLabelDelegate>

@end

@implementation AppDelegate

- (UIImage *)imageLabel:(SFImageLabel *)imageLabel imageWithName:(NSString *)imageName
{
    return [UIImage imageWithColor:[UIColor redColor] size:CGSizeMake(20, 20)];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor blackColor];
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
    
    
    SFCompatibleTabController *tabBarController = [SFCompatibleTabController new];
    tabBarController.viewControllers = @[
                                         [ESUIDefaults navigationControllerWithRootViewController:[EpisodesViewController new]]
//                                         , [ESUIDefaults navigationControllerWithRootViewController:[LocalEpisodesViewController new]]
                                         , [ESUIDefaults navigationControllerWithRootViewController:[DownloadsViewController new]]
                                         , [ESUIDefaults navigationControllerWithRootViewController:[SettingsViewController new]]
                                         ];
    
    NSString *menuItemTitleNews = NSLocalizedString(@"News", nil);
//    NSString *menuItemTitleLocal = NSLocalizedString(@"Local", nil);
    NSString *menuItemTitleDownloads = NSLocalizedString(@"Downloads", nil);
    NSString *menuItemTitleSettings = NSLocalizedString(@"Settings", nil);
    MenuController *menuController = [MenuController controllerWithMenuItemTitles:@[
                                                                                    menuItemTitleNews
//                                                                                    , menuItemTitleLocal
                                                                                    , menuItemTitleDownloads
                                                                                    , menuItemTitleSettings
                                                                                    ]];
    
    RESideMenu *sideMenu = [[RESideMenu alloc] initWithContentViewController:tabBarController leftMenuViewController:menuController rightMenuViewController:nil];
    sideMenu.contentViewShadowRadius = 5;
    sideMenu.contentViewShadowColor = [UIColor blackColor];
    sideMenu.contentViewShadowEnabled = YES;
    sideMenu.panFromEdge = NO;
    self.window.rootViewController = sideMenu;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:ESEnableSideMenuGestureNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        sideMenu.panGestureEnabled = YES;
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:ESDisableSideMenuGestureNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        sideMenu.panGestureEnabled = NO;
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:ESShowSideMenuNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [sideMenu presentLeftMenuViewController];
    }];
    
    @weakify(menuController);
    [menuController setMenuItemSelectHandler:^(NSString *menuItemTitle) {
        @strongify(menuController);
        NSUInteger indexOfMenuItemTitle = [menuController.menuItemTitles indexOfObject:menuItemTitle];
        if (indexOfMenuItemTitle != NSNotFound) {
            tabBarController.selectedIndex = indexOfMenuItemTitle;
            [sideMenu hideMenuViewController];
        }
    }];
    
    return YES;
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

#pragma mark - test
- (void)downloaderDidStartDownloading:(SFURLDownloader *)downloader
{
    NSLog(@"downloaderDidStartDownloading");
}

- (void)downloader:(SFURLDownloader *)downloader progress:(float)progress
{
    NSLog(@"%f", progress);
}

- (void)downloaderDidFinishDownloading:(SFURLDownloader *)downloader filePath:(NSString *)filePath
{
    NSLog(@"downloaderDidFinishDownloading");
}

- (void)downloader:(SFURLDownloader *)downloader didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError");
}

@end
