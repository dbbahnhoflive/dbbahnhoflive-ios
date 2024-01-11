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
@property (nonatomic) BOOL cancelled;
@property (nonatomic) BOOL cancelledDeparture;
@property (nonatomic) BOOL additional;
@property (nonatomic, strong) NSString *depTime;
@property (nonatomic, strong) NSString *depDate;
@property (nonatomic, strong) NSString *arrTime;
@property (nonatomic, strong) NSString *arrDate;
@property (nonatomic, strong) NSString *rtDepTime;
@property (nonatomic, strong) NSString *rtDepDate;
@property (nonatomic, strong) NSString *rtArrTime;
@property (nonatomic, strong) NSString *rtArrDate;
@property (nonatomic, strong) NSString *arrTrack;
@property (nonatomic, strong) NSString *depTrack;
@property (nonatomic, strong) NSString *rtDepTrack;
@property (nonatomic, strong) NSString *rtArrTrack;


@property (nonatomic) NSInteger arrTz;
@property (nonatomic) NSInteger depTz;

-(NSDate*)departure;
-(NSDate*)arrival;
-(NSDate*)rtDeparture;
-(NSDate*)rtArrival;
-(BOOL)hasChangedTrack;
- (CLLocationCoordinate2D) positionAsLatLng;

@end
