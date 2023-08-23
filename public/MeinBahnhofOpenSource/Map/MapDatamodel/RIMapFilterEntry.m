// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "RIMapFilterEntry.h"

@implementation RIMapFilterEntry

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"title": @"title",
             @"menucat": @"menucat",
             @"menusubcat": @"menusubcat",
             @"presets": @"presets",
             };
}

@end
