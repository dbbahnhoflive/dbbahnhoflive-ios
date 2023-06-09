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

- (void) initializeTimetableFromData:(NSData*)data evaNumber:(NSString *)evaNumber
{
    NSArray *stops = [TimetableParser parseTimeTableFromData:data evaNumber:evaNumber];
    
    if (!self.stops) {
        self.stops = [stops mutableCopy];
    } else {
        // integrate
        [self uniquelyMergeStops:stops];
    }

    self.arrivalStops = [self sortArrivalStops];
    self.departureStops = [self sortDepartureStops];
}

- (void) updateTimetableFromData:(NSData*)data evaNumber:(NSString *)evaNumber
{
    if (!self.stops || self.stops.count == 0) {
        return;
    }
    
    NSMutableArray *stopsToAdd = [NSMutableArray array];
    
    NSArray *changes = [TimetableParser parseChangesForTimetable:data evaNumber:evaNumber];
    //NSLog(@"checking for unknown changes between %@ and %@",[Timetable now],self.lastRequestedDate);
    
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
                
                if (changedStop.departureEvent) {
                    [self updateEvent:stop.departureEvent withNewEvent:changedStop.departureEvent];
                }
                
                if (changedStop.arrivalEvent) {
                    [self updateEvent:stop.arrivalEvent withNewEvent:changedStop.arrivalEvent];
                    
                }
            }
        }
        
        BOOL extraTrain = changedStop.isExtraTourTrain;
        if(extraTrain && (changedStop.arrivalEvent.eventIsCanceled || changedStop.departureEvent.eventIsCanceled)){
            NSLog(@"ignore canceled sonderfahrt");
            extraTrain = NO;
        }
        
        if(!hasRef && !hasUpdatedExisting && (changedStop.isReplacementTrain || extraTrain)){
            [stopsToAdd addObject:changedStop];
            hasAddedMissingStop = YES;
            if(extraTrain){
                NSLog(@"adding sonderfahrt!");
            }
            NSLog(@"added a stop %@ %@ %@ %@ %@ %@, %@ %@ ",changedStop.stopId,changedStop.transportCategory.transportCategoryType,changedStop.transportCategory.transportCategoryNumber,changedStop.arrivalEvent.formattedTime,changedStop.departureEvent.formattedTime,changedStop.arrivalEvent.station,changedStop.departureEvent.station,changedStop);
        }
        if(!hasUpdatedExisting && !hasAddedMissingStop && !hasRef){
            if((changedStop.arrivalEvent.eventIsAdditional || changedStop.departureEvent.eventIsAdditional) && (!changedStop.arrivalEvent.eventIsCanceled && !changedStop.departureEvent.eventIsCanceled)){
                [stopsToAdd addObject:changedStop];
                hasAddedMissingStop = YES;
                NSLog(@"added this train! %@",changedStop.stopId);
            } 
        }
        //code below detects missing stops from the change data that are in our future time window
        /*
        if(!hasUpdatedExisting && !hasAddedMissingStop && !hasRef){
            double now = [[Timetable now] timeIntervalSince1970];
            double futureLimit = self.lastRequestedDate.timeIntervalSince1970;
            double timestamp = 0;
            if(changedStop.departure && !changedStop.departure.eventIsCanceled){
                timestamp = changedStop.departure.changedTimestamp;
                if(timestamp >= now && timestamp < futureLimit){
                    //not yet departed...
                    NSLog(@"TODO: missing stop with a change in departure: %@, %@,%@",changedStop.stopId, [NSDate dateWithTimeIntervalSince1970:changedStop.departure.changedTimestamp],changedStop.evaNumber);
                    
                }
//                 else {
//                    double timestamp2 = changedStop.departure.timestamp;
//                    if(timestamp != 0 || timestamp2 != 0){
//                        NSLog(@"TODO: missing departure stop, additional train? %@, %@,%@,%@,%@,  %@, %@",changedStop.stopId,changedStop.departure.formattedTime,changedStop.departure.lineIdentifier,changedStop.transportCategory.transportCategoryType,changedStop.transportCategory.transportCategoryNumber, [NSDate dateWithTimeIntervalSince1970:timestamp], [NSDate dateWithTimeIntervalSince1970:timestamp2]);
//                    } else {
//                        //ignore this change, contains no time information
//                    }
                }
            }
            if(changedStop.arrival && !changedStop.arrival.eventIsCanceled){
                timestamp = changedStop.arrival.changedTimestamp;
                if(timestamp >= now && timestamp < futureLimit){
                    //not yet arrived...
                    if(changedStop.departure.changedTimestamp >= futureLimit){
                        //this an early arriving train with plan in the future, ignore this one
                        NSLog(@"ignore a missing arrival from an early train");
                    } else {
                        NSLog(@"TODO: missing stop with a change in arrival:  %@, %@,%@",changedStop.stopId,[NSDate dateWithTimeIntervalSince1970:timestamp],changedStop.evaNumber);
                    }
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
    event.stop = stop;
    event.timestamp = [NSDate timeIntervalSinceReferenceDate]+60*60;
    event.formattedTime = @"12:00";
    event.originalPlatform = @"1";
    event.stations = @[@"Dresden",@"München"];
    stop.arrivalEvent = event;
    stop.departureEvent = event;
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
        [components setValue:10 forComponent:NSCalendarUnitHour];
        [components setValue:18 forComponent:NSCalendarUnitDay];
        [components setValue:10 forComponent:NSCalendarUnitMonth];
        [components setValue:2021 forComponent:NSCalendarUnitYear];
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
    [oldEvent updateComposedIrisWithStop:oldEvent.stop];
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
        //NOTE: stops that are hidden will have timestamp=0 -> they are not displayed!
        if (departure) {
            if(!stop.departureEvent.isHidden){
                timestamp = stop.departureEvent.timestamp+[stop.departureEvent rawDelay];
            }
        } else {
            if(!stop.arrivalEvent.isHidden){
                timestamp = stop.arrivalEvent.timestamp+[stop.arrivalEvent rawDelay];
            }
        }
        
        //if ((timestamp+60) < now
        if (timestamp < now
            || timestamp > futureLimit) {
            // too old OR to far in the future
        } else {
            [filteredStops addObject:stop];
        }
    }
    
    NSString *sortKeyTime = departure ? @"departureEvent.timestamp" : @"arrivalEvent.timestamp";
    NSString *sortKeyPlatform = departure ? @"departureEvent.actualPlatform" : @"arrivalEvent.actualPlatform";
    NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:sortKeyTime ascending:YES],
                          [NSSortDescriptor sortDescriptorWithKey:sortKeyPlatform ascending:YES]];
    return [[filteredStops copy] sortedArrayUsingDescriptors:sortDescriptors];
}

@end
