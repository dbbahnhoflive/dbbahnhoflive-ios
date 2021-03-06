// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "MBParkingInfo.h"

@interface MBParkingManager : AFHTTPSessionManager


+ (instancetype)client;
- (NSURLSessionTask *)requestParkingStatus:(NSNumber*)stationId
                              forcedByUser:(BOOL)forcedByUser
                                    success:(void (^)(NSArray<MBParkingInfo*> *parkingInfoItems))success
                               failureBlock:(void (^)(NSError *error))failure;


@end
