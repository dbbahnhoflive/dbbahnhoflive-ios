// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import "Event.h"
#import "Message.h"
#import "TransportCategory.h"

@interface Stop : NSObject

@property (nonatomic, strong) NSString* stopId;

@property (nonatomic, strong) TransportCategory* transportCategory;
@property (nonatomic, strong) TransportCategory* changedTransportCategory;
@property (nonatomic, strong) TransportCategory* oldTransportCategory;
@property (nonatomic) BOOL isReplacementTrain;
@property (nonatomic) BOOL isExtraTourTrain;

@property (nonatomic, strong) NSString *evaNumber;
@property (nonatomic, strong) Event *arrival;
@property (nonatomic, strong) Event *departure;
@property (nonatomic, strong) Message *message;

@property (nonatomic, strong) NSString *junctionType;
@property (nonatomic, strong) NSString *stopIndex;

// this will be added in TimetableViewController if this stop is a Reference to another
@property (nonatomic, strong) NSString *referenceSplitMessage;

- (NSString*) formattedTransportType:(NSString*)lineIdentifier;
- (NSString*) replacementTrainMessage:(NSString*)lineIdentifier;
- (NSString*) changedTrainMessage:(NSString*)lineIdentifier;

- (Event*)eventForDeparture:(BOOL)departure;
- (NSDictionary*) requestParamsForWagenstandWithEvent:(Event*)event;

+(BOOL)stopShouldHaveTrainRecord:(Stop*)timetableStop;
@end
