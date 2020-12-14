// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBPTSAvailabilityTimes.h"

@interface MBPTSAvailabilityTimes()

@end

@implementation MBPTSAvailabilityTimes

static NSArray* dayOrder = nil;
static NSArray* displayTitles = nil;

-(instancetype)initWithArray:(NSArray *)availability{
    self = [super init];
    if(self){
        if(!dayOrder){
            dayOrder = @[@"monday", @"tuesday", @"wednesday", @"thursday", @"friday", @"saturday", @"sunday", @"holiday"];
            displayTitles = @[ @"Montag", @"Dienstag", @"Mittwoch", @"Donnerstag", @"Freitag", @"Samstag", @"Sonntag", @"Feiertags"];
        }
        
        self.availabilityStrings = [NSMutableArray arrayWithCapacity:8];
        NSInteger index = 0;
        NSString* lastDayAdded = nil;
        for(NSString* dayKey in dayOrder){
            for(NSDictionary* dayDict in availability){
                if([dayDict[@"day"] isEqualToString:dayKey]){
                    NSString* from = [dayDict objectForKey:@"openTime"];
                    NSString* to = [dayDict objectForKey:@"closeTime"];
                    from = [self parseTime:from];
                    to = [self parseTime:to];
                    if(dayDict){
                        if([lastDayAdded isEqualToString:dayKey]){
                           //same day: add the time with ", " on the same line
                            NSString* s = self.availabilityStrings.lastObject;
                            [self.availabilityStrings removeLastObject];
                            [self.availabilityStrings addObject:[NSString stringWithFormat:@"%@, %@-%@", s, from,to]];
                        } else {
                            [self.availabilityStrings addObject:[NSString stringWithFormat:@"%@: %@-%@", displayTitles[index], from,to]];
                            lastDayAdded = dayKey;
                        }
                    }
                }
            }
            index++;
        }
    }
    return self;
}
-(NSString*)parseTime:(NSString*)timeString{
    if(timeString.length == @"hh:mm:ss".length && [timeString rangeOfString:@":" options:NSBackwardsSearch].location == 5){
        //remove the seconds
        return [timeString substringToIndex:5];
    }
    return timeString;
}

-(NSString *)availabilityString{
    NSMutableString* res = [NSMutableString new];
    for(NSString* str in self.availabilityStrings){
        [res appendString:str];
        [res appendString:@"<br>"];
    }
    return res;
}

@end
