// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import "MBTrainJourneyStop.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBTrainJourney : NSObject

-(MBTrainJourney*)initWithDict:(NSDictionary*)dict;

@property(nonatomic,strong) NSString* _Nullable debugString;

@property(nonatomic,strong) NSString* journeyID;
@property(nonatomic) BOOL journeyCanceled;
-(NSArray<MBTrainJourneyStop*>*)journeyStopsForDeparture:(BOOL)departure;
-(BOOL)isSEVJourney;
@property(nonatomic) BOOL dateMismatch;

@end

NS_ASSUME_NONNULL_END
