// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "Train.h"
#import <UIKit/UIKit.h>

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
    if(UIAccessibilityIsVoiceOverRunning()){
        return [NSString stringWithFormat:@"Abschnitt %@ bis Abschnitt %@",[self.sections firstObject], [self.sections lastObject]];
    }
    return [NSString stringWithFormat:@"%@-%@",[self.sections firstObject], [self.sections lastObject]];
}

@end
