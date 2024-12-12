// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBStation.h"

@class MBStationNavigationViewController;
@class MBParkingInfo;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIViewController *viewController;
@property (strong, nonatomic) MBStationNavigationViewController *navigationController;

- (MBStation*) selectedStation;

+(AppDelegate*)appDelegate;

-(BOOL)hasEnabledPushServices;
-(NSString*)previousAppVersion;
-(BOOL)appDisabled;

//Tracking
-(BOOL)needsInitialPrivacyScreen;
-(void)userFeedbackOnPrivacyScreen:(BOOL)enabledTracking;

+(CGFloat)statusBarHeight;
+(CGFloat)screenHeight;
+(double)SCALEFACTORFORSCREEN;
@end

