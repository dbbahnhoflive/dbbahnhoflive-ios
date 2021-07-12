// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import <GoogleMaps/GoogleMaps.h>

NS_ASSUME_NONNULL_BEGIN

@interface RIMapIndoorTileLayer :  GMSSyncTileLayer

@property(nonatomic,strong) NSString* currentLevel;
@property(nonatomic) BOOL useOSM;

@end

NS_ASSUME_NONNULL_END
