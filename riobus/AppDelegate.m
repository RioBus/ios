#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import <Google/Analytics.h>
#import <GoogleMaps/GoogleMaps.h>
#import <Parse/Parse.h>
#import "AppDelegate.h"

#ifdef DEBUG
#import <SimulatorStatusMagic/SDStatusBarManager.h>
#endif

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Configure Google Maps
    [GMSServices provideAPIKey:@"AIzaSyAOXbZQbs0_scRqMWj83eDc8snV54yfF5I"];
    
    // Configure AFNetworking
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    // Configure Parse
    [Parse setApplicationId:@"MiNwvb2H3O1nTiZQLdVsIj8px5JWfCN1gITg1vIK"
                  clientKey:@"aJZh3mH9u9Baik8pE1vIfkbQwYA2V8E24oIinRy5"];
    
    // Configure Google Analytics
    NSError *configureError;
    [[GGLContext sharedInstance] configureWithError:&configureError];
    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);
    GAI *gai = [GAI sharedInstance];
    gai.trackUncaughtExceptions = YES; // Report uncaught exceptions
#ifdef DEBUG
    gai.logger.logLevel = kGAILogLevelWarning;
    gai.dryRun = YES; // Prevents any data from being sent to Google Analytics
    NSLog(@"Google Analytics running in Dry Run mode. Data will not be sent to Analytics.");
    [[SDStatusBarManager sharedInstance] enableOverrides];
#endif
    
#ifdef SNAPSHOT
    // If the app is running on Snapshot mode, clear previous Simulator preferences and load static preferences set
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    [[NSUserDefaults standardUserDefaults] setObject:@[@"555",@"475",@"636"] forKey:@"Recents"];
    [[NSUserDefaults standardUserDefaults] setObject:@"348" forKey:@"favorite_line"];
    NSLog(@"App on screenshot mode. User defaults have been reset.");
#endif
    
    // Register for Push Notifications
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationType userNotificationTypes = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    }
    else {
        UIRemoteNotificationType userNotificationTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
        [application registerForRemoteNotificationTypes:userNotificationTypes];
    }
    
    application.applicationIconBadgeNumber = 0;
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
