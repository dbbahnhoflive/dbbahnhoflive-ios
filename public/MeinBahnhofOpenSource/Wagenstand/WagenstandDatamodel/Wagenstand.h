// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "Train.h"
#import "Waggon.h"

@interface Wagenstand : NSObject

@property (nonatomic, strong) NSString *platform; // String taken from trackRecords
@property (nonatomic, copy) NSString *expected_time; // String, including delays, time is from IRIS
@property (nonatomic, copy) NSString *plan_time; // String, time in plan, time is from IRIS

@property (nonatomic, copy, readonly) NSArray *traintypes; // Array of Strings
@property (nonatomic, copy, readonly) NSArray *trainNumbers; // Array of Numbers
@property (nonatomic, copy, readonly) NSArray *subtrains; // Array of Trains
@property (nonatomic, copy, readonly) NSArray *waggons; // Array of Trains

@property (nonatomic, copy) NSString* evaId;//id used for this wagenstand
@property (nonatomic, strong) NSString *request_date; // String, date used to request this wagenstand
@property (nonatomic) BOOL departure;

- (Train*) destinationForWaggon:(Waggon*)waggon;
- (NSArray*) joinedSectionsList;

- (NSInteger) indexOfWaggonForSection:(NSString*)section;
- (NSInteger) indexOfWaggonForWaggonNumber:(NSString*)number;

-(BOOL)isReversed;
-(void)reverse;
-(void)addTrainDirection;
-(void)parseRISTransport:(NSDictionary*)istformation;

+(NSString*)getTrainNumberForWagenstand:(Wagenstand*)wagenstand;
+(NSString*)getTrainTypeForWagenstand:(Wagenstand*)wagenstand;
+(NSString*)dateRequestStringForTimestamp:(NSTimeInterval)timestamp;


@end
