// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import "MBTrainJourneyEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBTrainJourneyStop : NSObject

-(MBTrainJourneyStop *)initWithEvent:(MBTrainJourneyEvent*)event;

@property(nonatomic) BOOL additional;
@property(nonatomic) BOOL canceled;
@property(nonatomic) NSInteger journeyProgress;//calculated from current time
@property(nonatomic) BOOL isTimeScheduleStop;

@property(nonatomic,strong) NSString* stationName;
@property(nonatomic,strong) NSString* evaNumber;

//from arrival
@property(nonatomic,strong) NSString* _Nullable platform;
@property(nonatomic,strong) NSString* _Nullable platformSchedule;

//initial station has no arrival, last station has no departure
@property(nonatomic,strong) NSDate* _Nullable arrivalTime;
@property(nonatomic,strong) NSDate* _Nullable arrivalTimeSchedule;
@property(nonatomic,strong) NSDate* _Nullable departureTime;
@property(nonatomic,strong) NSDate* _Nullable departureTimeSchedule;

-(BOOL)platformChange;

@end

NS_ASSUME_NONNULL_END
