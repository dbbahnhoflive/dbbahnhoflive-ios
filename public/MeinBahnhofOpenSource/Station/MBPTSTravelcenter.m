// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBPTSTravelcenter.h"
#import "NSDictionary+MBDictionary.h"
#import "MBPTSAvailabilityTimes.h"

@interface MBPTSTravelcenter()
@property(nonatomic,strong) NSDictionary* data;
@property(nonatomic,strong) CLLocation* location;
@end

@implementation MBPTSTravelcenter

-(instancetype)initWithDict:(NSDictionary*)json{
    self = [super init];
    if(self){
        if([json isKindOfClass:[NSDictionary class]]){
            self.data = json;
        }
    }
    return self;
}

-(CLLocationCoordinate2D)coordinate{
    NSDictionary* location = [self.data db_dictForKey:@"location"];
    NSNumber* lat = [location db_numberForKey:@"latitude"];
    NSNumber* lng = [location db_numberForKey:@"longitude"];
    CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(lat.doubleValue, lng.doubleValue);
    return loc;
}
-(CLLocation*)location{
    if(!_location){
        CLLocationCoordinate2D coordinate = [self coordinate];
        _location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    }
    return _location;
}

-(NSString *)title{
    return [self.data db_stringForKey:@"name"];
}
-(NSDictionary*)addressDict{
    return [self.data db_dictForKey:@"address"];
}

-(NSString *)address{
    return [self.addressDict db_stringForKey:@"street"];
}
-(NSString *)postCode{
    return [self.addressDict db_stringForKey:@"postalCode"];
}
-(NSString *)city{
    return [self.addressDict db_stringForKey:@"city"];
}
-(NSString*)openingTimes{
    NSArray* openingHours = [self.data db_arrayForKey:@"openingHours"];
    if(openingHours){
        MBPTSAvailabilityTimes* times = [[MBPTSAvailabilityTimes alloc] initWithArray:openingHours];
        return times.availabilityString;
    }
    return @"-";
}


@end
