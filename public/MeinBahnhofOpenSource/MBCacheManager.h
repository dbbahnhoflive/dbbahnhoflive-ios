// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MBCacheResponseType) {
    MBCacheResponseTypeInvalid = 0,
    MBCacheResponseParking = 4,
    MBCacheResponseEinkaufsbahnhof = 5,
    MBCacheResponseEinkaufsbahnhofOverview = 7,
    MBCacheResponseNews = 9,
    MBCacheResponseRIMapPOIs07Api = 10,
    MBCacheResponseRIMapStatus07API = 11,

    MBCacheResponseRISStationData = 12,
    MBCacheResponseRISStationServices = 13,

    MBCacheResponseRIMapSEV07API = 14,

    MBCacheResponseRISLocker = 15,

    MBCacheResponseRISStopPlacesForEva = 16,
    MBCacheResponseRISPlatforms = 17,
    MBCacheResponseRISOccupancy = 18,
    MBCacheResponseParkingCapacity = 19,

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
