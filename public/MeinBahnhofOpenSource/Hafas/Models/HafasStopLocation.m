// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "HafasStopLocation.h"
#import "MBTrainJourneyRequestManager.h"

@implementation HafasStopLocation

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error
{
    if (self = [super initWithDictionary:dictionaryValue error:error]) {
    }
    return self;
}

- (CLLocationCoordinate2D) positionAsLatLng
{
    return CLLocationCoordinate2DMake([self.lat doubleValue], [self.lon doubleValue]);
}

-(BOOL)hasChangedTrack{
    NSString* plan = self.depTrack;
    NSString* real = self.rtDepTrack;
    if(plan.length == 0 && real.length == 0){
        //use arrival tracks
        plan = self.arrTrack;
        real = self.rtArrTrack;
    }
    return plan.length > 0 && real.length > 0 && ![plan isEqualToString:real];
}

-(NSDate *)departure{
    return [self dateWithDate:self.depDate time:self.depTime tz:self.depTz];
}
-(NSDate *)arrival{
    return [self dateWithDate:self.arrDate time:self.arrTime tz:self.arrTz];
}
-(NSDate *)rtDeparture{
    return [self dateWithDate:self.rtDepDate time:self.rtDepTime tz:self.depTz];
}
-(NSDate*)rtArrival{
    return [self dateWithDate:self.rtArrDate time:self.rtArrTime tz:self.arrTz];
}

-(NSDate*)dateWithDate:(NSString*)date time:(NSString*)time tz:(NSInteger)tz{
    if(date && time){
        //2023-07-13T18:37:00+02:00
        NSInteger hoursTZ = (tz / 60);
        NSString* t = [NSString stringWithFormat:@"%@T%@+0%ld:00",date,time,(long)hoursTZ];
        return [MBTrainJourneyRequestManager.dateFormatter dateFromString:t];
    }
    return nil;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"stopId": @"id",
             @"name": @"name",
             @"extId": @"extId",
             @"lon": @"lon",
             @"lat": @"lat",
             @"cancelled": @"cancelled",
             @"cancelledDeparture": @"cancelledDeparture",
             @"additional": @"additional",
             @"depTime": @"depTime",
             @"depDate": @"depDate",
             @"arrTime": @"arrTime",
             @"arrDate": @"arrDate",
             @"rtDepTime": @"rtDepTime",
             @"rtDepDate": @"rtDepDate",
             @"rtArrTime": @"rtArrTime",
             @"rtArrDate": @"rtArrDate",
             @"arrTrack": @"arrTrack",
             @"depTrack": @"depTrack",
             @"arrTz": @"arrTz",
             @"depTz": @"depTz",
             @"rtDepTrack": @"rtDepTrack",
             @"rtArrTrack": @"rtArrTrack",
             };
}

@end
