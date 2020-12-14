// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import <CoreLocation/CoreLocation.h>

@class MobilityMappable;

@interface SharedMobilityAPI : AFHTTPSessionManager

+ (instancetype)client;
- (NSURLSessionTask *)getMappables:(CLLocationCoordinate2D)coordinate
                                 success:(void (^)(NSArray<MobilityMappable*> *mappables))success
                                 failureBlock:(void (^)(NSError *error))failureBlock;

@end
