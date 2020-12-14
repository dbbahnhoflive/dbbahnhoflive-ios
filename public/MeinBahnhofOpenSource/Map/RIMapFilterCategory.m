// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "RIMapFilterCategory.h"

@implementation RIMapFilterCategory

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"appcat": @"appcat",
             @"presets": @"presets",
             @"items": @"items",
             };
}

+ (NSValueTransformer *)itemsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:RIMapFilterEntry.class];
}


@end
