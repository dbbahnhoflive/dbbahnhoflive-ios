// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import "MBCacheManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBRequestManager : NSObject


-(void)requestData:(NSNumber *)stationId forcedByUser:(BOOL)forcedByUser success:(void (^)(NSDictionary * _Nonnull))success failureBlock:(void (^)(NSError * _Nullable))failure;

//optional methods to overwrite in subclasses:
-(MBCacheResponseType)cacheType;
-(NSDictionary* _Nullable)cachedDataForStationId:(NSNumber*)stationId forcedByUser:(BOOL)forcedByUser;

//necessary method in subclass
-(NSString*)requestUrlForStationId:(NSNumber*)stationId;

@end

NS_ASSUME_NONNULL_END
