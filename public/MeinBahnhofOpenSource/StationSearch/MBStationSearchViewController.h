// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


//#import <UIKit/UIKit.h>

#import <CoreLocation/CoreLocation.h>

#import "MBUIViewController.h"
#import "MBStation.h"

#define SETTINGS_LAST_SEARCHES @"last_search_requests_v2"

@class MBRootContainerViewController;

@interface MBStationSearchViewController : MBUIViewController 

@property (nonatomic, strong) MBStation* _Nullable selectedStation;
@property (nonatomic, strong) MBRootContainerViewController* _Nullable stationMapController;

- (void) openStationAndShowFacility:(nonnull NSDictionary *)station;
- (void) openStation:(nonnull NSDictionary*)station andShowWagenstand:(nonnull NSDictionary*)wagenstandUserInfo;
- (void) openStation:(nonnull NSDictionary*)station;
-(void)freeStation;

@property(nonatomic) BOOL onBoardingVisible;
@property(nonatomic) BOOL privacySetupVisible;
@end
