// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MBCacheResponseType) {
    MBCacheResponseRIMapStatus = 2,
    MBCacheResponseRIMapPOIs = 3,
    MBCacheResponseParking = 4,
    MBCacheResponseEinkaufsbahnhof = 5,
    MBCacheResponsePTS = 6,
    MBCacheResponseEinkaufsbahnhofOverview = 7,
    MBCacheResponseTravelCenter = 8,
    MBCacheResponseNews = 9,
    MBCacheResponseRIMapPOIs07Api = 10,
    MBCacheResponseRIMapStatus07API = 11,
};

typedef NS_ENUM(NSUInteger, MBCacheState){
    MBCacheStateNone = 0,
    MBCacheStateOutdated = 1,
    MBCacheStateValid = 2
};

@interface MBCacheManager : NSObject

+ (instancetype)sharedManager;
-(MBCacheState)cacheStateForStationId:(NSNumber*)stationId type:(MBCacheResponseType)type;
-(NSDictionary*)cachedResponseForStationId:(NSNumber*)stationId type:(MBCacheResponseType)type;
-(void)storeResponse:(NSDictionary*)responseObject forStationId:(NSNumber*)stationId type:(MBCacheResponseType)type;

-(void)deleteCache;
@end
