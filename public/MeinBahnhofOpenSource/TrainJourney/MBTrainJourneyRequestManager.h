// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import "Stop.h"
#import "MBTrainJourney.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBTrainJourneyRequestManager : NSObject
+ (MBTrainJourneyRequestManager*) sharedManager;

- (void) loadJourneyForEvent:(Event*)event
            completionBlock:(void (^)(MBTrainJourney * _Nullable journey))completion;

- (void)loadJourneyForId:(NSString*)journeyID
         completionBlock:(void (^)(MBTrainJourney * _Nullable journey))completion;

+(NSDateFormatter*)dateFormatter;

@end

NS_ASSUME_NONNULL_END
