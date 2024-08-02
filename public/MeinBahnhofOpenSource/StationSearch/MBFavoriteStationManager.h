// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import "MBStationFromSearch.h"

@interface MBFavoriteStationManager : NSObject

+ (MBFavoriteStationManager*)client;

-(void)addStation:(MBStationFromSearch*)dict;
-(void)removeStation:(MBStationFromSearch*)dict;
-(BOOL)isFavorite:(MBStationFromSearch*)dict;
-(void)updateStation:(MBStationFromSearch*)station;

-(NSArray<MBStationFromSearch*>*)favoriteStationsList;

@end
