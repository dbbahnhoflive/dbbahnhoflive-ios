// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBEinkaufsbahnhofStore.h"

@implementation MBEinkaufsbahnhofStore

static NSArray* weekdaysEinkauf = nil;

+(MBEinkaufsbahnhofStore *)parse:(NSDictionary *)dict{
    if([dict[@"venueType"] isEqualToString:@"store"]){
        NSDictionary* localizedVenueCategories = dict[@"localizedVenueCategories"];
        //could be an array in the future?!
        if([localizedVenueCategories isKindOfClass:NSArray.class]){
            NSArray* localizedList = (NSArray*)localizedVenueCategories;
            for(NSDictionary* dict in localizedList){
                if([dict[@"locale"] isEqualToString:@"de"]){
                    localizedVenueCategories = dict;
                    break;
                }
            }
        }
        NSNumber* category_id = localizedVenueCategories[@"category_id"];
        MBEinkaufsbahnhofStore* res = [MBEinkaufsbahnhofStore new];
        NSDictionary* localizedVenues = dict[@"localizedVenues"];
        //could be an array in the future?!
        if([localizedVenues isKindOfClass:NSArray.class]){
            NSArray* localizedList = (NSArray*)localizedVenues;
            for(NSDictionary* dict in localizedList){
                if([dict[@"locale"] isEqualToString:@"de"]){
                    localizedVenues = dict;
                    break;
                }
            }
        }
        res.name = localizedVenues[@"name"];
        res.category_id = category_id;
        
        res.openingTimes = dict[@"openingTimes"];
        NSDictionary* extraFields = dict[@"extraFields"];
        res.paymentTypes = extraFields[@"paymentTypes"];
        res.web = extraFields[@"web"];
        res.phone = extraFields[@"phone"];
        res.email = extraFields[@"email"];
        res.location = extraFields[@"location"];
        return res;
    }
    return nil;
}


-(ShopOpenState)isOpen{
    NSArray *times = self.openingTimes;
    if (times.count == 0) {
        return POI_UNKNOWN;
    }

    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    [gregorian setLocale:[NSLocale localeWithLocaleIdentifier:@"de_DE"]];
    [gregorian setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Berlin"]];
    
    NSDateComponents *comps = [gregorian components:NSCalendarUnitWeekday|NSCalendarUnitHour|NSCalendarUnitMinute fromDate:[NSDate date]];
    NSInteger weekday = [comps weekday]-2;
    if(weekday < 0){
        weekday = 6;
    }
    if(!weekdaysEinkauf){
        weekdaysEinkauf = @[@"Mo",@"Di",@"Mi",@"Do",@"Fr",@"Sa",@"So"];
    }
    NSInteger currentHour = [comps hour];
    NSInteger currentMinutesFrom = [comps minute];
    NSTimeInterval timeToday = currentHour*60*60 + currentMinutesFrom*60;
    
    for(NSDictionary *openingTime in times) {
        NSString* dayRange = openingTime[@"day-range"];
        if([self isOpenToday:dayRange currentWeekday:weekday]){
            NSString* timeFrom = openingTime[@"time-from"];
            NSString* timeTo = openingTime[@"time-to"];
            if([timeFrom isEqualToString:timeTo]){
                //24h
                return POI_OPEN;
            } else if(timeFrom.length == 5 && timeTo.length == 5){
                NSTimeInterval timeFromTime = [self timeToTimeInterval:timeFrom];
                if(timeFromTime == 24*60*60){
                    NSLog(@"fixed timeFromTime, shop opened at 24h");
                    timeFromTime = 0;
                }
                NSTimeInterval timeToTime = [self timeToTimeInterval:timeTo];
                if(timeToTime < timeFromTime){
                    //must be next day, just check if we are behind from
                    if(timeToday >= timeFromTime){
                        return POI_OPEN;
                    }
                } else {
                    if(timeToday >= timeFromTime && timeToday <= timeToTime){
                        return POI_OPEN;
                    }
                }
            }
        }
    }
    return POI_CLOSED;
}
-(NSTimeInterval)timeToTimeInterval:(NSString*)hh_mm{
    NSInteger hour = [hh_mm substringToIndex:2].integerValue;
    NSInteger minute = [hh_mm substringFromIndex:2+1].integerValue;
    return hour*60*60 + minute*60;
}

-(NSInteger)indexForWeekday:(NSString*)weekdayString{
    return [weekdaysEinkauf indexOfObject:weekdayString];
}

-(BOOL)isOpenToday:(NSString*)dayRange currentWeekday:(NSInteger)weekday{
    if(dayRange.length > 0){
        if(dayRange.length == 2){
            //single day, e.g. "Mo"
            NSString* currentWeekday = weekdaysEinkauf[weekday];
            return [dayRange isEqualToString:currentWeekday];
        } else if(dayRange.length == 2+1+2 && [dayRange characterAtIndex:2]=='-'){
            //expecting Mo-Fr
            NSString* firstDay = [dayRange substringToIndex:2];
            NSString* secondDay = [dayRange substringFromIndex:2+1];
            NSInteger indexFirst = [self indexForWeekday:firstDay];
            NSInteger indexSecond = [self indexForWeekday:secondDay];
            if(indexFirst <= indexSecond){
                return (weekday >= indexFirst && weekday <= indexSecond);
            } else {
                //the second index in the next week
                //something like Sa-Di (Open: Sa,So,Mo,Di; Closed: Mi,Do,Fr)
                //so we are open when we are after Sa OR when we are before Di
                return weekday >= indexFirst || weekday <= indexSecond;
            }
        } else if([dayRange containsString:@"/"]){
            NSArray* days = [dayRange componentsSeparatedByString:@"/"];
            for(NSString* day in days){
                if([self isOpenToday:day currentWeekday:weekday]){
                    return YES;
                }
            }
        }
    }
    return NO;
}

@end
