// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <UIKit/UIKit.h>

#import <Mantle/Mantle.h>
#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM(NSUInteger, FacilityState) {
    FacilityStateUnknown = 0,
    FacilityStateActive = 1,
    FacilityStateInactive = 2
};

typedef NS_ENUM(NSUInteger, FacilityType) {
    FacilityTypeEscalator = 0,
    FacilityTypeElevator = 1,
};

@interface FacilityStatus : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy) NSNumber *equipmentNumber;
@property (nonatomic, assign, readwrite) FacilityType type;
@property (nonatomic, assign, readwrite) FacilityState state;
@property (nonatomic, copy) NSString *shortDescription;
@property (nonatomic, copy) NSNumber *geoCoordinateX;
@property (nonatomic, copy) NSNumber *geoCoordinateY;
@property (nonatomic, copy) NSNumber *stationNumber;

@property (nonatomic, assign, readwrite) CLLocationCoordinate2D centerLocation;

- (UIImage*)iconForState;
- (NSString*)title;

-(BOOL)isSameFacility:(FacilityStatus*)another;

-(NSString*)shortDescription;

-(NSString*)equipmentNumberString;

@end
