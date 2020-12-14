// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import "TimetableParser.h"
#import "Stop.h"

//debug features
#define TIMETABLE_USE_SIMULATED_DATE NO
#define TIMETABLE_USE_STATIC_TESTFILES NO
#define TIMETABLE_FORCE_STATIC_TESTFILES NO


@interface Timetable : NSObject

@property (nonatomic, strong) NSMutableArray *stops;

@property (nonatomic, strong) NSArray *arrivalStops;
@property (nonatomic, strong) NSArray *departureStops;

@property (nonatomic, strong) NSDate* lastRequestedDate;
@property (nonatomic, assign) NSInteger additionalRequestHours;

- (void) initializeTimetableFromData:(NSData*)data;
- (void) updateTimetableFromData:(NSData*)data;

- (void) clearTimetable;
- (BOOL) hasTimetableData;

-(void)generateTestdata;//for debugging

+(NSDate*)now;

- (NSArray*) availablePlatformsForDeparture:(BOOL)departure;
- (NSArray*) availableTransportTypesForDeparture:(BOOL)departure;
@end
