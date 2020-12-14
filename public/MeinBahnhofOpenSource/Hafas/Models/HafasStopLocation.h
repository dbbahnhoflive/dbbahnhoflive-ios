// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <Mantle/Mantle.h>

@interface HafasStopLocation : MTLModel <MTLJSONSerializing>

/// JSON Property "id"
@property (nonatomic, strong) NSString *stopId;
@property (nonatomic, strong) NSString *extId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *lon;
@property (nonatomic, strong) NSNumber *lat;

- (CLLocationCoordinate2D) positionAsLatLng;

@end
