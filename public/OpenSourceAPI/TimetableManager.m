// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "TimetableManager.h"
//#import "Timetable.h"

@interface TimetableManager()

@end

@implementation TimetableManager

+ (TimetableManager*)sharedManager
{
    static TimetableManager *sharedTimetableManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTimetableManager = [[self alloc] init];
    });
    return sharedTimetableManager;
}

- (instancetype) init
{
    if (self = [super init]) {
        self.timetable = [[Timetable alloc] init];
    }
    return self;
}

-(BOOL)canRequestAdditionalData{
    return NO;
}
-(void)requestAdditionalData{

}

-(BOOL)hasLoadingError{
    return NO;
}

- (void) startTimetableScheduler
{
    //start a scheduler that updates the timetable... this is just a simple simulation
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_TIMETABLE_REFRESHING object:nil];
    [self.timetable generateTestdata];
    self.timetableStatus = TimetableStatusIdle;
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_TIMETABLE_UPDATE object:self];
}

- (void) stopTimetableScheduler
{
    
}

- (void) manualRefresh
{
    [self startTimetableScheduler];
}



- (void) resetTimetable;
{
    //NSLog(@"clear timetable");
    self.evaIds = @[];
    [self.timetable clearTimetable];
}


-(void)reloadTimetableWithEvaIds:(NSArray*)eva_ids{
    [self resetTimetable];
    [self setEvaIds:eva_ids];
    [self startTimetableScheduler];
}


@end
