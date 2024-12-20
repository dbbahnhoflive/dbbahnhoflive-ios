// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBTrainJourney.h"
#import "NSDictionary+MBDictionary.h"
#import "MBTrainJourneyEvent.h"
#import "WagenstandRequestManager.h"

@interface MBTrainJourney()
@property(nonatomic,strong) NSDictionary* dict;
@property(nonatomic,strong) NSArray* eventCache;
@end

@implementation MBTrainJourney

-(MBTrainJourney *)initWithDict:(NSDictionary *)dict{
    self = [super init];
    if(self){
        self.dict = dict;
        self.journeyID = [dict db_stringForKey:@"journeyID"];
        self.journeyCanceled = [dict db_boolForKey:@"journeyCanceled"];
    }
    return self;
}

-(BOOL)isSEVJourney{
    NSArray* events = [self.dict db_arrayForKey:@"events"];
    NSDictionary* event = events.firstObject;
    NSDictionary* transport = [event db_dictForKey:@"transport"];
    NSDictionary* replacementTransport = [transport db_dictForKey:@"replacementTransport"];
    NSString* realType = [replacementTransport db_stringForKey:@"realType"];
    return [realType isEqualToString:@"BUS"];
}

-(BOOL)journeyShouldHaveTrainOrderRecord{
    NSDictionary* info = [self.dict db_dictForKey:@"info"];
    NSDictionary* transportAtStart = [info db_dictForKey:@"transportAtStart"];
    NSDictionary* administration = [transportAtStart db_dictForKey:@"administration"];
    NSString* administrationID = [administration db_stringForKey:@"administrationID"];
    NSLog(@"ris:journey administrationID %@",administrationID);
    if(administrationID){
        return [WagenstandRequestManager.sharedManager hasDataForAdministration:administrationID];
    }
    return false;
}

-(NSArray<MBTrainJourneyStop *> *)journeyStopsForDeparture:(BOOL)departure{
    if(!self.eventCache){
        NSArray* serverSegments = [self.dict db_arrayForKey:@"events"];
        NSMutableArray<MBTrainJourneyEvent*>* events = [NSMutableArray arrayWithCapacity:serverSegments.count];
        for(NSDictionary* segmentDict in serverSegments){
            MBTrainJourneyEvent* event = [[MBTrainJourneyEvent alloc] initWithDict:segmentDict];
            [events addObject:event];
        }

        //now combine events: arrival followed by departure with same evaNumber: combine into one
        for(NSInteger i=0; i<events.count; ){
            MBTrainJourneyEvent* event = events[i];
            if(event.isArrival){
                if(i+1 < events.count){
                    MBTrainJourneyEvent* nextevent = events[i+1];
                    if(!nextevent.isArrival && [event.evaNumber isEqualToString:nextevent.evaNumber]){
                        //next event is the departure from same station
                        if(!nextevent.canceled && event.canceled){
                            //don't mark this as canceled, since only the arrival was cancelled
                            event.canceled = false;
                        }
                        event.linkedDepartureForThisArrival = nextevent;
                        [events removeObjectAtIndex:i+1];
                    }
                }
            }
            i += 1;
        }

        NSMutableArray<MBTrainJourneyStop*>* res = [NSMutableArray arrayWithCapacity:events.count];
        for(MBTrainJourneyEvent* event in events){
            MBTrainJourneyStop* stop = [[MBTrainJourneyStop alloc] initWithEvent:event forDeparture:departure];
            [res addObject:stop];
        }
        
        NSLog(@"parsed events: %@",res);
        self.eventCache = res;
    }
    return self.eventCache;
}


@end
