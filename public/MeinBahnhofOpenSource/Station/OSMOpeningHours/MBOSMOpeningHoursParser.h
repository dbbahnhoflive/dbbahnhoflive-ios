// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import "MBOSMOpeningWeek.h"
#import "MBStation.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBOSMOpeningHoursParser : NSObject

+ (MBOSMOpeningHoursParser*)sharedInstance;

-(void)parseOSM:(NSString*)osmOpeningHours forStation:(MBStation*)station completion:(void (^)(MBOSMOpeningWeek* _Nullable week))completion;

-(NSCalendar*)formattingCalender;
-(NSDateFormatter*)timeFormatter;
-(NSDateFormatter*)weekdayFormatter;

@end

NS_ASSUME_NONNULL_END
