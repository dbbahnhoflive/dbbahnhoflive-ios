// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <AFNetworking/AFNetworking.h>
#import "MBNewsResponse.h"

@interface MBNewsRequestManager : AFHTTPSessionManager

+ (MBNewsRequestManager*)sharedInstance;
- (NSURLSessionTask *)requestNewsForStation:(NSNumber*)stationId
                            forcedByUser:(BOOL)forcedByUser
                                 success:(void (^)(MBNewsResponse *response))success
                            failureBlock:(void (^)(NSError *error))failure;


@end
