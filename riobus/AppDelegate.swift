import Alamofire
import GoogleMaps
import Parse
import UIKit
import SimulatorStatusMagic

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private static let reachabilityManager = NetworkReachabilityManager()
    static var isConnectedToNetwork: Bool {
        get {
            if let reachable = reachabilityManager?.isReachable {
                return reachable
            }
            return false
        }
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Configure Google Maps
        GMSServices.provideAPIKey("AIzaSyAOXbZQbs0_scRqMWj83eDc8snV54yfF5I")
        
        // Configure networking
        AppDelegate.reachabilityManager?.startListening()
        
        // Configure Parse
        Parse.setApplicationId("MiNwvb2H3O1nTiZQLdVsIj8px5JWfCN1gITg1vIK", clientKey: "aJZh3mH9u9Baik8pE1vIfkbQwYA2V8E24oIinRy5")
        
        // Configure Google Analytics
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        let gai = GAI.sharedInstance()
        gai.trackUncaughtExceptions = true
        #if DEBUG
            gai.logger.logLevel = .Warning
            gai.dryRun = true
            print("Google Analytics running in Dry Run mode. Data will not be sent to Analytics.")
        #else
            gai.logger.logLevel = .None
        #endif
        
        // If the app is running on Snapshot mode, clear previous Simulator preferences and load static preferences set
        #if SNAPSHOT
            let preferences = PreferencesStore.sharedInstance
            preferences.clearPreferences()
            preferences.recentSearches = ["555", "475", "636", "348"]
            preferences.favoriteLine = "348"
            print("App on screenshot mode. User defaults have been reset.")
        #endif
        
        #if DEBUG
            SDStatusBarManager.sharedInstance().enableOverrides()
        #endif
        
        // Register for Push Notifications
        let userNotificationSettings = UIUserNotificationSettings(forTypes: [UIUserNotificationType.Sound, UIUserNotificationType.Alert, UIUserNotificationType.Badge], categories: nil)
        application.registerUserNotificationSettings(userNotificationSettings)
        application.registerForRemoteNotifications()
        application.applicationIconBadgeNumber = 0
        
        // Clear legacy caches
        ItineraryCache.clearLegacyCacheIfNecessary()
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        application.applicationIconBadgeNumber = 0
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        application.applicationIconBadgeNumber = 0
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        PFPush.handlePush(userInfo)
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        
        let currentInstallation = PFInstallation.currentInstallation()
        currentInstallation.setDeviceTokenFromData(deviceToken)
        currentInstallation.saveInBackground()
    }
}