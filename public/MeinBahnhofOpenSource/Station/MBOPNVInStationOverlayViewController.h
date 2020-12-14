// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBOverlayViewController.h"
#import "MBStation.h"
#import "HafasRequestManager.h"
#import "MBOPNVStation.h"

#define NEAREST_STATIONS_LIMIT_IN_M 250

//NS_ASSUME_NONNULL_BEGIN

@interface MBOPNVInStationOverlayViewController : MBOverlayViewController

@property(nonatomic,strong) NSArray<MBOPNVStation*>* nearestStations;//results from Hafas nearby request

@property(nonatomic,strong) MBStation* station;

@end

//NS_ASSUME_NONNULL_END
