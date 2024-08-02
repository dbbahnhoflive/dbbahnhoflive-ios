// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "Train.h"
#import <UIKit/UIKit.h>

@implementation Train

- (NSString *)destinationStation
{
    return self.destination;
}

- (NSString *)sectionRangeAsString;
{
    if(self.sections.count == 0 || ((NSString*)self.sections.firstObject).length == 0 || ((NSString*)self.sections.lastObject).length == 0){
        return @"";
    }
    if(UIAccessibilityIsVoiceOverRunning()){
        return [NSString stringWithFormat:@"Abschnitt %@ bis Abschnitt %@",[self.sections firstObject], [self.sections lastObject]];
    }
    return [NSString stringWithFormat:@"%@-%@",[self.sections firstObject], [self.sections lastObject]];
}

@end
