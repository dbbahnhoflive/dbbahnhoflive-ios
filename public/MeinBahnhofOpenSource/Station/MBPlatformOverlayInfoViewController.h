// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBOverlayViewController.h"
#import "MBStation.h"
#import "MBTrainJourneyStop.h"
#import "Stop.h"
#import "Event.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBPlatformOverlayInfoViewController : MBOverlayViewController
@property(nonatomic,strong) MBStation* station;
@property(nonatomic,strong) MBTrainJourneyStop* trainJourneyStop;
@property(nonatomic,strong) Event* event;

@end

NS_ASSUME_NONNULL_END
