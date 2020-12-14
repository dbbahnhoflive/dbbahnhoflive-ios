// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "HafasStopLocation.h"

@implementation HafasStopLocation

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error
{
    if (self = [super initWithDictionary:dictionaryValue error:error]) {
    }
    return self;
}

- (CLLocationCoordinate2D) positionAsLatLng
{
    return CLLocationCoordinate2DMake([self.lat doubleValue], [self.lon doubleValue]);
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"stopId": @"id",
             @"name": @"name",
             @"extId": @"extId",
             @"lon": @"lon",
             @"lat": @"lat",
             };
}

@end
