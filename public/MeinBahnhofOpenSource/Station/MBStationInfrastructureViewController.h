// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBOverlayViewController.h"
#import "MBStation.h"

@interface MBStationInfrastructureViewController : MBOverlayViewController

@property(nonatomic,strong) MBStation* station;

+(BOOL)displaySomeEntriesOnlyWhenAvailable:(MBStation*)station;

@end
