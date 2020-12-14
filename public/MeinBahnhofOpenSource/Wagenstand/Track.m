// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "Track.h"

@implementation Track

+ (NSArray*)trackNumbers:(NSArray*)tracks
{
    NSMutableArray *trackNumbers = [NSMutableArray array];
    for (Track *track in tracks) {
        if ([track.number rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound) {
            [trackNumbers addObject:track.number];
        }
    }
    
    trackNumbers = [[trackNumbers sortedArrayUsingComparator:^(NSString *obj1, NSString* obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }] mutableCopy];
    
    //[trackNumbers insertObject:@"-" atIndex:0];
    return trackNumbers;
    
}

+ (NSDictionary*) JSONKeyPathsByPropertyKey
{
    return @{
             @"number": @"number",
             @"name": @"name"
             };
}


@end
