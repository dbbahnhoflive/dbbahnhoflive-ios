// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Mantle/Mantle.h>
#import "HafasRequestManager.h"

@class HafasStopLocation;

@interface HafasDeparture : MTLModel <MTLJSONSerializing>

/// day of departure
@property (nonatomic, strong) NSString *date;
/// time of departure
@property (nonatomic, strong) NSString *time;
/// line name
@property (nonatomic, strong) NSString *name;
/// station name
@property (nonatomic, strong) NSString *stop;
/// Hafas category
@property (nonatomic, strong) NSString *trainCategory;
/// destination station
@property (nonatomic, strong) NSString *direction;

/// day of departure
@property (nonatomic, strong) NSString *rtTime;
/// time of departure
@property (nonatomic, strong) NSString *rtDate;

@property (nonatomic,strong) NSString* stopid;

-(void)cleanupName;

-(NSArray<NSString*>*)stopLocationTitles;
-(void)storeStopLocations:(NSArray<HafasStopLocation*>*)stops;

-(HAFASProductCategory)productCategory;
+(NSString*)stringForCat:(HAFASProductCategory)cat;
-(NSString*)productLine;
-(NSString*)productName;

-(NSString*)journeyDetailId;

+(NSDate*)dateForDate:(NSString*)date andTime:(NSString*)time;
-(NSInteger)delayInMinutes;
-(NSString*)delayInMinutesString;
-(NSDate*)dateDeparture;
-(NSDate*)dateRTDeparture;
-(NSString*)expectedDeparture;
@end
