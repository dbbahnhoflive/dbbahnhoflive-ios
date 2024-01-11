// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "RIMapPoiOpenTime.h"

@implementation RIMapPoiOpenTime

- (NSString *)description
{
    return [NSString stringWithFormat:@"(%@ <%@>: %@)",self.daysDisplayString, self.days,self.openTimes];
}

-(BOOL)validForDay:(NSString *)weekday{
    return [self.days containsObject:weekday];
}

+(NSArray *)weekdayList{
    return @[ kWeekDayMo,kWeekDayDi,kWeekDayMi,kWeekDayDo,kWeekDayFr,kWeekDaySa,kWeekDaySo ];
}
+(NSArray *)weekdayListShort{
    return @[ kWeekDayMoShort,kWeekDayDiShort,kWeekDayMiShort,kWeekDayDoShort,kWeekDayFrShort,kWeekDaySaShort,kWeekDaySoShort ];
}

-(NSString*)openTimesStringForVoiceOver:(BOOL)voiceOver{
    NSMutableString* s = [NSMutableString new];
    for(NSString* time in (voiceOver? self.openTimesVoiceOver : self.openTimes)){
        if(s.length > 0){
            [s appendString:@","];
        }
        [s appendString:time];
    }
    return s;
}


+(BOOL)isValidWeekday:(NSString*)s{
    return [kWeekDayHoliday isEqualToString:s]
    || [kWeekDayMo isEqualToString:s]
    || [kWeekDayDi isEqualToString:s]
    || [kWeekDayMi isEqualToString:s]
    || [kWeekDayDo isEqualToString:s]
    || [kWeekDayFr isEqualToString:s]
    || [kWeekDaySa isEqualToString:s]
    || [kWeekDaySo isEqualToString:s];
}

@end
