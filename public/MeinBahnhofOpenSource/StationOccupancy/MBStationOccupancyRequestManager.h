// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
@class MBStationOccupancy;

@interface MBStationOccupancyRequestManager : AFHTTPSessionManager

+ (MBStationOccupancyRequestManager*)sharedInstance;

-(void)getOccupancyForStation:(NSNumber*)stationId forcedByUser:(BOOL)forcedByUser
     success:(void (^)(MBStationOccupancy *response))success
failureBlock:(void (^)(NSError *error))failure;

@end
