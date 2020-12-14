// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "NSDateFormatter+MBDateFormatter.h"

@implementation NSDateFormatter (MBDateFormatter)

static NSDateFormatter *formatter;

+ (NSDateFormatter*) cachedDateFormatter
{
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    }
    return formatter;
}

+ (NSString*) formattedDate:(NSDate*)date forPattern:(NSString*)pattern
{
    [[NSDateFormatter cachedDateFormatter] setDateFormat:pattern];
    return [[NSDateFormatter cachedDateFormatter] stringFromDate:date];
}

+ (NSDate*) dateFromString:(NSString*)dateString forPattern:(NSString*)pattern
{
    [[NSDateFormatter cachedDateFormatter] setDateFormat:pattern];
    return [[NSDateFormatter cachedDateFormatter] dateFromString:dateString];
}

@end
