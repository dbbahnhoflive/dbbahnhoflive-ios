// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBOSMOpeningHoursParser.h"
#import "MBOSMOpeningWeek.h"
@import WebKit;

@interface MBOSMOpeningHoursParser()
@property(nonatomic,strong) WKWebView* webView;
@property(nonatomic,strong) NSDateFormatter* dateFormatter;
@property(nonatomic,strong) NSDateFormatter* weekFormatter;
@property(nonatomic,strong) NSCalendar* calender;
@end

@implementation MBOSMOpeningHoursParser

+ (MBOSMOpeningHoursParser*)sharedInstance
{
    static MBOSMOpeningHoursParser *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[self alloc] init];
    });
    return sharedClient;
}

-(instancetype)init{
    self = [super init];
    if(self){
        //formatter used for generating the displayed open times (hh:mm)
        self.dateFormatter = [NSDateFormatter new];
        [self.dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"de"]];
        [self.dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Berlin"]];
        [self.dateFormatter setDateStyle:NSDateFormatterNoStyle];
        [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        
        self.weekFormatter = [NSDateFormatter new];
        [self.weekFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"de"]];
        [self.weekFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Berlin"]];
        [self.weekFormatter setDateFormat:@"EEEE"];
        
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        [gregorian setLocale:[NSLocale localeWithLocaleIdentifier:@"de_DE"]];
        [gregorian setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Berlin"]];
        self.calender = gregorian;

        self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[WKWebViewConfiguration new]];
        NSURL* osmPage = [NSBundle.mainBundle URLForResource:@"osm_opening_hours" withExtension:@"html"];
        [self.webView loadFileURL:osmPage allowingReadAccessToURL:osmPage.URLByDeletingLastPathComponent];
    }
    return self;
}

-(NSCalendar*)formattingCalender{
    return self.calender;
}
-(NSDateFormatter*)timeFormatter{
    return self.dateFormatter;
}
-(NSDateFormatter *)weekdayFormatter{
    return self.weekFormatter;
}

-(void)parseOSM:(NSString*)osmOpeningHours forStation:(MBStation*)station completion:(void (^)(MBOSMOpeningWeek* _Nullable week))completion{
    //NSLog(@"start parsing..  %@",osmOpeningHours);
    if(![osmOpeningHours isKindOfClass:NSString.class] || osmOpeningHours.length == 0){
        completion(nil);
        return;
    }
    if(!self.webView){
        completion(nil);
        return;
    }
    
    NSDateFormatter* df = [NSDateFormatter new];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [df setDateFormat:@"dd MMM yyyy"];
    
    NSDate* today = [self.calender startOfDayForDate:NSDate.date];
    NSDate* in6DaysDate = [today dateByAddingTimeInterval:60*60*24*6];
    NSString* todayString = [df stringFromDate:today];//@"13 Jan 2022";
    
    if(UIAccessibilityIsVoiceOverRunning()){
        [df setDateFormat:@"dd. MMM"];
    } else {
        [df setDateFormat:@"dd.MM."];
    }
    NSString* startDate = [df stringFromDate:today];
    if(UIAccessibilityIsVoiceOverRunning()){
        [df setDateFormat:@"dd. MMM yyyy"];
    } else {
        [df setDateFormat:@"dd.MM.yy"];
    }
    NSString* endDate = [df stringFromDate:in6DaysDate];
    NSString* divider = @"-";
    if(UIAccessibilityIsVoiceOverRunning()){
        divider = @"bis";
    }
    NSString* interval = [NSString stringWithFormat:@"%@ %@ %@",startDate,divider,endDate];

    NSString* lat = [NSString stringWithFormat:@"%f",station.stationDetails.coordinate.latitude];
    NSString* lon = [NSString stringWithFormat:@"%f",station.stationDetails.coordinate.longitude];
    NSString* country = station.stationDetails.country.lowercaseString;
    NSString* state = station.stationDetails.state;

    NSString* jsCall = [NSString stringWithFormat:@"parseOSMhours('%@', '%@', %@,%@,'%@','%@')",osmOpeningHours,todayString,lat,lon,country,state];
    //NSLog(@"process opening_hours: %@",jsCall);
        
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.webView evaluateJavaScript:jsCall completionHandler:^(id _Nullable something, NSError * _Nullable error) {
            if(!error){
                //NSLog(@"OSM opening_hours evaluate returned %@",something);
                NSString* result = @"";
                if([something isKindOfClass:NSString.class]){
                    result = something;
                    NSArray<NSString*>* components = [result componentsSeparatedByString:@"#;#"];
                    //NSLog(@"got opening_hours for %@: %@",interval,components);
                    //Expecting 3 entries for each timeslot (start,end,comment)
                    if((components.count % 3) == 0 && components.count > 0){
                        //got some valid time intervals
                        
                        MBOSMOpeningWeek* week = [MBOSMOpeningWeek new];
                        week.originalString = osmOpeningHours;
                        week.startDate = today;
                        week.weekstringForDisplay = interval;
                        NSMutableArray<MBOSMOpenInterval*>* openIntervals = [NSMutableArray new];
                        for(NSInteger i=0; i<components.count; ){
                            NSTimeInterval start = components[i].doubleValue;
                            NSTimeInterval end = components[i+1].doubleValue;
                            NSString* comment = components[i+2];
                            MBOSMOpenInterval* openInterval = [MBOSMOpenInterval new];
                            openInterval.startTime = [NSDate dateWithTimeIntervalSince1970:start];
                            openInterval.endTime = [NSDate dateWithTimeIntervalSince1970:end];
                            openInterval.comment = comment;
                            [openIntervals addObject:openInterval];
                            i += 3;
                        }
                        week.openIntervals = openIntervals;
                        //NSLog(@"parsed %@ to %@",osmOpeningHours,week);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(week);
                        });
                        return;
                    }
                } else {
                    NSLog(@"error: string expected, got %@",something);
                }
            } else {
                NSLog(@"OSM opening_hours evaluate failed for %@: %@",osmOpeningHours,error);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil);
            });
        }];
    });
}




@end
