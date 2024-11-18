// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "AppDelegate.h"
#import <GoogleMaps/GoogleMaps.h>

#import "MBUIHelper.h"
#import "MBTrackingManager.h"

#import "FacilityStatusManager.h"

#import "MBStationNavigationViewController.h"
#import "MBRootContainerViewController.h"
#import "MBStationSearchViewController.h"

#import "TimetableManager.h"

#import "MBGPSLocationManager.h"

#import "MBMapInternals.h"

#import "MBStationNavigationViewController.h"
#import "MBTrainPositionViewController.h"
#import "MBParkingInfo.h"
#import "MBOSMOpeningHoursParser.h"

#import "Constants.h"
#import "MBCacheManager.h"

@import UserNotifications;
@import Sentry;
@import Firebase;

@interface AppDelegate ()<UNUserNotificationCenterDelegate>
@property(nonatomic) BOOL hasHadBeenActive;

@property(nonatomic) BOOL hasEnabledPushServices;

@end

//note that these settings are also defined in the Root.plist in Settings
#define SETTING_ENABLED_TRACKING @"enabled_tracking"
#define SETTING_DELETE_CACHE @"DeleteCache"

#define SETTING_GOT_TRACKING_DECISION @"got_tracking_decisison"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    // Override point for customization after application launch.
    // NSLog(@"didFinishLaunching with %@",launchOptions);
    [Constants setup];

    [self registerDefaultsFromSettingsBundle];

    // Setup app-wide shared cache
    NSUInteger capacity = 20 * 1024 * 1024;
    NSURLCache *cache = [[NSURLCache alloc] initWithMemoryCapacity:capacity diskCapacity:capacity diskPath:nil];
    [NSURLCache setSharedURLCache:cache];
    
    NSString *appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    //NSString* previousStoredAppVersionString = [self previousAppVersion];
    NSString* currentStoredAppVersionString = [NSUserDefaults.standardUserDefaults stringForKey:@"CurrentCFBundleShortVersionString"];

    NSString* currentBuildNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString* lastBuildNumber = [NSUserDefaults.standardUserDefaults stringForKey:@"LastCFBundleVersion"];
    if(lastBuildNumber && ![lastBuildNumber isEqualToString:currentBuildNumber]){
        //build number changed, disable rimaps debug feature
        [NSUserDefaults.standardUserDefaults setBool:false forKey:@"RiMapUseProviderSetting"];
    }
    
    if(currentStoredAppVersionString == nil){
        //user had a version installed which did not yet store the version number
        // OR this is a new install
        if(lastBuildNumber){
            //this is an update, but we don't know the previous version, just set 0.0.0
            [NSUserDefaults.standardUserDefaults setObject:@"0.0.0" forKey:@"PreviousCFBundleShortVersionString"];
        } else {
            //this is a new install, don't set the previous value! It will be set on the fist update
        }
    } else {
        if(![currentStoredAppVersionString isEqualToString:appVersionString]){
            //the app version has changed, store the old "current" as previous
            [NSUserDefaults.standardUserDefaults setObject:currentStoredAppVersionString forKey:@"PreviousCFBundleShortVersionString"];
        }
    }
    [NSUserDefaults.standardUserDefaults setObject:appVersionString forKey:@"CurrentCFBundleShortVersionString"];
    
    [NSUserDefaults.standardUserDefaults setObject:currentBuildNumber forKey:@"LastCFBundleVersion"];
    //NSLog(@"stored: CurrentCFBundleShortVersionString=%@",appVersionString);
    //NSLog(@"stored: PreviousCFBundleShortVersionString=%@",self.previousAppVersion);

#ifdef DEBUG
    NSLog(@"Sentry: no crash reporting on debug builds");
#else
    NSString *sentryDNS = [Constants kSentryDNS];
    if(sentryDNS){
        NSLog(@"starting sentry %@",sentryDNS);
        [SentrySDK startWithConfigureOptions:^(SentryOptions *options) {
            options.dsn = sentryDNS;
            options.sendClientReports = false;
            options.enableCaptureFailedRequests = false;
            options.appHangTimeoutInterval = 3;
            options.enableCaptureFailedRequests = false;
            //options.debug = @YES;
            //options.logLevel = kSentryLogLevelVerbose;
        }];
    }
#endif
    
    if (@available(iOS 15.0, *))
    {
        //configure system UI back to pre-ios15 state
        UITableView.appearance.sectionHeaderTopPadding = 0;
        
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.titleTextAttributes = @{NSForegroundColorAttributeName : UIColor.db_333333};
        appearance.backgroundColor = UIColor.whiteColor;
        [UINavigationBar appearance].standardAppearance = appearance;
        [UINavigationBar appearance].scrollEdgeAppearance = appearance;
    }
    
    [MBTrackingManager setupWithOptOut:!self.trackingEnabled];


    // initialize Google Maps
    [GMSServices setAbnormalTerminationReportingEnabled:NO];
    [GMSServices provideAPIKey:[MBMapInternals kGoogleMapsApiKey]];

    if(Constants.usePushServices){
        //firebase setup
        [FIRApp configure];
        NSLog(@"Firebase Token: %@",FIRMessaging.messaging.FCMToken);
    }
    
    CGRect mainScreenBounds = [[UIScreen mainScreen] bounds];

    self.window = [[UIWindow alloc] initWithFrame:mainScreenBounds];
    self.viewController = [[MBStationSearchViewController alloc] initWithNibName:nil bundle:nil];
    self.navigationController = [[MBStationNavigationViewController alloc] initWithRootViewController:self.viewController];

    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    
    UNUserNotificationCenter* notificationCenter = UNUserNotificationCenter.currentNotificationCenter;
    notificationCenter.delegate = self;
    
    [MBOSMOpeningHoursParser sharedInstance];
    
    if(Constants.usePushServices){
        [self registerRemoteNotif:application];
    }
    
    return YES;
}

-(NSString*)previousAppVersion{
    return [NSUserDefaults.standardUserDefaults stringForKey:@"PreviousCFBundleShortVersionString"];
}


-(BOOL)trackingEnabled{
    return [NSUserDefaults.standardUserDefaults boolForKey:SETTING_ENABLED_TRACKING];
}
-(BOOL)needsInitialPrivacyScreen{
    //return true;
    return ![NSUserDefaults.standardUserDefaults boolForKey:SETTING_GOT_TRACKING_DECISION];
}
-(void)userFeedbackOnPrivacyScreen:(BOOL)enabledTracking{
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:SETTING_GOT_TRACKING_DECISION];
    [NSUserDefaults.standardUserDefaults setBool:enabledTracking forKey:SETTING_ENABLED_TRACKING];
    [MBTrackingManager setOptOut:!self.trackingEnabled];
}

- (MBStation*) selectedStation
{
    MBStationSearchViewController* vc = (MBStationSearchViewController*) self.viewController;
    return vc.selectedStation;
}

+(CGFloat)screenHeight{
    return [AppDelegate appDelegate].window.frame.size.height;
}
+(CGFloat)statusBarHeight{
    CGFloat res =
    [AppDelegate appDelegate].window.windowScene.statusBarManager.statusBarFrame.size.height; //UIApplication.sharedApplication.statusBarFrame.size.height;
    if(res == 0){
        res = 20;
    }
    return res;
}
+(double)SCALEFACTORFORSCREEN{
    return (self.screenHeight <= 568) ? 568./667. : 1. ;
}

+(AppDelegate *)appDelegate{
    return (AppDelegate*) [UIApplication sharedApplication].delegate;
}

-(void)registerRemoteNotif:(UIApplication*)application{
    UNAuthorizationOptions authOptions = UNAuthorizationOptionAlert |
        UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
    [UNUserNotificationCenter.currentNotificationCenter
        requestAuthorizationWithOptions:authOptions
        completionHandler:^(BOOL granted, NSError * _Nullable error) {
          // ...
        self.hasEnabledPushServices = granted;
    }];
    [application registerForRemoteNotifications];
}

-(void)checkRemoteNotificationAccess{
    [UNUserNotificationCenter.currentNotificationCenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        switch(settings.authorizationStatus){
            case UNAuthorizationStatusAuthorized:
                self.hasEnabledPushServices = true;
                break;
            default:
                self.hasEnabledPushServices = false;
                break;
        }
    }];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
    fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  // If you are receiving a notification message while your app is in the background,
  // this callback will not be fired till the user taps on the notification launching the application.

  // With swizzling disabled you must let Messaging know about the message, for Analytics
  // [[FIRMessaging messaging] appDidReceiveMessage:userInfo];

  // Print full message.
  NSLog(@"didReceiveRemoteNotification: %@", userInfo);
    [FacilityStatusManager.client handleRemoteNotification:userInfo];
//    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Push" message:userInfo.description preferredStyle:UIAlertControllerStyleAlert];
//    [alert addAction:[UIAlertAction actionWithTitle:@"close" style:UIAlertActionStyleCancel handler:nil]];
//    [self.navigationController.topViewController presentViewController:alert animated:YES completion:nil];
    
    completionHandler(UIBackgroundFetchResultNewData);
}




-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler{
    NSLog(@"didreceive some notif, %@",response);
    
    if ([response.actionIdentifier isEqualToString:UNNotificationDefaultActionIdentifier]) {
        // The user launched the app.
        NSLog(@"user launched app");
        
        [self handleLocalNotification:response.notification.request.content.userInfo];
    }

    completionHandler();
}
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler{
    NSLog(@"userNotificationCenter:willPresentNotification");
    [self handleLocalNotification:notification.request.content.userInfo];
    completionHandler(UNNotificationPresentationOptionNone);
}



- (void) applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[TimetableManager sharedManager] stopTimetableScheduler];
    
    [[MBGPSLocationManager sharedManager] stopAllUpdates];
    

}


- (void) applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void) applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"applicationDidBecomeActive");
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[TimetableManager sharedManager] startTimetableScheduler];
    
    if([NSUserDefaults.standardUserDefaults boolForKey:SETTING_DELETE_CACHE]){
        [[MBCacheManager sharedManager] deleteCache];
        [NSUserDefaults.standardUserDefaults removeObjectForKey:SETTING_DELETE_CACHE];
    }
    
    [self checkRemoteNotificationAccess];
    
    if(self.hasHadBeenActive){
        [MBTrackingManager setOptOut:!self.trackingEnabled];
    } else {
        //we ignore the initial applicationDidBecomeActive for optout settings, its already configured by didFinishLaunchingWithOptions
        self.hasHadBeenActive = YES;
    }

}

- (void) handleLocalNotification:(NSDictionary*)userInfo
{
    NSLog(@"handleLocalNotification: %@",userInfo);
    if([userInfo[@"type"] isEqualToString:@"wagenstand"]){
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
            //app running, display alert
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Wagenreihung" message:userInfo[@"body"] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Schließen" style:UIAlertActionStyleCancel handler:nil];
            [alert addAction:defaultAction];
            defaultAction = [UIAlertAction actionWithTitle:@"Öffnen" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self openWagenstandWithUserInfo:userInfo];
            }];
            [alert addAction:defaultAction];
            [self.navigationController presentViewController:alert animated:YES completion:nil];
             
        } else {
            //should open station and display wagenstand for this train
            [self openWagenstandWithUserInfo:userInfo];
        }
    } else if(userInfo[@"facilityEquipmentNumber"]){
        //user received a notification for facility
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
            // NSLog(@"Push Notification received by running app, display alert");
            [FacilityStatusManager.client handleRemoteNotification:userInfo];
        } else {
            //NSLog(@"App opened from Notification, now should go to station %@",notification.userInfo[@"properties"]);
            [FacilityStatusManager.client openFacilityStatusWithLocalNotification:userInfo];
        }
    } else {
        NSLog(@"unknown type in userinfo %@",userInfo);
    }
}

- (void) openWagenstandWithUserInfo:(NSDictionary*)userInfo
{
    // NSLog(@"now open this wagenstand %@",userInfo);
    NSNumber* stationNumber = userInfo[@"stationNumber"];
    NSString* stationTitle = userInfo[@"stationName"];

    if([self.selectedStation.mbId longLongValue] == [stationNumber longLongValue]
       && ![self.navigationController.topViewController isKindOfClass:[MBStationSearchViewController class]]){
        //we already are in this station
        MBStationSearchViewController* vc = (MBStationSearchViewController*) self.viewController;
        // NSLog(@"we are in this station!");
        [MBTrainPositionViewController showWagenstandForUserInfo:userInfo fromViewController:vc];
    } else {
        // NSLog(@"must open another station OR did display search controller!");
        [MBRootContainerViewController.currentlyVisibleInstance goBackToSearchAnimated:false];
        MBStationSearchViewController* vc = (MBStationSearchViewController*) self.viewController;
        [vc openStation:@{ @"title":stationTitle, @"id": [NSNumber numberWithLongLong:[stationNumber longLongValue]] } andShowWagenstand:userInfo];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.

    [[MBGPSLocationManager sharedManager] stopAllUpdates];
}




- (void) registerDefaultsFromSettingsBundle
{
    NSUserDefaults *defs = NSUserDefaults.standardUserDefaults;

    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];

    if(!settingsBundle) {
        return;
    }

    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];

    for (NSDictionary *prefSpecification in preferences) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if (key) {
            // Check if value is registered or not in userDefaults
            id currentObject = [defs objectForKey:key];
            if (currentObject == nil) {
                // Not registered: set value from Settings.bundle
                id objectToSet = [prefSpecification objectForKey:@"DefaultValue"];
                [defaultsToRegister setObject:objectToSet forKey:key];
            }
        }
    }

    [defs registerDefaults:defaultsToRegister];
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    return ISIPAD ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskAllButUpsideDown;
}



@end
