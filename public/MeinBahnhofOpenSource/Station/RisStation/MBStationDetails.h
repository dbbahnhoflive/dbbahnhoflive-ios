// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

#import "MBTravelcenter.h"
#import "MBOSMOpeningWeek.h"

@interface MBStationDetails : NSObject

@property(nonatomic) NSInteger category;
@property(nonatomic) CLLocationCoordinate2D coordinate;

@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *state;

@property (nonatomic, strong) MBOSMOpeningWeek *dbInfoOpeningTimesOSM;
@property(nonatomic,strong) MBOSMOpeningWeek* localServiceOpeningTimesOSM;


-(instancetype)initWithResponse:(NSDictionary*)json;
-(BOOL)isValid;

//facility status

-(BOOL)hasPublicFacilities;
-(BOOL)hasWiFi;
-(BOOL)hasLockerSystem;
-(BOOL)hasDBInfo;
-(BOOL)hasTravelCenter;
-(BOOL)hasDBLounge;
-(BOOL)hasTravelNecessities;
-(BOOL)hasParking;
-(BOOL)hasBicycleParking;
-(BOOL)hasTaxiRank;
-(BOOL)hasCarRental;
-(BOOL)hasLostAndFound;

//services
-(BOOL)hasMobilityService;
-(NSString*)mobilityServiceText;

-(BOOL)hasRailwayMission;
-(BOOL)hasLocalServiceStaff;

-(BOOL)has3SZentrale;
-(NSString*)phoneNumber3S;

-(MBTravelcenter*)nearestTravelCenter;

-(NSString*)dbInfoOSMTimes;
-(NSString*)localServiceOSMTimes;
@end
