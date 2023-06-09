// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBUIViewController.h"
#import "MBTrainJourney.h"
#import "Stop.h"
#import "MBMapViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBTrainJourneyViewController : MBUIViewController<MBMapViewControllerDelegate>

@property(nonatomic,strong) MBTrainJourney* _Nullable journey;
@property(nonatomic,strong) Event* event;
@property(nonatomic) BOOL departure;
@property(nonatomic) BOOL showJourneyFromCurrentStation;
@property(nonatomic) BOOL showJourneyMessageAndTrainLinks;
@property(nonatomic) BOOL hafasJourney;

@end

NS_ASSUME_NONNULL_END
