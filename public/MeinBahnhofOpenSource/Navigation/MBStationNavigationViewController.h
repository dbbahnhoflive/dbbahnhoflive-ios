// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBStationTopView.h"
#import "MBStation.h"

#define STATION_NAVIGATION_PICTURE_HEIGHT 280

@interface MBStationNavigationViewController : UINavigationController

@property (nonatomic, strong) UIButton* contentSearchButton;

@property (nonatomic, strong) MBStationTopView *behindView;
@property (nonatomic, strong) NSLayoutConstraint *behindHeightConstraint;
@property (nonatomic, strong) MBStation *station;
@property (nonatomic, assign) BOOL showRedBar;
@property (nonatomic, assign) BOOL hideEverything;

- (void)showBackgroundImage:(BOOL)showBackground;
- (void)hideNavbar:(BOOL)hidden;

@property(nonatomic,strong) UIColor* behindViewBackgroundColor;

#define STATION_SEARCH_PLACEHOLDER @"Suchen Sie etwas am Bahnhof?"

@end
