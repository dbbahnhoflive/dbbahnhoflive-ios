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
             @"cancelled": @"cancelled",
             @"partCancelled": @"partCancelled",
             @"journeyDetailRef": @"JourneyDetailRef",
             @"stopid": @"stopid",
             @"stopExtId": @"stopExtId",
             @"product": @"ProductAtStop",
             @"track": @"track",
             @"rtTrack": @"rtTrack",
             };
}

+ (NSSet *)propertyKeys {
    return [super propertyKeys];
}

-(void)cleanupName{
    self.name = [self removeSpacesFromString:self.name];
}


-(BOOL)trackChanged{
    return self.track.length > 0 && self.rtTrack.length > 0 && ![self.track isEqualToString:self.rtTrack];
}
-(NSString*)displayTrack{
    if(self.rtTrack.length > 0){
        return self.rtTrack;
    }
    return self.track;
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

+(NSString*)stringForCat:(HAFASProductCategory)cat{
    switch (cat) {
        case HAFASProductCategoryNONE:
            return @"Sonstige";
        case HAFASProductCategoryICE:
            return @"ICE";
        case HAFASProductCategoryIC:
            return @"IC";
        case HAFASProductCategoryIR:
            return @"IR";
        case HAFASProductCategoryREGIO:
            return @"RB";
        case HAFASProductCategoryS:
            return @"S-Bahn";
        case HAFASProductCategoryBUS:
            return @"Bus";
        case HAFASProductCategorySHIP:
            return @"Fähre";
        case HAFASProductCategoryU:
            return @"U-Bahn";
        case HAFASProductCategoryTRAM:
            return @"Tram";
        case HAFASProductCategoryCAL:
            return @"Anrufpflichtige Verkehre";
    }
}

-(HAFASProductCategory)productCategory{
    HAFASProductCategory cat = HAFASProductCategoryNONE;
    if(!self.product || self.product[@"cls"] == nil){
        return cat;
    }
    NSInteger catCode = [self.product[@"cls"] integerValue];
    return catCode;
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
