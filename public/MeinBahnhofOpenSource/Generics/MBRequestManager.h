// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "MBCacheManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBRequestManager : NSObject

@property(nonatomic,strong) AFHTTPSessionManager* networkManager;

-(void)requestData:(NSNumber *)stationId forcedByUser:(BOOL)forcedByUser success:(void (^)(NSDictionary * _Nonnull))success failureBlock:(void (^)(NSError * _Nullable))failure;

//methods to overwrite in subclasses:
-(MBCacheResponseType)cacheType;
-(NSDictionary* _Nullable)cachedDataForStationId:(NSNumber*)stationId forcedByUser:(BOOL)forcedByUser;

@end

NS_ASSUME_NONNULL_END
