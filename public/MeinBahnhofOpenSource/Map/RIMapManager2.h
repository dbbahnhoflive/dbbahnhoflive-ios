// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "RIMapPoi.h"
@class LevelplanWrapper;


NS_ASSUME_NONNULL_BEGIN

@interface RIMapManager2 : AFHTTPSessionManager
+ (instancetype)client;
- (NSURLSessionTask *_Nullable)requestMapPOI:(NSNumber*)stationId
                                osm:(BOOL)osm
                       forcedByUser:(BOOL)forcedByUser
                            success:(void (^)(NSArray<RIMapPoi*> *pois))success
                       failureBlock:(void (^)(NSError * _Nullable error))failure;

- (NSURLSessionTask *_Nullable)requestMapStatus:(NSNumber*)stationId
                                   osm:(BOOL)osm
                          forcedByUser:(BOOL)forcedByUser
                               success:(void (^)(NSArray<LevelplanWrapper*> *levels))success
                          failureBlock:(void (^)(NSError* _Nullable error))failure;

+(NSString*)zoneIdForStationID:(NSNumber*)stationId;

@end

NS_ASSUME_NONNULL_END
