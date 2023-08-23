// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBUIViewController.h"
#import "MBTrainJourney.h"
#import "Stop.h"
#import "MBMapViewController.h"
#import "HafasDeparture.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBTrainJourneyViewController : MBUIViewController<MBMapViewControllerDelegate>

@property(nonatomic,strong) MBTrainJourney* _Nullable journey;
@property(nonatomic,strong) Event* _Nullable event;
@property(nonatomic,strong) Stop* _Nullable stop;
@property(nonatomic,strong) MBStation* _Nullable hafasStationThatOpenedThisJourney;
@property(nonatomic,strong) MBOPNVStation* _Nullable originalHafasStation;
@property(nonatomic) BOOL departure;
@property(nonatomic) BOOL showJourneyFromCurrentStation;
@property(nonatomic) BOOL showJourneyMessageAndTrainLinks;

//a hafas-journey has no event and instead a HafasDeparture
@property(nonatomic,strong) HafasDeparture* _Nullable hafasDeparture;

@end

NS_ASSUME_NONNULL_END
