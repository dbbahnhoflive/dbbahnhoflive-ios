// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import "MBPTSAvailabilityTimes.h"
#import "MBPTSTravelcenter.h"

@interface MBPTSStationResponse : NSObject

-(instancetype)initWithResponse:(NSDictionary*)json;
-(BOOL)isValid;


-(NSNumber*)stadaIdNumber;
-(NSArray<NSString*>*)evaIds;
-(NSNumber*)category;
-(NSArray<NSNumber*>*)position;

//facility status
-(BOOL)hasSteplessAccess;
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

-(MBPTSTravelcenter*)travelCenter;

-(MBPTSAvailabilityTimes*)dbInfoAvailabilityTimes;
-(MBPTSAvailabilityTimes*)localServiceStaffAvailabilityTimes;
@end
