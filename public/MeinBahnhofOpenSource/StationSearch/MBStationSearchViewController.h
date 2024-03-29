// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


//#import <UIKit/UIKit.h>

#import <CoreLocation/CoreLocation.h>

#import "MBUIViewController.h"
#import "MBStation.h"

#define SETTINGS_LAST_SEARCHES @"last_search_requests_v2"

@class MBBackNavigationState;
@class MBStationFromSearch;
@class MBRootContainerViewController;

@interface MBStationSearchViewController : MBUIViewController 

- (void) openStationAndShowFacility:(nonnull NSDictionary *)station;
- (void) openStation:(nonnull NSDictionary*)station andShowWagenstand:(nonnull NSDictionary*)wagenstandUserInfo;
- (void) openStation:(nonnull NSDictionary*)station;
-(void)openStationFromInternalLink:(nonnull MBStationFromSearch *)station withBackState:(nonnull MBBackNavigationState*)state;

-(void)freeStationAndClearBackHistory:(BOOL)clearBackHistory;

-(MBStation* _Nullable)selectedStation;
-(MBRootContainerViewController* _Nullable)stationMapController;
-(BOOL)allowBackFromStation;
-(void)goBackToPreviousStation;


+(void)displayDataProtectionOn:(nonnull UIViewController*)vc;

@property(nonatomic,strong) MBBackNavigationState* _Nullable trainJourneyToRestore;
@property(nonatomic) BOOL onBoardingVisible;
@property(nonatomic) BOOL privacySetupVisible;
@end
