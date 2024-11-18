// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBTrainJourneyEvent.h"
#import "NSDictionary+MBDictionary.h"

@implementation MBTrainJourneyEvent

-(MBTrainJourneyEvent *)initWithDict:(NSDictionary * _Nullable)dict{
    self = [super init];
    if(self){
        self.additional = [dict db_boolForKey:@"additional"];
        self.canceled = [dict db_boolForKey:@"cancelled"];
        NSDictionary* station = [dict db_dictForKey:@"stopPlace"];
        self.name = [station db_stringForKey:@"name"];
        self.evaNumber = [station db_stringForKey:@"evaNumber"];
        self.platform = [dict db_stringForKey:@"platform"];
        self.platformSchedule = [dict db_stringForKey:@"platformSchedule"];
        
        self.time = [dict db_stringForKey:@"time"];
        self.timeSchedule = [dict db_stringForKey:@"timeSchedule"];
        self.type = [dict db_stringForKey:@"type"];
        self.timeType = [dict db_stringForKey:@"timeType"];
        if([self isScheduleEvent]){
            self.time = @"";
        }
    }
    return self;
}

-(BOOL)isScheduleEvent{
    return [self.timeType isEqualToString:@"SCHEDULE"];
}

-(BOOL)isArrival{
    return [self.type isEqualToString:@"ARRIVAL"];
}

@end
