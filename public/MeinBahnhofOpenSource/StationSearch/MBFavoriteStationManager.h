// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import "MBPTSStationFromSearch.h"

@interface MBFavoriteStationManager : NSObject

+ (id)client;

-(void)addStation:(MBPTSStationFromSearch*)dict;
-(void)removeStation:(MBPTSStationFromSearch*)dict;
-(BOOL)isFavorite:(MBPTSStationFromSearch*)dict;

-(NSArray<MBPTSStationFromSearch*>*)favoriteStationsList;

@end
