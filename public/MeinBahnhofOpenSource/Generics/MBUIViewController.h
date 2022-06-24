// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBUITrackableViewController.h"
#import "MBStation.h"

#import "MBMapView.h"

@interface MBUIViewController : MBUITrackableViewController

@property (nonatomic, strong) MBStation *station;

@property (nonatomic, assign) BOOL swipeBackGestureEnabled;

- (instancetype) initWithRootBackButton;
- (instancetype) initWithBackButton:(BOOL)showBackButton;

+ (void) addBackButtonToViewController:(UIViewController*)vc andActionBlockOrNil:(void (^) (void))backHandler;
+ (void) removeBackButton:(UIViewController*)viewController;

- (void) showFacilityFavorites;
- (void) showFacilityForStation;


- (void) showWagenstandForUserInfo:(NSDictionary*)userInfo;

@end
