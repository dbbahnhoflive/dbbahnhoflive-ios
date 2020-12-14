// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MBMapInternals : NSObject

+(NSString*)kGoogleMapsApiKey;
+(NSString*)backgroundTileURLForZoom:(int)zoom x:(int)x y:(int)y;
+(NSString*)indoorTileURLForLevel:(NSString*)level zoom:(NSUInteger)zoom x:(NSUInteger)x y:(NSUInteger)y;

@end

NS_ASSUME_NONNULL_END
