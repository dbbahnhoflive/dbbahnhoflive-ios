// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "AppDelegate.h"
#import "MBUIHelper.h"
#import "MBTrackingManager.h"

#import "FacilityStatusManager.h"

#import "MBStationNavigationViewController.h"

#import "MBStationSearchViewController.h"

#import "TimetableManager.h"

#import "MBGPSLocationManager.h"

#import "SharedMobilityAPI.h"
#import "MBMapInternals.h"

#import "MBStationNavigationViewController.h"
#import "MBTrainPositionViewController.h"
#import "MBParkingInfo.h"
#import "MBOSMOpeningHoursParser.h"

#import "Constants.h"
#import "MBCacheManager.h"

@import UserNotifications;
@import Sentry;

@interface AppDelegate ()<UNUserNotificationCenterDelegate>
@property(nonatomic) BOOL hasHadBeenActive;
@end

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
    
    
    NSString* currentBuildNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString* lastBuildNumber = [NSUserDefaults.standardUserDefaults stringForKey:@"LastCFBundleVersion"];
    if(lastBuildNumber && ![lastBuildNumber isEqualToString:currentBuildNumber]){
        //build number changed, disable rimaps debug feature
        [NSUserDefaults.standardUserDefaults setBool:false forKey:@"RiMapUseProviderSetting"];
    }
    [NSUserDefaults.standardUserDefaults setObject:currentBuildNumber forKey:@"LastCFBundleVersion"];

#ifdef DEBUG
    NSLog(@"Sentry: no crash reporting on debug builds");
#else
    NSString *sentryDNS = [Constants kSentryDNS];
    if(sentryDNS){
        NSLog(@"starting sentry %@",sentryDNS);
        [SentrySDK startWithConfigureOptions:^(SentryOptions *options) {
            options.dsn = sentryDNS;
            options.sendClientReports = false;
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


    CGRect mainScreenBounds = [[UIScreen mainScreen] bounds];

    self.window = [[UIWindow alloc] initWithFrame:mainScreenBounds];
    self.viewController = [[MBStationSearchViewController alloc] initWithNibName:nil bundle:nil];
    self.navigationController = [[MBStationNavigationViewController alloc] initWithRootViewController:self.viewController];

    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    
    UNUserNotificationCenter* notificationCenter = UNUserNotificationCenter.currentNotificationCenter;
    notificationCenter.delegate = self;
    
    [MBOSMOpeningHoursParser sharedInstance];
   
    return YES;
}

-(BOOL)trackingEnabled{
    return [NSUserDefaults.standardUserDefaults boolForKey:@"enabled_tracking"];
}
-(BOOL)needsInitialPrivacyScreen{
    //return true;
    return ![NSUserDefaults.standardUserDefaults boolForKey:@"got_tracking_decisison"];
}
-(void)userFeedbackOnPrivacyScreen:(BOOL)enabledTracking{
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"got_tracking_decisison"];
    [NSUserDefaults.standardUserDefaults setBool:enabledTracking forKey:@"enabled_tracking"];
    [MBTrackingManager setOptOut:!self.trackingEnabled];
}

- (MBStation*) selectedStation
{
    MBStationSearchViewController* vc = (MBStationSearchViewController*) self.viewController;
    return vc.selectedStation;
}

+(AppDelegate *)appDelegate{
    return (AppDelegate*) [UIApplication sharedApplication].delegate;
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
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[TimetableManager sharedManager] startTimetableScheduler];
    
    if([NSUserDefaults.standardUserDefaults boolForKey:@"DeleteCache"]){
        [[MBCacheManager sharedManager] deleteCache];
        [NSUserDefaults.standardUserDefaults removeObjectForKey:@"DeleteCache"];
    }
    
    if(self.hasHadBeenActive){
        [MBTrackingManager setOptOut:!self.trackingEnabled];
    } else {
        //we ignore the initial applicationDidBecomeActive for optout settings, its already configured by didFinishLaunchingWithOptions
        self.hasHadBeenActive = YES;
    }

}

- (void) handleLocalNotification:(NSDictionary*)userInfo
{
    // NSLog(@"handleLocalNotification: %@",notification);
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
    } else if(userInfo[@"properties"]){
        //handle code for facility manager (when merged from facility branch!)
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
            // NSLog(@"Local Notification received by running app - ignore");
        } else {
            //NSLog(@"App opened from Notification, now should go to station %@",notification.userInfo[@"properties"]);
            [[FacilityStatusManager client] openFacilityStatusWithLocalNotification:userInfo];
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
        [vc showWagenstandForUserInfo:userInfo];
    } else {
        // NSLog(@"must open another station OR did display search controller!");
        [self.navigationController popToRootViewControllerAnimated:NO];
        MBStationSearchViewController* vc = (MBStationSearchViewController*) self.viewController;
        [vc openStation:@{ @"title":stationTitle, @"id": [NSNumber numberWithLongLong:[stationNumber longLongValue]] } andShowWagenstand:userInfo];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.

    // clean cached pdfs when app is terminated
    [self clearCachedFiles];
    

    [[MBGPSLocationManager sharedManager] stopAllUpdates];
}

- (void)application:(UIApplication *)application didChangeStatusBarFrame:(CGRect)oldStatusBarFrame
{
    //
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

- (void) clearCachedFiles
{
    NSArray *myPathList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *mainPath  = myPathList[0];

    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSArray *fileArray = [fileMgr contentsOfDirectoryAtPath:mainPath error:nil];

    [fileArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]] && ([obj rangeOfString:@".pdf"].length != 0)) {
            [fileMgr removeItemAtPath:[mainPath stringByAppendingPathComponent:obj] error:NULL];
        }
    }];
}


@end
