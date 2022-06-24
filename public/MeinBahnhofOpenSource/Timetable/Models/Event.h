// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import "Message.h"

enum EventType {
    ARRIVAL,
    DEPARTURE
};

@class Stop;


/*!
 *  @brief An event (arrival or departure) that is part of a stop.
 */
@interface Event : NSObject

@property (nonatomic, weak) Stop* stop;

/*!
 *  @brief  The time of the arrival/departure (raw)
 */
@property (nonatomic, assign) double timestamp;
/*!
 *  @brief  The changed time of the arrival/departure (raw)
 */
@property (nonatomic, assign) double changedTimestamp;
/*!
 *  @brief  The reference timestamp of the delay
 */
//@property (nonatomic, assign) double delayTimestamp;
/*!
 *  @brief  The delay formatted to display
 */
@property (nonatomic, assign) double delay;
/*!
 *  @brief  Formatted time to display
 */
@property (nonatomic, strong) NSString *formattedTime;

/*!
 *  @brief  List of stations according to the Stop.
 */
@property (nonatomic, strong) NSArray *stations;
/*!
 *  @brief  List of changed stations according to the Stop.
 */
@property (nonatomic, strong) NSArray *changedStations;
/*!
 *  @brief  final or first station of the Stop
 */
@property (nonatomic, strong) NSString *station;


@property (nonatomic, strong) NSString* plannedDistantEndpoint;


/*!
 *  @brief  Array of reference Events if a train splits.
 */
@property (nonatomic, strong) NSArray *wings;
/*!
 *  @brief  Assigned original platform of the Train.
 */
@property (nonatomic, strong) NSString *originalPlatform;
/*!
 *  @brief  Assigned changed platform of the Train.
 */
@property (nonatomic, strong) NSString *changedPlatform;
/*!
 *  @brief If not null, this field holds the Line number (e.g. S 2).
 */
@property (nonatomic, strong) NSString *lineIdentifier;
/*!
 *  @brief If YES, this Event should not be shown to the User.
 */
@property (nonatomic, assign) BOOL hidden;
/*!
 *  @brief  A list of attached Messages.
 */
@property (nonatomic, strong) NSArray *messages;
/*!
 *  @brief  Indicates if there are messages to display.
 */
@property (nonatomic, assign) BOOL messagesAvailable;

@property (nonatomic, strong) NSString *plannedStatus;
@property (nonatomic, strong) NSString *changedStatus;

@property (nonatomic, strong) NSString *composedIrisMessage;
@property (nonatomic, strong) NSAttributedString *composedIrisMessageAttributed;

//@property (nonatomic, strong) NSString* evaId;//optional evaId where is trainRecord is available
@property (nonatomic, assign) BOOL departure;

@property (nonatomic, assign) BOOL hasOnlySplitMessage;
@property (nonatomic, assign) BOOL shouldShowRedWarnIcon;

@property (nonatomic, strong) NSString* journeyID;//stored after successful ris:journeys request


- (NSString *) actualStation;
- (NSString *) actualStations;
- (NSArray *) actualStationsArray;
- (NSString *) actualPlatform;
- (NSString *) actualPlatformNumberOnly;
- (NSString*) formattedExpectedTime;
- (NSInteger) roundedDelay;

- (NSArray*) currentStations;

- (NSArray*) buildEventIrisMessages;
- (NSArray*) qosMessages;

- (BOOL) eventIsCanceled;
- (BOOL) eventIsAdditional;

- (double) rawDelay;
- (BOOL) hasChanges;

-(void) updateComposedIrisWithStop:(Stop*)stop;

-(BOOL)sameDayEvent:(Event*)event;

-(NSArray<NSString*>*)stationListWithCurrentStation:(NSString*)currentStation;
@end
