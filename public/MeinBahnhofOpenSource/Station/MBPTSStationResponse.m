// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBPTSStationResponse.h"
#import "NSDictionary+MBDictionary.h"

@interface MBPTSStationResponse()

@property(nonatomic,strong) NSDictionary* data;

@end

@implementation MBPTSStationResponse

-(instancetype)initWithResponse:(NSDictionary *)json{
    self = [super init];
    if(self){
        if([json isKindOfClass:[NSDictionary class]]){
            self.data = json;
        }
    }
    return self;
}

-(BOOL)isValid{
    return self.data.count > 0 && self.evaIds.count > 0;
}

-(MBPTSTravelcenter *)travelCenter{
    NSDictionary* _embedded = self.data[@"_embedded"];
    NSArray* travelCenters = [_embedded db_arrayForKey:@"travelCenters"];
    NSMutableArray<MBPTSTravelcenter*>* list = [NSMutableArray arrayWithCapacity:2];
    for(NSDictionary* dict in travelCenters){
        if([dict isKindOfClass:NSDictionary.class]){
            //use only type "travel center"
            if([[dict db_stringForKey:@"type"] isEqualToString:@"travel center"]){
                MBPTSTravelcenter* res = [[MBPTSTravelcenter alloc] initWithDict:dict];
                [list addObject:res];
            }
        }
    }
    NSArray<NSNumber*>* pos = self.position;
    if(pos){
        //sort by distance to our station
        CLLocation *stationLocation = [[CLLocation alloc] initWithLatitude:pos.firstObject.doubleValue longitude:pos.lastObject.doubleValue];
        [list sortUsingComparator:^NSComparisonResult(MBPTSTravelcenter* obj1, MBPTSTravelcenter* obj2) {
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

-(NSString*)getIdentifierForType:(NSString*)type{
    NSArray* identifiers = self.data[@"identifiers"];
    NSString* value = nil;
    for(NSDictionary* identifier in identifiers){
        if([identifier[@"type"] isEqualToString:type]){
            value = identifier[@"value"];
            if(value){
                break;
            }
        }
    }
    return value;
}

-(NSString*)stadaIdString{
    return [self getIdentifierForType:@"STADA"];
}
-(NSNumber*)stadaIdNumber{
    return [NSNumber numberWithInteger:[self stadaIdString].integerValue];
}

-(NSArray<NSString *> *)evaIds{
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:5];
    
    NSString* evaMainId = [self getIdentifierForType:@"EVA"];
    if(!evaMainId){
        return nil;//failure
    }
    [res addObject:evaMainId];

    NSString* stadaId = [self stadaIdString];

    NSDictionary* _embedded = self.data[@"_embedded"];
    NSArray* neighbours = _embedded[@"neighbours"];
    for(NSDictionary* neighbour in neighbours){
        if(![neighbour isKindOfClass:NSDictionary.class]){
            continue;
        }
        
        NSString* belongsToStation = neighbour[@"belongsToStation"];
        if(belongsToStation.length > 0 && ![stadaId isEqualToString:belongsToStation]){
            //this is a neighbour station that belongs to another stada station, ignore it
            continue;
        }
        NSDictionary* links = neighbour[@"_links"];
        NSDictionary* selfDict = links[@"self"];
        NSString* href = selfDict[@"href"];
        NSRange rangeLastSlash = [href rangeOfString:@"/" options:NSBackwardsSearch];
        if(rangeLastSlash.location != NSNotFound && rangeLastSlash.location+1 < href.length){
            NSString* evaSubstring = [href substringFromIndex:rangeLastSlash.location+1];
            if(evaSubstring.length > 1 && [evaSubstring characterAtIndex:0] == '8'){
                NSCharacterSet *searchSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
                NSRange r = [evaSubstring rangeOfCharacterFromSet: searchSet];
                if(r.location == NSNotFound){
                    [res addObject:evaSubstring];
                }//else: there are some other characters that are not numbers, ignore this id
            }
        }
    }
    return res;
}

-(NSDictionary*)detailData{
    NSDictionary* res = self.data[@"details"];
    if([res isKindOfClass:NSDictionary.class]){
        return res;
    }
    return nil;
}

-(NSNumber *)category{
    NSDictionary* details = [self detailData];
    NSNumber* num = details[@"ratingCategory"];
    if([num isKindOfClass:NSNumber.class]){
        return num;
    }
    return nil;
}


-(NSArray<NSNumber *> *)position{
    NSDictionary* location = self.data[@"location"];
    NSNumber* lat = location[@"latitude"];
    NSNumber* lng = location[@"longitude"];
    if(lat && lng){
        return @[ lat,lng ];
    } else {
        return nil;
    }
}

-(BOOL)boolValueForKey:(NSString*)key{
    NSDictionary* details = [self detailData];
    NSNumber* obj = details[key];
    if([obj isKindOfClass:NSNumber.class]){
        return [obj boolValue];
    }
    if([obj isKindOfClass:NSString.class]){
        NSString* s = (NSString*)obj;
        return [s isEqualToString:@"YES"] || [s isEqualToString:@"yes"];
    }
    return NO;
}

-(BOOL)hasSteplessAccess{
    return [self boolValueForKey:@"hasSteplessAccess"];//future dev: some stations have "PARTIAL"
}
-(BOOL)hasPublicFacilities{
    return [self boolValueForKey:@"hasPublicFacilities"];
}
-(BOOL)hasWiFi{
    return [self boolValueForKey:@"hasWifi"];
}
-(BOOL)hasLockerSystem{
    return [self boolValueForKey:@"hasLockerSystem"];
}
-(BOOL)hasTravelCenter{
    return [self boolValueForKey:@"hasTravelCenter"];
}
-(BOOL)hasDBLounge{
    return [self boolValueForKey:@"hasDbLounge"];
}
-(BOOL)hasTravelNecessities{
    return [self boolValueForKey:@"hasTravelNecessities"];
}
-(BOOL)hasParking{
    return [self boolValueForKey:@"hasParking"];
}
-(BOOL)hasBicycleParking{
    return [self boolValueForKey:@"hasBicycleParking"];
}
-(BOOL)hasTaxiRank{
    return [self boolValueForKey:@"hasTaxiRank"];
}
-(BOOL)hasCarRental{
    return [self boolValueForKey:@"hasCarRental"];
}
-(BOOL)hasLostAndFound{
    return [self boolValueForKey:@"hasLostAndFound"];
}

-(BOOL)hasRailwayMission{
    return [self boolValueForKey:@"hasRailwayMission"];
}

-(BOOL)hasMobilityService{
    NSString* text = [[self detailData] objectForKey:@"mobilityService"];
    return text && ![text isEqualToString:@"no"];
}
-(NSString*)mobilityServiceText{
    return [[self detailData] objectForKey:@"mobilityService"];
}
-(BOOL)hasLocalServiceStaff{
    return [[self detailData] objectForKey:@"localServiceStaff"] != nil;
}

-(BOOL)hasDBInfo{
    return [[self detailData] objectForKey:@"dbInformation"] != nil;
}
-(MBPTSAvailabilityTimes *)dbInfoAvailabilityTimes{
    NSDictionary* obj = [[self detailData] objectForKey:@"dbInformation"];
    NSArray* availability = [obj objectForKey:@"availability"];
    return [[MBPTSAvailabilityTimes alloc] initWithArray:availability];
}
-(MBPTSAvailabilityTimes*)localServiceStaffAvailabilityTimes{
    NSDictionary* obj = [[self detailData] objectForKey:@"localServiceStaff"];
    NSArray* availability = [obj objectForKey:@"availability"];
    return [[MBPTSAvailabilityTimes alloc] initWithArray:availability];
}

-(BOOL)has3SZentrale{
    NSDictionary* _embedded = self.data[@"_embedded"];
    return [_embedded objectForKey:@"tripleSCenter"] != nil;
}
-(NSString*)phoneNumber3S{
    NSDictionary* _embedded = self.data[@"_embedded"];
    NSDictionary* tripleSCenter = [_embedded objectForKey:@"tripleSCenter"];
    return [tripleSCenter objectForKey:@"publicPhoneNumber"];
}

@end
