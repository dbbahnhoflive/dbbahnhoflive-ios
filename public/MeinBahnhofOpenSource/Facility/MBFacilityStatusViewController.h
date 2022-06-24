// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBStation.h"

@interface MBFacilityStatusViewController : UIViewController

@property (nonatomic, strong) MBStation *station;
@property (nonatomic, strong) NSString *trackingTitle;


@end
