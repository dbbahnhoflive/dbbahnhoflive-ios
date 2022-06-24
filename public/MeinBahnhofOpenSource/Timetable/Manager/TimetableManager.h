// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import "Timetable.h"


#define NOTIF_TIMETABLE_UPDATE @"bahnhoflive.timetable_update"
#define NOTIF_TIMETABLE_REFRESHING @"bahnhoflive.timetable_refreshing"

typedef NS_ENUM(NSUInteger, TimetableStatus) {
    TimetableStatusIdle = 0,
    TimetableStatusBusy = 1,
    TimetableStatusError  = 2,
};

typedef NS_ENUM(NSUInteger, TimetableResponseStatus) {
    TimetableResponseStatus_EMPTY = 0,
    TimetableResponseStatus_SUCCESS,
    TimetableResponseStatus_ERROR,
    TimetableResponseStatus_FILTER_EMPTY
} ;


@interface TimetableManager : NSObject

@property (nonatomic, strong) NSArray<NSString*> *evaIds;

@property (nonatomic, strong) Timetable *timetable;
@property (nonatomic, assign) TimetableStatus timetableStatus;

+ (TimetableManager*)sharedManager;

- (void) startTimetableScheduler;
- (void) stopTimetableScheduler;
- (void) manualRefresh;

- (void) resetTimetable;

-(void)reloadTimetableWithEvaIds:(NSArray*)eva_ids;

-(BOOL)canRequestAdditionalData;
-(void)requestAdditionalData;

-(BOOL)hasLoadingError;
@end
