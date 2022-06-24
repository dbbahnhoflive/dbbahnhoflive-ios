// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBTrainJourneyStop.h"
#import "NSDictionary+MBDictionary.h"
#import "MBTrainJourneyRequestManager.h"

@implementation MBTrainJourneyStop


-(MBTrainJourneyStop *)initWithEvent:(MBTrainJourneyEvent *)event{
    self = [super init];
    if(self){
        self.journeyProgress = -1;

        self.isTimeScheduleStop = event.isScheduleEvent;
        self.additional = event.additional;
        self.canceled = event.canceled;
        self.stationName = event.name;
        self.evaNumber = event.evaNumber;
        self.platform = event.platform;
        self.platformSchedule = event.platformSchedule;

        if(event.isArrival){
            self.arrivalTime = [MBTrainJourneyRequestManager.dateFormatter dateFromString:event.time];
            self.arrivalTimeSchedule = [MBTrainJourneyRequestManager.dateFormatter dateFromString:event.timeSchedule];
            if(event.linkedDepartureForThisArrival){
                self.departureTime = [MBTrainJourneyRequestManager.dateFormatter dateFromString:event.linkedDepartureForThisArrival.time];
                self.departureTimeSchedule = [MBTrainJourneyRequestManager.dateFormatter dateFromString:event.linkedDepartureForThisArrival.timeSchedule];
            }
        } else {
            self.departureTime = [MBTrainJourneyRequestManager.dateFormatter dateFromString:event.time];
            self.departureTimeSchedule = [MBTrainJourneyRequestManager.dateFormatter dateFromString:event.timeSchedule];
        }
    }
    return self;
}

-(BOOL)platformChange{
    return self.platformSchedule.length > 0 && ![self.platform isEqualToString:self.platformSchedule];
}




-(NSString *)description{
    return [NSString stringWithFormat:@"Segment<\n%@, Gleis %@ (geplant %@), additional %d, canceled %d\nAnkunft: %@ (%@)\nAbfahrt: %@ (%@)\n>",_stationName,_platform,_platformSchedule,_additional,_canceled,self.arrivalTime,self.arrivalTimeSchedule,self.departureTime,self.departureTimeSchedule];
}

@end
