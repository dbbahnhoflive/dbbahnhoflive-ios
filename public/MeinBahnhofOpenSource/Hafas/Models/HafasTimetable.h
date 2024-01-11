// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import "HafasDeparture.h"

@class MBOPNVStation;

@interface HafasTimetable : NSObject

@property(nonatomic,strong) MBOPNVStation* opnvStationForFiltering;

@property (nonatomic, strong) NSArray<HafasDeparture*> *departureStops;
@property (nonatomic, strong) NSString *currentStopLocationId;
@property(nonatomic) BOOL includedSTrains;
@property (nonatomic, assign) NSInteger requestDuration;//in minutes
@property (nonatomic) BOOL isBusy;
@property (nonatomic) BOOL needsInitialRequest;
@property (nonatomic) BOOL hasError;

@property (nonatomic) BOOL includeLongDistanceTrains;

- (void)initializeTimetableFromArray:(NSArray<NSDictionary*> *)departures mergeData:(BOOL)merge date:(NSDate*)loadingDate;
- (NSArray*) availableTransportTypes;
-(NSDate *)lastRequestedDate;

@end
