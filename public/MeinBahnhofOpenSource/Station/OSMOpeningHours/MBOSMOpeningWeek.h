// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import "MBOSMOpenInterval.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBOSMOpeningWeek : NSObject

@property(nonatomic,strong) NSString* originalString;

@property(nonatomic,strong) NSDate* startDate;

@property(nonatomic,strong) NSString* weekstringForDisplay;
@property(nonatomic,strong) NSArray<MBOSMOpenInterval*>* openIntervals;

-(NSArray<NSString*>*)calculateWeekdays;
-(NSArray<NSString*>*)openTimesForDay:(NSInteger)index;

-(BOOL)hasOpenTimes;

@end

NS_ASSUME_NONNULL_END
