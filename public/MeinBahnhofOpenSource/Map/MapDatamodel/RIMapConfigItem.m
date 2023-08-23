// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "RIMapConfigItem.h"

@implementation RIMapConfigItem


+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"menucat": @"menucat",
             @"menusubcat": @"menusubcat",
             @"zoom": @"zoom",
             @"icon": @"icon",
             @"showLabelAtZoom": @"showLabelAtZoom",
             };
}


@end
