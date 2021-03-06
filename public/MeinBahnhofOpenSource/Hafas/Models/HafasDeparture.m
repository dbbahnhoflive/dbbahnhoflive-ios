// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "HafasDeparture.h"
#import "HafasStopLocation.h"

@interface HafasDeparture()

//hide internal dict structure
@property (nonatomic, strong) NSDictionary* product;
@property (nonatomic, strong) NSDictionary* journeyDetailRef;


@property(nonatomic,strong) NSArray* stopLocations;//filled later by separate request

@end

@implementation HafasDeparture

static NSRegularExpression *regex = nil;
static NSDateFormatter* dateTimeFormatter = nil;

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"date": @"date",
             @"time": @"time",
             @"rtDate": @"rtDate",
             @"rtTime": @"rtTime",
             @"name": @"name",
             @"stop": @"stop",
             @"trainCategory": @"trainCategory",
             @"direction": @"direction",
             @"journeyDetailRef": @"JourneyDetailRef",
             @"stopid": @"stopid",
             @"product": @"Product"
             };
}

+ (NSSet *)propertyKeys {
    return [super propertyKeys];
}

-(void)cleanupName{
    self.name = [self removeSpacesFromString:self.name];
}

-(NSString *)journeyDetailId{
    if(self.journeyDetailRef){
        return self.journeyDetailRef[@"ref"];
    }
    return nil;
}

-(NSArray<NSString *> *)stopLocationTitles{
    if(!self.stopLocations){
        return nil;
    }
    
    NSMutableArray* stopNames = [NSMutableArray arrayWithCapacity:self.stopLocations.count];
    for(HafasStopLocation* stop in self.stopLocations){
        [stopNames addObject:stop.name];
    }
    return stopNames;
}
-(void)storeStopLocations:(NSArray *)stops{
    self.stopLocations = stops;
}

-(HAFASProductCategory)productCategory{
    HAFASProductCategory cat = HAFASProductCategoryNONE;
    if(!self.product || self.product[@"catCode"] == nil){
        return cat;
    }
    NSInteger catCode = [self.product[@"catCode"] integerValue];
    switch(catCode){
        case 0:
            cat = HAFASProductCategoryICE;
            break;
        case 1:
            cat = HAFASProductCategoryIC;
            break;
        case 2:
            cat = HAFASProductCategoryIR;
            break;
        case 3:
            cat = HAFASProductCategoryREGIO;
            break;
        case 4:
            cat = HAFASProductCategoryS;
            break;
        case 5:
            cat = HAFASProductCategoryBUS;
            break;
        case 6:
            cat = HAFASProductCategorySHIP;
            break;
        case 7:
            cat = HAFASProductCategoryU;
            break;
        case 8:
            cat = HAFASProductCategoryTRAM;
            break;
        case 9:
            cat = HAFASProductCategoryCAL;
            break;
    }
    return cat;
}
-(NSString*)productLine{
    NSString* line = self.product[@"line"];
    if([line isKindOfClass:NSString.class] && line.length > 0){
        return line;
    }
    return nil;
}
-(NSString*)productName{
    return self.name;
    /*
    //NSLog(@"getting productName from %@",self.product);
    NSString* line = self.product[@"name"];
    if([line isKindOfClass:NSString.class] && line.length > 0){
        //we get a string like "Bus  142", remove the duplicated spaces
        return [self removeSpacesFromString:line];
    }
    return nil;*/
}
-(NSString*)removeSpacesFromString:(NSString*)string{
    NSString *trimmedString = [self.staticRegex stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, string.length) withTemplate:@" "];
    return trimmedString;
}
-(NSRegularExpression*)staticRegex{
    if(!regex){
        NSError *error = nil;
        regex = [NSRegularExpression regularExpressionWithPattern:@"  +" options:NSRegularExpressionCaseInsensitive error:&error];
    }
    return regex;
}

+(NSDateFormatter*)formatter{
    if(!dateTimeFormatter){
        dateTimeFormatter = [[NSDateFormatter alloc] init];
        dateTimeFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        dateTimeFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"DE"];
        dateTimeFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:60*60];//+1h
    }
    return dateTimeFormatter;
}

-(NSDate*)dateDeparture{
    return [HafasDeparture dateForDate:self.date andTime:self.time];
}
-(NSDate*)dateRTDeparture{
    return [HafasDeparture dateForDate:self.rtDate andTime:self.rtTime];
}
+(NSDate*)dateForDate:(NSString*)date andTime:(NSString*)time{
    if(date.length > 0 && time.length > 0){
        NSDate* dateDeparture = [[HafasDeparture formatter] dateFromString:[NSString stringWithFormat:@"%@ %@",date,time]];
        return dateDeparture;
    }
    return nil;
}

-(NSInteger)delayInMinutes{
    //time in minutes between planed and real time
    NSDate* dateRT = [self dateRTDeparture];
    if(dateRT){
        NSDate* datePlaned = [self dateDeparture];
        
        NSTimeInterval delay = dateRT.timeIntervalSinceReferenceDate - datePlaned.timeIntervalSinceReferenceDate;
        NSInteger delayInMinutes = delay/60;
        return MAX(0, delayInMinutes);
    }
    return 0;
}
-(NSString *)delayInMinutesString{
    NSInteger delay = [self delayInMinutes];
    if(delay > 0){
        return [NSString stringWithFormat:@"+%ld",(long)delay];
    } else {
        return @"";
    }
}

-(NSString*)expectedDeparture{
    NSDate* dateRT = [self dateRTDeparture];
    if(dateRT){
        //we have a valid delay timestamp
        return [self.rtTime substringToIndex:5];
    } else {
        return [self.time substringToIndex:5];
    }
}

@end
