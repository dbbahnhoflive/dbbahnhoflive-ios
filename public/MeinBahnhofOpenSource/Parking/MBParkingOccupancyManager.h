// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@interface MBParkingOccupancyManager : AFHTTPSessionManager

+ (instancetype)client;
- (NSURLSessionTask *)requestParkingOccupancy:(NSString*)siteId
                                   success:(void (^)(NSNumber *allocationCategory))success
                              failureBlock:(void (^)(NSError *error))failure;



@end
