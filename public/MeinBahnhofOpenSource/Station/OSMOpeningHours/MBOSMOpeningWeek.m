// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBOSMOpeningWeek.h"
#import "MBOSMOpeningHoursParser.h"
#import <UIKit/UIKit.h>
@implementation MBOSMOpeningWeek

-(NSString *)description{
    NSMutableString* res = [NSMutableString new];
    [res appendString:self.originalString];
    [res appendString:@", "];
    [res appendString:self.weekstringForDisplay];
    [res appendString:@":\n"];
    for(MBOSMOpenInterval* i in self.openIntervals){
        [res appendFormat:@"%@ - %@, %@\n",i.startTime, i.endTime, i.comment];
    }
    return res;
}

-(NSArray<NSString *> *)calculateWeekdays{
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:7];
    [res addObject:@"Heute"];
    NSDateFormatter* df = MBOSMOpeningHoursParser.sharedInstance.weekdayFormatter;
    for(int i=1; i<7; i++){
        NSDate* date = [self.startDate dateByAddingTimeInterval:60*60*24*i];
        [res addObject:[df stringFromDate:date]];
    }
    return res;
}
-(NSArray<NSString*>*)openTimesForDay:(NSInteger)index{
    NSMutableArray* res = [NSMutableArray new];
    NSDateFormatter* df = MBOSMOpeningHoursParser.sharedInstance.timeFormatter;
    NSDate* date = [self.startDate dateByAddingTimeInterval:60*60*24*index];
    //find all open times with for this day
    for(MBOSMOpenInterval* interval in self.openIntervals){
        NSMutableString* str = [NSMutableString new];
        if([self sameDay:date day2:interval.startTime]){
            NSString* startString = [df stringFromDate:interval.startTime];
            [str appendString:startString];
            if(UIAccessibilityIsVoiceOverRunning()){
                [str appendString:@" bis "];
            } else {
                [str appendString:@" - "];
            }
            if([startString isEqualToString:@"00:00"]){
                NSTimeInterval delta = [interval.endTime timeIntervalSinceDate:interval.startTime];
                if(delta == 60*60*24){
                    //special case: endTime is the same "time" one day later instead of showing 00:00-00:00 we show 00:00-24:00
                    [str appendString:@"24:00"];
                } else {
                    [str appendString:[df stringFromDate:interval.endTime]];
                }
            } else {
                [str appendString:[df stringFromDate:interval.endTime]];
            }
            [str appendString:@" Uhr"];
            if(interval.comment.length > 0){
                [str appendString:@"\n"];
                [str appendString:interval.comment];
            }
            [res addObject:str];
        }
    }
    if(res.count == 0){
        return @[@"geschlossen"];
    } else {
        return res;
    }
}

-(BOOL)hasOpenTimes{
    return self.openIntervals.count > 0;
}

-(BOOL)sameDay:(NSDate*)day1 day2:(NSDate*)day2{
    NSCalendar *calendar  = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitDay| NSCalendarUnitMonth) fromDate:day1];
    NSDateComponents *componentsOther = [calendar components:(NSCalendarUnitDay| NSCalendarUnitMonth) fromDate:day2];
    return components.day == componentsOther.day && components.month == componentsOther.month;

}

@end
