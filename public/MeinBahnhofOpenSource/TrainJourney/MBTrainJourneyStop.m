// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBTrainJourneyStop.h"
#import "NSDictionary+MBDictionary.h"
#import "MBTrainJourneyRequestManager.h"

@implementation MBTrainJourneyStop

-(instancetype)init{
    self = [super init];
    if(self){
        self.platformDesignator = @"Gl.";
        self.platformDesignatorVoiceOver = @"Gleis";
    }
    return self;
}

-(MBTrainJourneyStop *)initWithEvent:(MBTrainJourneyEvent *)event forDeparture:(BOOL)departure{
    self = [super init];
    if(self){
        self.platformDesignator = @"Gl.";
        self.platformDesignatorVoiceOver = @"Gleis";
        self.journeyProgress = -1;
        self.isTimeScheduleStop = event.isScheduleEvent;
        self.additional = event.additional;
        self.canceled = event.canceled;
        self.stationName = event.name;
        self.evaNumber = event.evaNumber;
        self.platform = event.platform;
        self.platformSchedule = event.platformSchedule;
        if(departure && event.linkedDepartureForThisArrival){
            //for the rare case when a train departs from another platform than it arrives: when we display a journey from the departure-board then use platforms information from the departure event.
            self.platform = event.linkedDepartureForThisArrival.platform;
            self.platformSchedule = event.linkedDepartureForThisArrival.platformSchedule;
        }

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
    return self.platformSchedule.length > 0 && self.platform.length > 0 && ![self.platform isEqualToString:self.platformSchedule];
}

-(NSString *)platformForDisplay{
    NSString* platform = self.platform;
    if(!platform){
        platform = self.platformSchedule;
    }
    return platform;
}
-(BOOL)hasPlatformInfo{
    return MBStation.displayPlaformInfo && ( self.linkedPlatformsForStop.count > 0 || self.headPlatform || self.platformLevel.length > 0
    || self.isCurrentStation);
}


-(NSString *)description{
    return [NSString stringWithFormat:@"Segment<\n%@, %@, Gleis %@ (geplant %@), additional %d, canceled %d\nAnkunft: %@ (%@)\nAbfahrt: %@ (%@)\n>",_stationName,_evaNumber,_platform,_platformSchedule,_additional,_canceled,self.arrivalTime,self.arrivalTimeSchedule,self.departureTime,self.departureTimeSchedule];
}

@end
