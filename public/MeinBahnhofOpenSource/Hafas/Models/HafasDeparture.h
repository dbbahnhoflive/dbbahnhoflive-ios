// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Mantle/Mantle.h>
#import "HafasRequestManager.h"

@class HafasStopLocation;

#define STOP_MISSING_TEXT @"Ein oder mehrere Halte fallen aus."
#define CANCELLED_TEXT @"Fahrt fällt aus."


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

@property (nonatomic, strong) NSString *track;
@property (nonatomic, strong) NSString *rtTrack;

@property (nonatomic) BOOL partCancelled;
@property (nonatomic) BOOL cancelled;

/// day of departure
@property (nonatomic, strong) NSString *rtTime;
/// time of departure
@property (nonatomic, strong) NSString *rtDate;

@property (nonatomic,strong) NSString* stopid;
@property (nonatomic,strong) NSString* stopExtId;

-(void)cleanupName;
-(BOOL)trackChanged;
-(NSString*)displayTrack;

-(NSArray<NSString*>*)stopLocationTitles;
-(NSArray<HafasStopLocation*>*)stopLocations;
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
