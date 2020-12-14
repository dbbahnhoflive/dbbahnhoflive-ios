// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import "MBStation.h"

@class MBStationNavigationViewController;
@class MBParkingInfo;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIViewController *viewController;
@property (strong, nonatomic) MBStationNavigationViewController *navigationController;


+ (BOOL) hasGoogleMaps;
+ (BOOL) hasAppleMaps;
- (MBStation*) selectedStation;

+(void)showRoutingForParking:(MBParkingInfo *)parking fromViewController:(UIViewController*)fromViewController;
-(void)routeToName:(NSString*)name location:(CLLocationCoordinate2D)location  fromViewController:(UIViewController*)fromViewController;

-(void)openURL:(NSURL*)url;
-(BOOL)canOpenURL:(NSURL*)url;
+(AppDelegate*)appDelegate;

//Tracking
-(BOOL)needsInitialPrivacyScreen;
-(void)userFeedbackOnPrivacyScreen:(BOOL)enabledTracking;
@end

