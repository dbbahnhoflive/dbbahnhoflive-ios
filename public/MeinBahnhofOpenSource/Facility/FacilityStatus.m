// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "FacilityStatus.h"
#import "MBUIHelper.h"

@implementation FacilityStatus

-(NSString*)equipmentNumberString{
    return self.equipmentNumber.description;
}

- (UIImage*)iconForState
{
    switch (self.state) {
        case FacilityStateActive:
            if (self.type == FacilityTypeEscalator) {
                return [UIImage db_imageNamed:@"StairActive"];
            } else {
                return [UIImage db_imageNamed:@"ElevatorActive"];
            }
            break;
        case FacilityStateUnknown:
            if (self.type == FacilityTypeEscalator) {
                return [UIImage db_imageNamed:@"StairUnknown"];
            } else {
                return [UIImage db_imageNamed:@"ElevatorUnknown"];
            }
            break;
        default:
            if (self.type == FacilityTypeEscalator) {
                return [UIImage db_imageNamed:@"StairInactive"];
            } else {
                return [UIImage db_imageNamed:@"ElevatorInactive"];
            }
    }
}

- (CLLocationCoordinate2D) centerLocation
{
    if(_centerLocation.longitude == 0 && _centerLocation.latitude == 0) {
        _centerLocation = CLLocationCoordinate2DMake([self.geoCoordinateY doubleValue], [self.geoCoordinateX doubleValue]);
    }
    return _centerLocation;
}

+ (NSValueTransformer *)stateJSONTransformer {

    NSDictionary *states = @{
                             @"UNKNOWN": @(FacilityStateUnknown),
                             @"INACTIVE": @(FacilityStateInactive),
                             @"ACTIVE": @(FacilityStateActive)
                             };
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *value, BOOL *success, NSError *__autoreleasing *error) {
        if (!value) { // fallback in case the value is null
            return @(FacilityStateUnknown);
        }
        return states[value];
    }];
    
}

- (NSString*) title
{
    if (self.type == FacilityTypeEscalator) {
        return @"Fahrtreppe";
    } else if (self.type == FacilityTypeElevator) {
        return @"Aufzug";
    }
    return @"";
}

-(NSString *)shortDescription{
    if(_shortDescription){
        return _shortDescription;
    } else {
        return @"Aufzugsanlage";
    }
}

+ (NSValueTransformer *)typeJSONTransformer {
    return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{
                                                                           @"ELEVATOR": @(FacilityTypeElevator),
                                                                           @"ESCALATOR": @(FacilityTypeEscalator),
                                                                           }];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"equipmentNumber": @"equipmentnumber",
             @"type": @"type",
             @"shortDescription": @"description",
             @"geoCoordinateX": @"geocoordX",
             @"geoCoordinateY": @"geocoordY",
             @"state": @"state",
             @"stationNumber": @"stationnumber"
             };
}

+ (NSDictionary *)facilityMappingForSuedkreuz {
    // equipmentnumber : facilityId
    return @{
        
    };
}

/*+ (Class) classForParsingJSONDictionary:(NSDictionary *)JSONDictionary
{
    if (![JSONDictionary[@"type"] isEqualToString:@"ELEVATOR"]) {
        return nil;
    }
    return self.class;
}*/


-(BOOL)isSameFacility:(FacilityStatus *)another{
    return [self.stationNumber isEqualToNumber:another.stationNumber] && [self.equipmentNumber isEqualToNumber:another.equipmentNumber];
}

@end
