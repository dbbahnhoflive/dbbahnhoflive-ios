// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBStationDetails.h"
#import "NSDictionary+MBDictionary.h"

@interface MBStationDetails()

@property(nonatomic,strong) NSDictionary* data;

@end

@implementation MBStationDetails

#define RIS_SERVICE_TYPE_INFORMATION_COUNTER @"INFORMATION_COUNTER"
#define RIS_SERVICE_TYPE_TRAVEL_CENTER @"TRAVEL_CENTER"
#define RIS_SERVICE_TYPE_VIDEO_TRAVEL_CENTER @"VIDEO_TRAVEL_CENTER"
#define RIS_SERVICE_TYPE_TRIPLE_S_CENTER @"TRIPLE_S_CENTER"
#define RIS_SERVICE_TYPE_TRAVEL_LOUNGE @"TRAVEL_LOUNGE"
#define RIS_SERVICE_TYPE_LOST_PROPERTY_OFFICE @"LOST_PROPERTY_OFFICE"
#define RIS_SERVICE_TYPE_RAILWAY_MISSION @"RAILWAY_MISSION"
#define RIS_SERVICE_TYPE_HANDICAPPED_TRAVELLER_SERVICE @"HANDICAPPED_TRAVELLER_SERVICE"
#define RIS_SERVICE_TYPE_LOCKER @"LOCKER"
#define RIS_SERVICE_TYPE_WIFI @"WIFI"
#define RIS_SERVICE_TYPE_CAR_PARKING @"CAR_PARKING"
#define RIS_SERVICE_TYPE_BICYCLE_PARKING @"BICYCLE_PARKING"
#define RIS_SERVICE_TYPE_PUBLIC_RESTROOM @"PUBLIC_RESTROOM"
#define RIS_SERVICE_TYPE_TRAVEL_NECESSITIES @"TRAVEL_NECESSITIES"
#define RIS_SERVICE_TYPE_CAR_RENTAL @"CAR_RENTAL"
#define RIS_SERVICE_TYPE_BICYCLE_RENTAL @"BICYCLE_RENTAL"
#define RIS_SERVICE_TYPE_TAXI_RANK @"TAXI_RANK"
#define RIS_SERVICE_TPYE_MOBILE_TRAVEL_SERVICE @"MOBILE_TRAVEL_SERVICE"


-(instancetype)initWithResponse:(NSDictionary *)json{
    self = [super init];
    if(self){
        self.coordinate = kCLLocationCoordinate2DInvalid;
        if([json isKindOfClass:[NSDictionary class]]){
            self.data = json;
        }
    }
    return self;
}

-(BOOL)isValid{
    return self.data.count > 0 && self.localServices != nil;
}

-(NSArray*)localServices{
    return [self.data db_arrayForKey:@"localServices"];
}

-(MBTravelcenter *)nearestTravelCenter{
    NSArray* travelCenters = [self servicesForType:RIS_SERVICE_TYPE_TRAVEL_CENTER];
    NSMutableArray<MBTravelcenter*>* list = [NSMutableArray arrayWithCapacity:2];
    for(NSDictionary* dict in travelCenters){
        if([dict isKindOfClass:NSDictionary.class]){
            if([dict db_stringForKey:@"localServiceID"].integerValue == 511113){
                //ignore this travelcenter in stuttgart, quick fix
                continue;
            }
            MBTravelcenter* res = [[MBTravelcenter alloc] initWithDict:dict];
            [list addObject:res];
        }
    }
    if(CLLocationCoordinate2DIsValid(self.coordinate)){
        //sort by distance to our station
        CLLocation *stationLocation = [[CLLocation alloc] initWithLatitude:self.coordinate.latitude longitude:self.coordinate.longitude];
        [list sortUsingComparator:^NSComparisonResult(MBTravelcenter* obj1, MBTravelcenter* obj2) {
            CLLocation *travelCenterLocation1 = obj1.location;
            CLLocationDistance dist1 = [travelCenterLocation1 distanceFromLocation:stationLocation];
            CLLocation *travelCenterLocation2 = obj2.location;
            CLLocationDistance dist2 = [travelCenterLocation2 distanceFromLocation:stationLocation];
            NSLog(@"Sort %@, %@",obj1.title,obj2.title);
            NSLog(@"dist %f, %f",dist1,dist2);
            if(dist1 == dist2){
                return NSOrderedSame;
            } else if(dist1 < dist2){
                return NSOrderedAscending;
            } else {
                return NSOrderedDescending;
            }
        }];
    }
    return list.firstObject;
}

-(NSDictionary*)serviceForType:(NSString*)type{
    NSArray* services = self.localServices;
    if(services){
        for(NSDictionary* dict in services){
            if([[dict db_stringForKey:@"type"] isEqualToString:type]){
                return dict;
            }
        }
    }
    return nil;
}
-(NSArray<NSDictionary*>*)servicesForType:(NSString*)type{
    NSArray* services = self.localServices;
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:3];
    if(services){
        for(NSDictionary* dict in services){
            if([[dict db_stringForKey:@"type"] isEqualToString:type]){
                [res addObject:dict];
            }
        }
    }
    return res;
}


-(BOOL)hasService:(NSString*)serviceType{
    return [self serviceForType:serviceType] != nil;
}

-(BOOL)hasPublicFacilities{
    return [self hasService:RIS_SERVICE_TYPE_PUBLIC_RESTROOM];
}
-(BOOL)hasWiFi{
    return [self hasService:RIS_SERVICE_TYPE_WIFI];
}
-(BOOL)hasLockerSystem{
    return [self hasService:RIS_SERVICE_TYPE_LOCKER];
}
-(BOOL)hasTravelCenter{
    return [self hasService:RIS_SERVICE_TYPE_TRAVEL_CENTER];
}
-(BOOL)hasDBLounge{
    return [self hasService:RIS_SERVICE_TYPE_TRAVEL_LOUNGE];
}
-(BOOL)hasTravelNecessities{
    return [self hasService:RIS_SERVICE_TYPE_TRAVEL_NECESSITIES];
}
-(BOOL)hasParking{
    return [self hasService:RIS_SERVICE_TYPE_CAR_PARKING];
}
-(BOOL)hasBicycleParking{
    return [self hasService:RIS_SERVICE_TYPE_BICYCLE_PARKING];
}
-(BOOL)hasTaxiRank{
    return [self hasService:RIS_SERVICE_TYPE_TAXI_RANK];
}
-(BOOL)hasCarRental{
    return [self hasService:RIS_SERVICE_TYPE_CAR_RENTAL];
}
-(BOOL)hasLostAndFound{
    return [self hasService:RIS_SERVICE_TYPE_LOST_PROPERTY_OFFICE];
}

-(BOOL)hasRailwayMission{
    return [self hasService:RIS_SERVICE_TYPE_RAILWAY_MISSION];
}

-(BOOL)hasMobilityService{
    NSString* text = [self mobilityServiceText];
    return text && ![text isEqualToString:@"no"];
}
-(NSString*)mobilityServiceText{
    if([self hasService:RIS_SERVICE_TYPE_HANDICAPPED_TRAVELLER_SERVICE]){
        NSDictionary* service = [self serviceForType:RIS_SERVICE_TYPE_HANDICAPPED_TRAVELLER_SERVICE];
        NSString* description = [service db_stringForKey:@"description"];
        return description;
    }
    return nil;
}
-(BOOL)hasLocalServiceStaff{
    return [self hasService:RIS_SERVICE_TPYE_MOBILE_TRAVEL_SERVICE];
}
-(NSString*)localServiceOSMTimes{
    NSDictionary* service = [self serviceForType:RIS_SERVICE_TPYE_MOBILE_TRAVEL_SERVICE];
    NSString* openingHours = [service db_stringForKey:@"openingHours"];
    return openingHours;
}


-(BOOL)hasDBInfo{
    return [self hasService:RIS_SERVICE_TYPE_INFORMATION_COUNTER];
}
-(NSString*)dbInfoOSMTimes{
    NSDictionary* service = [self serviceForType:RIS_SERVICE_TYPE_INFORMATION_COUNTER];
    NSString* openingHours = [service db_stringForKey:@"openingHours"];
    return openingHours;
}


-(BOOL)has3SZentrale{
    return [self hasService:RIS_SERVICE_TYPE_TRIPLE_S_CENTER];
}
-(NSString*)phoneNumber3S{
    NSDictionary* service = [self serviceForType:RIS_SERVICE_TYPE_TRIPLE_S_CENTER];
    NSDictionary* contact = [service db_dictForKey:@"contact"];
    NSArray* phoneNumbers = [contact db_arrayForKey:@"phoneNumbers"];
    for(NSDictionary* dict in phoneNumbers){
        if([dict isKindOfClass:NSDictionary.class]){
            NSString* type = [dict db_stringForKey:@"type"];
            NSString* number = [dict db_stringForKey:@"number"];
            if([type isEqualToString:@"BUSINESS"] && number){
                return number;
            }
        }
    }
    return nil;
}

@end
