// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBStation.h"
#import "MBStationKachel.h"
#import "MBRootContainerViewController.h"
#import "MBMapViewController.h"

@interface MBStationViewController : UIViewController<MBRootContainerViewControllerDelegate,MBMapViewControllerDelegate>

-(void)updateMapMarkersForFacilities;
-(void)openOPNV;
-(void)openStationFeatures;

@property (nonatomic, strong) MBStation *station;
@property (nonatomic, strong) MBStationTabBarViewController *tabBarViewController;


@end
