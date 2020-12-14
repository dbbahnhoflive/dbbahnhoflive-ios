// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

@interface NSDateFormatter (MBDateFormatter)

+ (NSDateFormatter*) cachedDateFormatter;
+ (NSString*) formattedDate:(NSDate*)date forPattern:(NSString*)pattern;
+ (NSDate*) dateFromString:(NSString*)dateString forPattern:(NSString*)pattern;

@end
