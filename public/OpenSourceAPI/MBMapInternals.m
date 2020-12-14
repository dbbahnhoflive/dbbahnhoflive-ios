// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBMapInternals.h"

@implementation MBMapInternals

+(NSString*)kGoogleMapsApiKey{
    return @"";
}

+(NSString*)backgroundTileURLForZoom:(int)zoom x:(int)x y:(int)y{
    return nil;
}

+(NSString *)indoorTileURLForLevel:(NSString*)level zoom:(NSUInteger)zoom x:(NSUInteger)x y:(NSUInteger)y{
    return nil;
}

@end
