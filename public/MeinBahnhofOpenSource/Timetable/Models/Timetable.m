// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "Timetable.h"

#define kPastOffsetOneMinute 60

#define DEFAULT_REQUEST_HOURS 1

@interface Timetable()
@end

@implementation Timetable

static NSDate* initialSetupDate = nil;

-(instancetype)init{
    self = [super init];
    if(self){
        self.additionalRequestHours = DEFAULT_REQUEST_HOURS;
        if(!initialSetupDate){
            initialSetupDate = [NSDate date];
        }
    }
    return self;
}

- (void) initializeTimetableFromData:(NSData*)data
{
    NSArray *stops = [TimetableParser parseTimeTableFromData:data];
    
    if (!self.stops) {
        self.stops = [stops mutableCopy];
    } else {
        // integrate
        [self uniquelyMergeStops:stops];
    }

    self.arrivalStops = [self sortArrivalStops];
    self.departureStops = [self sortDepartureStops];
}

- (void) updateTimetableFromData:(NSData*)data
{
    if (!self.stops || self.stops.count == 0) {
        return;
    }
    
    NSMutableArray *stopsToAdd = [NSMutableArray array];
    
    NSArray *changes = [TimetableParser parseChangesForTimetable:data];
    
    for (Stop *changedStop in changes) {
        // A change might introduce a new Stop as a replacement for a cancelled one
        // The replacement might be too far in the future since the fchg and rchg Requests
        // are time independent
        BOOL hasRef = NO;
        BOOL hasUpdatedExisting = NO;
        BOOL hasAddedMissingStop = NO;
        if (changedStop.oldTransportCategory) {
            hasRef = YES;
            [stopsToAdd addObject:changedStop];
        }
        
        for (Stop *stop in self.stops) {
            if ([changedStop.stopId isEqualToString:stop.stopId]) {
                hasUpdatedExisting = YES;
                // update the transport category
                stop.changedTransportCategory = changedStop.transportCategory;
                
                // merge information from two events
                
                if (changedStop.departure) {
                    [self updateEvent:stop.departure withNewEvent:changedStop.departure];
                }
                
                if (changedStop.arrival) {
                    [self updateEvent:stop.arrival withNewEvent:changedStop.arrival];
                    
                }
            }
        }
        
        BOOL extraTrain = changedStop.isExtraTourTrain;
        if(extraTrain && (changedStop.arrival.eventIsCanceled || changedStop.departure.eventIsCanceled)){
            NSLog(@"ignore canceled sonderfahrt");
            extraTrain = NO;
        }
        
        if(!hasRef && !hasUpdatedExisting && (changedStop.isReplacementTrain || extraTrain)){
            [stopsToAdd addObject:changedStop];
            hasAddedMissingStop = YES;
            if(extraTrain){
                NSLog(@"adding sonderfahrt!");
            }
            NSLog(@"added a stop %@ %@ %@ %@ %@ %@, %@ %@ ",changedStop.stopId,changedStop.transportCategory.transportCategoryType,changedStop.transportCategory.transportCategoryNumber,changedStop.arrival.formattedTime,changedStop.departure.formattedTime,changedStop.arrival.station,changedStop.departure.station,changedStop);
        }
        /* //code below detects missing stops from the change data that are in our future time window
        if(!hasUpdatedExisting && !hasAddedMissingStop && !hasRef){
            //stop not found in existing plan data... is this a delayed train?
            double now = [[Timetable now] timeIntervalSince1970];
            double futureLimit = self.lastRequestedDate.timeIntervalSince1970;
            double timestamp = 0;
            if(changedStop.departure){
                timestamp = changedStop.departure.changedTimestamp;
                if(timestamp >= now && timestamp < futureLimit){
                    //not yet departed...
                    NSLog(@"TODO: missing stop with a change in departure: %@, %f",changedStop.stopId, changedStop.departure.changedTimestamp);
                }
            }
            if(changedStop.arrival){
                timestamp = changedStop.arrival.changedTimestamp;
                if(timestamp >= now && timestamp < futureLimit){
                    //not yet arrived...
                    NSLog(@"TODO: missing stop with a change in arrival:  %@",changedStop.stopId);
                }
            }
        }*/
        
    }
    
    // check if the stop was already added
    [self uniquelyMergeStops:stopsToAdd];
    
    // sort the stops and divide them into separate lists
    self.arrivalStops = [self sortArrivalStops];
    self.departureStops = [self sortDepartureStops];
}

-(void)generateTestdata{
    NSLog(@"generating testdata for timetable...");
    self.lastRequestedDate = [Timetable now];
    Stop* stop = [[Stop alloc] init];
    stop.stopId = @"12345";
    TransportCategory* tc = [[TransportCategory alloc] init];
    tc.transportCategoryType = @"ICE";
    tc.transportCategoryNumber = @"11111";
    stop.transportCategory = tc;
    Event* event = [[Event alloc] init];
    event.timestamp = [NSDate timeIntervalSinceReferenceDate]+60*60;
    event.formattedTime = @"12:00";
    event.originalPlatform = @"1";
    event.stations = @[@"Dresden",@"München"];
    stop.arrival = event;
    stop.departure = event;
    self.stops = [NSMutableArray arrayWithCapacity:1];
    [self.stops addObject:stop];
    self.arrivalStops = @[ stop ];
    self.departureStops = @[ stop ];
}


+(NSDate*)now{
    if(TIMETABLE_USE_SIMULATED_DATE){
        NSTimeInterval t = -[initialSetupDate timeIntervalSinceNow];
        NSDate* d = [NSDate date];
        NSCalendar* calendar = [[NSCalendar alloc]
                    initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        [calendar setLocale:[NSLocale localeWithLocaleIdentifier:@"de"]];
        NSDateComponents *components = [calendar components:NSCalendarUnitHour|NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:d];
        [components setValue:0 forComponent:NSCalendarUnitSecond];
        [components setValue:0 forComponent:NSCalendarUnitMinute];
        [components setValue:9 forComponent:NSCalendarUnitHour];
        [components setValue:12 forComponent:NSCalendarUnitDay];
        [components setValue:5 forComponent:NSCalendarUnitMonth];
        [components setValue:2020 forComponent:NSCalendarUnitYear];
        d = [calendar dateFromComponents:components];
        NSDate* res = [d dateByAddingTimeInterval:t];
        NSLog(@"now fixed to %@ plus %f seconds: %@",d,t,res);
        return res;
    } else {
        return [NSDate date];
    }
}

- (void) uniquelyMergeStops:(NSArray*)newStops
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NONE %@.stopId == stopId", self.stops];
    NSArray *filteredArray = [newStops filteredArrayUsingPredicate:predicate];
    [self.stops addObjectsFromArray:filteredArray];
}

- (void) updateEvent:(Event*)oldEvent withNewEvent:(Event*)newEvent
{
    oldEvent.changedTimestamp = newEvent.changedTimestamp;
    oldEvent.changedStations = newEvent.changedStations;
    oldEvent.messages = newEvent.messages;
    oldEvent.changedPlatform = newEvent.changedPlatform;
    oldEvent.changedStatus = newEvent.changedStatus;
    if (newEvent.wings.count > 0) {
        oldEvent.wings = newEvent.wings;
    }
}

- (void) clearTimetable;
{
    self.stops = nil;//[@[] mutableCopy];
    self.arrivalStops = @[];
    self.departureStops = @[];
    self.additionalRequestHours = DEFAULT_REQUEST_HOURS;
}

- (BOOL) hasTimetableData
{
    return self.stops && self.stops.count > 0;
}

- (NSArray*) sortArrivalStops
{
    return [self sortStops:NO];
}

- (NSArray*) sortDepartureStops
{
    return [self sortStops:YES];
}

- (NSArray*) availablePlatformsForDeparture:(BOOL)departure
{
    NSArray *stops = departure ? [self departureStops] : [self arrivalStops];
    
    NSMutableArray *platformsArray = [NSMutableArray array];
    for (Stop *stop in stops) {
        Event *event = [stop eventForDeparture:departure];
        NSString* finalPlatform = event.actualPlatformNumberOnly;
        if (![platformsArray containsObject:finalPlatform]) {
            [platformsArray addObject:finalPlatform];
        }
    }
    
    platformsArray = [[platformsArray sortedArrayUsingComparator:^(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }] mutableCopy];
    
    [platformsArray insertObject:@"Alle" atIndex:0];
    
    return platformsArray;
}

- (NSArray*) availableTransportTypesForDeparture:(BOOL)departure
{
    NSArray *stops = departure ? [self departureStops] : [self arrivalStops];
    
    NSMutableArray *transportTypesArray = [NSMutableArray array];
    for (Stop *stop in stops) {
        if (stop.transportCategory.transportCategoryType && ![transportTypesArray containsObject:stop.transportCategory.transportCategoryType]) {
            [transportTypesArray addObject:stop.transportCategory.transportCategoryType];
        }
    }
    
    transportTypesArray = [[transportTypesArray sortedArrayUsingComparator:^(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }] mutableCopy];
    
    [transportTypesArray insertObject:@"Alle" atIndex:0];
    
    return transportTypesArray;
}

- (NSArray*) sortStops:(BOOL)departure
{
    double now = [[Timetable now] timeIntervalSince1970];
    double futureLimit = self.lastRequestedDate.timeIntervalSince1970;
    NSMutableArray *filteredStops = [NSMutableArray array];
    
    for (Stop *stop in self.stops) {
        double timestamp = 0;
        if (departure) {
            timestamp = stop.departure.timestamp+[stop.departure rawDelay];
        } else {
            timestamp = stop.arrival.timestamp+[stop.arrival rawDelay];
        }
        
        //if ((timestamp+60) < now
        if (timestamp < now
            || timestamp > futureLimit) {
            // too old OR to far in the future
        } else {
            [filteredStops addObject:stop];
        }
    }
    
    NSString *sortKeyTime = departure ? @"departure.timestamp" : @"arrival.timestamp";
    NSString *sortKeyPlatform = departure ? @"departure.actualPlatform" : @"arrival.actualPlatform";
    NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:sortKeyTime ascending:YES],
                          [NSSortDescriptor sortDescriptorWithKey:sortKeyPlatform ascending:YES]];
    return [[filteredStops copy] sortedArrayUsingDescriptors:sortDescriptors];
}

@end
