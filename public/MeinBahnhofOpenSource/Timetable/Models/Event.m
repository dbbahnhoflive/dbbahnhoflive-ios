// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "Event.h"
#import "Stop.h"
#import <UIKit/UIKit.h>

@implementation Event


- (instancetype) init
{
    if (self = [super init]) {
        //self.timestamp = 0.0;
        //self.changedTimestamp = 0.0;
    }
    return self;
}

- (NSString*) stationsAsString:(NSArray*)stations
{
    if (stations && stations.count > 0) {
        NSString *firstStop = [stations firstObject];
        if (firstStop.length == 0) {
            return @"-";
        }
        return [stations componentsJoinedByString:@", "];
    }
    return @"-";
}

- (NSString*) formattedExpectedTime
{
    NSInteger delay = [self roundedDelay];
    if(delay == 0){
        return self.formattedTime;
    }
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:self.changedTimestamp];
    NSCalendar *calendar  = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour| NSCalendarUnitMinute) fromDate:date];
    NSInteger hour = [components hour];
    NSInteger minutes = [components minute];
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)hour, (long)minutes];
}

- (NSInteger) roundedDelay
{
    if (self.timestamp > 0 && self.changedTimestamp > 0) {
        double deltaTimestamp = (self.changedTimestamp-self.timestamp)/60;
        return deltaTimestamp;
    }
    return 0;
}

- (double) rawDelay
{
    if (self.timestamp > 0 && self.changedTimestamp > 0) {
        return self.changedTimestamp-self.timestamp;
    }
    return 0.0;
}

- (BOOL) hasChanges
{    
    return [self roundedDelay] != 0 || self.changedPlatform != nil || self.changedStations.count > 0;
}

- (BOOL) messagesAvailable
{
    return self.messages && self.messages.count > 0;
}


- (NSArray*) currentStations
{
    return (!self.eventIsCanceled && self.changedStations.count > 0) ? self.changedStations : self.stations;
}

/*- (id) actualStatus
{
    return null != self.changedStatus ? self.changedStatus : self.status
}*/

- (double) actualTime
{
    return self.timestamp; //nil != this.changedTime ? this.changedTime : this.time
}

- (NSString*) actualPlatform
{
    return nil != self.changedPlatform ? self.changedPlatform : self.originalPlatform;
}
-(NSString*)actualPlatformNumberOnly{
    //remove all non numbers, so that "5A-G" will be transformed to "5".
    NSString* p = [self actualPlatform];
    return [p stringByReplacingOccurrencesOfString:@"[^0-9]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, p.length)];
}

- (NSString*) originalPlatform
{
    return _originalPlatform.length > 0 ? _originalPlatform : @"k.A.";
}

- (NSString*) changedPlatform
{
    return nil != _changedPlatform ? _changedPlatform : nil;
}

- (NSString*) actualStations
{
    NSArray* stations = [self actualStationsArray];
    return [self stationsAsString:stations];
}

-(NSArray*)actualStationsArray{
    NSMutableArray *stations;
    // check if we have update stations and the result has at least 1 station
    if (self.changedStations && self.changedStations.count > 0) {
        stations = [self.changedStations mutableCopy];
    } else {
        stations = [self.stations mutableCopy];
    }
    /*
    if (!self.departure) {
        [stations removeObjectAtIndex:0];
    } else {
        [stations removeLastObject];
    }*/
    return stations;
}


- (NSString*) actualStation
{
    NSString *station = @"";
    if (self.departure) {
        station = [self.currentStations lastObject];
    } else {
        station = [self.currentStations firstObject];
    }
    if(self.plannedDistantEndpoint.length > 0){
        return self.plannedDistantEndpoint;
    }
    
    if(station.length == 0 && (!self.eventIsCanceled && self.changedStations.count > 0)){
        //fallback for the case where the train was not cancelled but the changed stations is empty. Display the destination from the plan data.
        if (self.departure) {
            station = [self.stations lastObject];
        } else {
            station = [self.stations firstObject];
        }
    }
    
    return station;
}

- (NSArray*) buildEventIrisMessages
{
    
    NSMutableArray *irisEventMessages = [NSMutableArray array];
    
    if(self.plannedDistantEndpoint.length > 0){
        //is this different from the last station?
        NSString *station = @"";
        if (self.departure) {
            station = [self.currentStations lastObject];
        } else {
            station = [self.currentStations firstObject];
        }
        if(![self.plannedDistantEndpoint isEqualToString:station]){
            [irisEventMessages addObject:[NSString stringWithFormat:@"Ab %@ weiter in Richtung %@.",station,self.plannedDistantEndpoint]];
        }
    }
    
    if  (self.eventIsCanceled) {
        self.shouldShowRedWarnIcon = YES;
        NSString *changedPlatformMessage = @"Dieser Zug fällt heute aus";
        [irisEventMessages addObject:changedPlatformMessage];
        // if the trip was cancelled, this is the only relevant message
        return irisEventMessages;
    }
    
    if(self.eventIsAdditional){
        self.shouldShowRedWarnIcon = YES;
        NSString *changedPlatformMessage = @"Zusätzlicher Halt";
        [irisEventMessages addObject:changedPlatformMessage];
    }
    
    if (self.changedPlatform) {
        self.shouldShowRedWarnIcon = YES;
        NSString *changedPlatformMessage = [NSString stringWithFormat: @"Heute Gleis %@", self.changedPlatform];
        [irisEventMessages addObject:changedPlatformMessage];
    }
    
    if ([self roundedDelay] > 0) {
        NSString* caString = @"ca.";
        if(UIAccessibilityIsVoiceOverRunning()){
            caString = @"Circa";
        }
        NSString *delayMessage = [NSString stringWithFormat:@"%@ %ld Minuten später", caString, (long)[self roundedDelay]];
        [irisEventMessages addObject:delayMessage];
    }
    
    if ([self changedStations].count > 0) {
        NSString *addedStationsMessage =  [self calculateAddedStations];
        NSString *missingStationsMessage = [self calculateMissingStations];
        
        if (addedStationsMessage) {
            self.shouldShowRedWarnIcon = YES;
            [irisEventMessages addObject:addedStationsMessage];
        }
        if (missingStationsMessage) {
            self.shouldShowRedWarnIcon = YES;
            [irisEventMessages addObject:missingStationsMessage];
        }
    }

    return irisEventMessages;
}

- (NSArray*) qosMessages
{
    NSMutableArray *messages = [NSMutableArray array];
    
    if (self.eventIsCanceled) {
        return messages;
    }
    
    for (Message *message in self.messages) {
        if (message && !message.revoked && message.displayMessage && ![messages containsObject:message.displayMessage]) {
            [messages addObject:message.displayMessage];
        }
    }
    return messages;
}

- (BOOL) eventIsCanceled
{
    if (self.plannedStatus
        && [self.plannedStatus isEqualToString:@"c"]) {
        return YES;
    }
    if (self.changedStatus
        && [self.changedStatus isEqualToString:@"c"]) {
            return YES;
    }
    return NO;
}
- (BOOL) eventIsAdditional
{
    if (self.plannedStatus
        && [self.plannedStatus isEqualToString:@"a"]) {
        return YES;
    }
    return NO;
}


- (NSString*) cancelledMessage
{
    if ([self eventIsCanceled]) {
        return @"Dieser Zug fällt heute aus";

        /*      
        if ([self.changedStatus isEqualToString:@"a"]) {
            return @"Ersatzzug";
        }*/
    }
    return nil;
}

- (NSString *) calculateMissingStations
{
    NSMutableArray *missingStations = [NSMutableArray array];
    for (NSString *station in [self stations]) {
        if (station.length > 0 && ![[self changedStations] containsObject:station]) {
            // additional Station
            [missingStations addObject:station];
        }
    }
    if (missingStations.count > 0) {
        return [NSString stringWithFormat:@"Hält nicht in %@", [missingStations componentsJoinedByString:@", "]];
    }
    return nil;
}

- (NSString *) calculateAddedStations
{
    NSMutableArray *additionalStations = [NSMutableArray array];
    
    for (NSString *changedStation in [self changedStations]) {
        if (changedStation.length > 0 && ![[self stations] containsObject:changedStation]) {
            // additional Station
            [additionalStations addObject:changedStation];
        }
    }
    
    if (additionalStations.count > 0) {
        return [NSString stringWithFormat:@"Hält auch in %@", [additionalStations componentsJoinedByString:@", "]];
    }
    return nil;
}

-(void)updateComposedIrisWithStop:(Stop *)stop{
    self.shouldShowRedWarnIcon = NO;
    NSMutableArray *extraMessage;
    extraMessage = [[self buildEventIrisMessages] mutableCopy];
    NSArray* qosMessages = [self qosMessages];
    if(qosMessages.count > 0){
        self.shouldShowRedWarnIcon = YES;
        [extraMessage addObjectsFromArray:[self qosMessages]];
    }
    
    NSString *replacementTrainMessage = [stop replacementTrainMessage:self.lineIdentifier];
    if (replacementTrainMessage && !self.eventIsCanceled) {
        self.shouldShowRedWarnIcon = YES;
        [extraMessage addObject:replacementTrainMessage];
    }
    
    self.hasOnlySplitMessage = extraMessage.count == 0;
    if (stop.referenceSplitMessage) {
        [extraMessage addObject:stop.referenceSplitMessage];
    }
    
    NSString* divider = @" +++ ";
    if(UIAccessibilityIsVoiceOverRunning()){
        divider = @". ";
    }
    NSString *composedIris = [extraMessage componentsJoinedByString:divider];
    
    self.composedIrisMessage = composedIris;    
}

-(BOOL)sameDayEvent:(Event*)event{
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:self.timestamp];
    NSDate* dateOther = [NSDate dateWithTimeIntervalSince1970:event.timestamp];
    NSCalendar *calendar  = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitDay| NSCalendarUnitMonth) fromDate:date];
    NSDateComponents *componentsOther = [calendar components:(NSCalendarUnitDay| NSCalendarUnitMonth) fromDate:dateOther];
    return components.day == componentsOther.day && components.month == componentsOther.month;
}

-(NSArray<NSString*>*)stationListWithCurrentStation:(NSString*)currentStation{
    return self.departure ? [@[currentStation] arrayByAddingObjectsFromArray:self.actualStationsArray] : [self.actualStationsArray arrayByAddingObject:currentStation];
}
@end
