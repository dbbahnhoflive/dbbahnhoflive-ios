// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBTravelcenter.h"
#import "NSDictionary+MBDictionary.h"


@interface MBTravelcenter()
@property(nonatomic,strong) NSDictionary* data;
@property(nonatomic,strong) CLLocation* location;
@end

@implementation MBTravelcenter

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
    NSDictionary* location = [self.data db_dictForKey:@"position"];
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
-(NSString*)openingHoursOSMString{
    return [self.data db_stringForKey:@"openingHours"];
}


@end
