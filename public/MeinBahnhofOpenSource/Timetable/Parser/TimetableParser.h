// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import "Timetable.h"
#import "Stop.h"
#import "Event.h"
#import "TBXML.h"

@interface TimetableParser : NSObject

+ (NSArray*) parseTimeTableFromData:(NSData*)data;
+ (NSArray*) parseChangesForTimetable:(NSData*)data;

@end
