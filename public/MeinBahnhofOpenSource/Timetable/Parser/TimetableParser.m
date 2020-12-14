// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "TimetableParser.h"

#define DB_DATE_FORMAT_FULL @"YYMMddHHmm"
#define DB_STATION_LIST_DELIMITER @"|"
#define kTimeFormatPattern @"%02ld:%02ld"

@implementation TimetableParser

static NSDateFormatter *formatter = nil;

+ (NSArray*) parseTimeTableFromData:(NSData*)data
{
    if (data) {
        
        NSError *error = nil;
        TBXML *xmlRootInstance = [TBXML tbxmlWithXMLData:data error:&error];
        
        if (!error) {
            return [TimetableParser parseStops:[xmlRootInstance rootXMLElement]];
        }
    }
    return nil;
}

+ (NSArray*) parseChangesForTimetable:(NSData*)data;
{
    if (data) {
        
        NSError *error = nil;
        TBXML *xmlRootInstance = [TBXML tbxmlWithXMLData:data error:&error];
        
        if (!error) {
            return [TimetableParser parseStops:[xmlRootInstance rootXMLElement]];
        }
    }
    return nil;
}

/**
 Parses the root Element of each Stop
 <s id="-3876736263946883288-1505270554-8">
	
 </s>
 **/
+ (NSArray*) parseStops:(TBXMLElement*)fromElement
{
    NSMutableArray *stops = [NSMutableArray array];
    TBXMLElement *firstChildStopElement = [TBXML childElementNamed:@"s" parentElement:fromElement];
    TBXMLElement *element = firstChildStopElement;
    
    while (element) {
        [stops addObject:[TimetableParser parseStopDetail:element]];
        element = element->nextSibling;
    }
    return stops;
}

/**
 Parses the content and Values of each journey.
 <s id="-3876736263946883288-1505270554-8">
	<tl f="F" t="p" o="80" c="ICE" n="1654"/>
	<ar pt="1505271037" pp="6" ppth="Dresden Hbf|Dresden-Neustadt|Riesa|Leipzig Hbf|Erfurt Hbf|Eisenach|Fulda"/>
	<dp pt="1505271044" pp="6" ppth="Frankfurt(M) Flughafen Fernbf|Mainz Hbf|Wiesbaden Hbf"/>
 </s>
 
 // only arrival = trip ends here
 // only departure = trip starts here
 // both = intermediate stop
 
 
 Planned Path. A sequence of station names separated by the pipe symbols (“|”).
 E.g.: “Mainz Hbf|Rüsselsheim|Frankfrt(M) Flughafen”.
 For arrival, the path indicates the stations that come before the current station. The first ele- ment then is the trip’s start station.
 For departure, the path indicates the stations that come after the current station. The last ele- ment in the path then is the trip’s destination station.
 Note that the current station is never included in the path (neither for arrival nor for departure).
 
 **/

+ (Stop*) parseStopDetail:(TBXMLElement*)fromElement
{
    @autoreleasepool {
        Stop *stop = [[Stop alloc] init];
        
        TBXMLElement *transportTypeElement = [TBXML childElementNamed:@"tl" parentElement:fromElement];
        TBXMLElement *arrivalElement = [TBXML childElementNamed:@"ar" parentElement:fromElement];
        TBXMLElement *departureElement = [TBXML childElementNamed:@"dp" parentElement:fromElement];
        
        TBXMLElement *refElement = [TBXML childElementNamed:@"ref" parentElement:fromElement];
        
        if (refElement) {
            TBXMLElement *oldTransportTypeElement = [TBXML childElementNamed:@"tl" parentElement:refElement];
            if (oldTransportTypeElement) {
                [stop setOldTransportCategory:[TimetableParser parseTransportCategoryFromElement:oldTransportTypeElement]];
            }
        }
        
        NSString *journeyId = [TBXML valueOfAttributeNamed:@"id" forElement:fromElement];
        [stop setStopId:journeyId];
        
        if (transportTypeElement) {
            [stop setTransportCategory:[TimetableParser parseTransportCategoryFromElement:transportTypeElement]];
            stop.isReplacementTrain = [TimetableParser isReplacementTrain:transportTypeElement];
            stop.isExtraTourTrain = [TimetableParser isExtraTourTrain:transportTypeElement];
        }
        
        if (arrivalElement) {
            Event *arrivalEvent = [TimetableParser parseEventFromElement: arrivalElement ofTypeDeparture:NO];
            if (arrivalEvent) {
                [stop setArrival:arrivalEvent];
            }
        }
        
        if (departureElement) {
            Event *departureEvent = [TimetableParser parseEventFromElement: departureElement ofTypeDeparture:YES];
            if (departureEvent) {
                [stop setDeparture:departureEvent];
            }
        }
        return stop;
    }
}

+ (NSDateFormatter*) cachedDateFormatter
{
    if (formatter == nil) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterFullStyle];
        [formatter setTimeStyle:NSDateFormatterFullStyle];
        [formatter setDateFormat:DB_DATE_FORMAT_FULL];
        [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    }
    return formatter;
}

+ (TransportCategory*) parseTransportCategoryFromElement:(TBXMLElement*)fromElement
{
    TransportCategory *transportCategory = [[TransportCategory alloc] init];
    NSString *transportCategoryType = [TBXML valueOfAttributeNamed:@"c" forElement:fromElement];
    NSString *transportCategoryNumber = @"";
    if ([transportCategoryType isEqualToString:@"S"] || [transportCategoryType isEqualToString:@"B"]) {
        transportCategoryNumber = [TBXML valueOfAttributeNamed:@"l" forElement:fromElement];
    } else {
        transportCategoryNumber = [TBXML valueOfAttributeNamed:@"n" forElement:fromElement];
    }
    
    NSString *transportCategoryGenericNumber = [TBXML valueOfAttributeNamed:@"l" forElement:fromElement];
    
    [transportCategory setTransportCategoryType:transportCategoryType];
    [transportCategory setTransportCategoryNumber:transportCategoryNumber];
    [transportCategory setTransportCategoryGenericNumber:transportCategoryGenericNumber];
    
    return transportCategory;
}
+(BOOL)isReplacementTrain:(TBXMLElement*)tlElement{
    NSString *tType = [TBXML valueOfAttributeNamed:@"t" forElement:tlElement];
    if([tType isEqualToString:@"e"]){
        return YES;
    }
    return NO;
}
+(BOOL)isExtraTourTrain:(TBXMLElement*)tlElement{
    NSString *tType = [TBXML valueOfAttributeNamed:@"t" forElement:tlElement];
    if([tType isEqualToString:@"s"]){
        return YES;
    }
    return NO;
}

+ (Event*) parseEventFromElement:(TBXMLElement*)fromElement ofTypeDeparture:(BOOL)departure
{
    NSString *stationsString = [[TBXML valueOfAttributeNamed:@"ppth" forElement:fromElement] gtm_stringByUnescapingFromHTML];
    NSString *distantEndpoint = [[TBXML valueOfAttributeNamed:@"pde" forElement:fromElement] gtm_stringByUnescapingFromHTML];
    NSString *changedStationsString = [[TBXML valueOfAttributeNamed:@"cpth" forElement:fromElement] gtm_stringByUnescapingFromHTML];
    NSString *platformString = [[TBXML valueOfAttributeNamed:@"pp" forElement:fromElement] gtm_stringByUnescapingFromHTML];
    NSString *changedPlatformString = [TBXML valueOfAttributeNamed:@"cp" forElement:fromElement];
    NSString *wingsReferenceEventString = [TBXML valueOfAttributeNamed:@"wings" forElement:fromElement];
    NSArray  *wingsTrips = [wingsReferenceEventString componentsSeparatedByString:DB_STATION_LIST_DELIMITER];
    NSString *hidden = [TBXML valueOfAttributeNamed:@"hi" forElement:fromElement];
    NSString *timestampString = [TBXML valueOfAttributeNamed:@"pt" forElement:fromElement]; // +0000 == has no abbreviation
    NSString *delayTimestampString = [TBXML valueOfAttributeNamed:@"ct" forElement:fromElement]; // +0000 == has no abbreviation
    NSString *plannedStatus = [TBXML valueOfAttributeNamed:@"ps" forElement:fromElement];
    NSString *changedStatus = [TBXML valueOfAttributeNamed:@"cs" forElement:fromElement];
    
    NSString *lineIdentifier = [TBXML valueOfAttributeNamed:@"l" forElement:fromElement];

    NSArray *messages = [TimetableParser parseMessageFromElement:fromElement];
    
    NSArray *stations = [[stationsString gtm_stringByUnescapingFromHTML] componentsSeparatedByString:DB_STATION_LIST_DELIMITER];
    NSArray *changedStations = [[changedStationsString gtm_stringByUnescapingFromHTML] componentsSeparatedByString:DB_STATION_LIST_DELIMITER];
    NSDate *date = [[TimetableParser cachedDateFormatter] dateFromString:timestampString];
    NSDate *delayDate = [[TimetableParser cachedDateFormatter] dateFromString:delayTimestampString];
    NSString *station = nil;
    
    if ([hidden isEqualToString:@"1"]) {
        return nil;
    }
    
    Event *event = [[Event alloc] init];
    [event setPlannedDistantEndpoint:distantEndpoint];
    [event setHidden:[hidden isEqualToString:@"1"]];
    [event setWings:wingsTrips];
    [event setPlannedStatus:plannedStatus];
    [event setChangedStatus:changedStatus];
    [event setOriginalPlatform: platformString];
    [event setChangedPlatform:changedPlatformString];
    [event setStation:station];
    [event setStations:stations];
    [event setChangedStations:changedStations];
    [event setMessages:messages];
    [event setLineIdentifier:lineIdentifier];
    [event setTimestamp:[date timeIntervalSince1970]];
    [event setDeparture:departure];
    
    if (delayDate) {
        [event setChangedTimestamp:[delayDate timeIntervalSince1970]];
    }
    
    if (date) {
        NSCalendar *calendar  = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:(NSCalendarUnitHour| NSCalendarUnitMinute) fromDate:date];
        NSInteger hour = [components hour];
        NSInteger minutes = [components minute];
        [event setFormattedTime:[NSString stringWithFormat:kTimeFormatPattern, (long)hour, (long)minutes]];
    }
        
    return event;
}

/*!
 *  @brief  This method parses the Message Element of an Event
 *
 *  @param fromElement fromElement
 *
 *  Message-Types
 *  h HIM message (generated through the Hafas Information Manager).
 *  q QUALITY CHANGE A message about a quality change.
 *  f FREE A free text message.
 *  d CAUSE OF DELAY A message about the cause of a delay.
 ￼*  i IBIS An IBIS message (generated from IRIS-AP).
 *  u UNASSIGNED IBIS MESSAGE An IBIS message (generated from IRIS-AP) not yet assigned to a train.
 *  r DISRUPTION A major disruption.
 *  c CONNECTION A connection.
 *
 *  @return Currently this only returns TRUE, if one or more messages are available
 */

+ (NSArray*) parseMessageFromElement:(TBXMLElement*)fromElement
{
    NSMutableArray *messagesArray = [NSMutableArray array];
    NSArray *relevantCodes = @[@80, @82, @83, @84, @85, @86, @87, @88, @89, @90, @91];

    TBXMLElement *messageElement = [TBXML childElementNamed:@"m" parentElement:fromElement];
    while (messageElement) {
        
        NSString *messageId         = [TBXML  valueOfAttributeNamed:@"id" forElement:messageElement];
        NSString *messageType       = [TBXML  valueOfAttributeNamed:@"t" forElement:messageElement];
        NSString *validFrom         = [TBXML  valueOfAttributeNamed:@"from" forElement:messageElement];
        NSString *validTo           = [TBXML  valueOfAttributeNamed:@"to" forElement:messageElement];
        NSUInteger code             = [[TBXML valueOfAttributeNamed:@"c" forElement:messageElement] integerValue];
        NSString *internalText      = [TBXML  valueOfAttributeNamed:@"int" forElement:messageElement];
        NSString *externalText      = [TBXML  valueOfAttributeNamed:@"ext" forElement:messageElement];
        NSString *category          = [TBXML  valueOfAttributeNamed:@"cat" forElement:messageElement];
        NSUInteger externalCategory = [[TBXML valueOfAttributeNamed:@"ec" forElement:messageElement] integerValue];
        NSString *timestamp         = [TBXML  valueOfAttributeNamed:@"ts" forElement:messageElement];
        NSString *priority          = [TBXML  valueOfAttributeNamed:@"pr" forElement:messageElement];
        NSString *owner             = [TBXML  valueOfAttributeNamed:@"o" forElement:messageElement];//not used
        NSUInteger deleted          = [[TBXML valueOfAttributeNamed:@"del" forElement:messageElement] integerValue];

        Message *message = [[Message alloc]init];
        message.messageId = messageId;
        message.type = messageType;
        message.validFrom = validFrom;
        message.validTo = validTo;
        message.code = code;
        message.internalText = internalText;
        message.externalText = externalText;
        message.category = category;
        message.externalCategory = externalCategory;
        message.priority = priority;
        message.owner = owner;
        message.deleted = deleted;
        
        NSDate *parsedTimestamp = [NSDateFormatter dateFromString:timestamp forPattern:DB_DATE_FORMAT_FULL];
        if (parsedTimestamp) {
            message.timestamp = [parsedTimestamp timeIntervalSince1970];
        } else {
            message.timestamp = -1.0;
        }
        
        if ([messageType isEqualToString:@"q"]) {
            NSNumber *messageCode = @(code);
            BOOL messageDeleted = deleted  == 1;
            
            if ([relevantCodes containsObject:messageCode] && !messageDeleted) {
                message.displayMessage = [TimetableParser messageForKey:[messageCode stringValue]];
                [messagesArray addObject:message];
            }
        }
        
        // get next Message Element
        messageElement = [TBXML nextSiblingNamed:@"m" searchFromElement:messageElement];
    };
    
    // check if messages have been revoked
    NSArray *reversedMessagesArray = [[messagesArray reverseObjectEnumerator] allObjects];
    for (Message *message in reversedMessagesArray) {
        NSString *code = [NSString stringWithFormat:@"%d",(int)message.code];
        NSArray *revocationCodes = [TimetableParser revocationCodesForKey:code];
        
        for (NSNumber *revocationCode in revocationCodes) {
            for (Message *revocableMessage in messagesArray) {
                if (revocableMessage.code == [revocationCode integerValue]
                    && message != revocableMessage
                    && (revocableMessage.timestamp <= message.timestamp)) {
                    revocableMessage.revoked = YES;
                }
            }
        }
    }
    
    return messagesArray;
}

+ (NSString*)messageForKey:(NSString*)key
{
    NSDictionary *messages = @{
      @"80": @"Andere Reihenfolge der Wagen",
      @"82": @"Mehrere Wagen fehlen",
      @"83": @"Fehlender Zugteil",
      @"85": @"Ein Wagen fehlt",
      @"86": @"Gesamter Zug ohne Reservierung",
      @"87": @"Einzelne Wagen ohne Reservierung",
      @"90": @"Kein gastronomisches Angebot",
      @"91": @"Eingeschränkte Fahrradbeförderung"
      };
    
    return [messages objectForKey:key];
}

+ (NSArray*) revocationCodesForKey:(NSString*)key
{
    NSDictionary *revoke = @{
                             @"84": @[@80,@82,@83,@85],
                             @"88": @[@80,@82,@83,@85,@86,@87,@90,@91,@92,@93,@94,@96,@97,@98],
                             @"89": @[@86,@87]
                             };
    return [revoke objectForKey:key];
}


@end
