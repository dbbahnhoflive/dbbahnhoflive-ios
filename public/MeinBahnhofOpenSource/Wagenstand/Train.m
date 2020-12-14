// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "Train.h"

@implementation Train

+ (NSDictionary*) JSONKeyPathsByPropertyKey
{
    return @{
             @"destination": @"destination",
             @"sections": @"sections"
             };
}

- (NSString *)destinationStation
{
    return [self.destination objectForKey:@"destinationName"];
}

- (NSArray *)destinationVia
{
    return [self.destination objectForKey:@"destinationVia"];
}

- (NSString *) destinationViaAsString
{
    return [self.destinationVia componentsJoinedByString:@", "];
}

- (NSString *)sectionRangeAsString;
{
    return [NSString stringWithFormat:@"%@-%@",[self.sections firstObject], [self.sections lastObject]];
}

@end
