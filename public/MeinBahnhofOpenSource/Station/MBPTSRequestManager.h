// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <AFNetworking/AFNetworking.h>
#import "MBPTSStationResponse.h"
#import "MBPTSStationFromSearch.h"

@interface MBPTSRequestManager  : AFHTTPSessionManager

+ (MBPTSRequestManager*)sharedInstance;
- (NSURLSessionTask *)requestStationData:(NSNumber*)stationId
                            forcedByUser:(BOOL)forcedByUser
                                    success:(void (^)(MBPTSStationResponse *response))success
                               failureBlock:(void (^)(NSError *error))failure;

- (NSURLSessionTask *)searchStationByName:(NSString*)text
        success:(void (^)(NSArray<MBPTSStationFromSearch*>* stationList))success
   failureBlock:(void (^)(NSError *error))failure;

- (NSURLSessionTask *)searchStationByGeo:(CLLocationCoordinate2D)geo
     success:(void (^)(NSArray<MBPTSStationFromSearch*>* stationList))success
failureBlock:(void (^)(NSError *error))failure;


@end
