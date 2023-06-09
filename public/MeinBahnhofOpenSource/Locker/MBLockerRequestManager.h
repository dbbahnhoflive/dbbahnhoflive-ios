// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "MBLocker.h"
#import "MBRequestManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBLockerRequestManager : MBRequestManager

+ (MBLockerRequestManager*)shared;

-(void)requestLocker:(NSNumber *)stationId forcedByUser:(BOOL)forcedByUser success:(void (^)(NSArray<MBLocker *> * _Nonnull))success failureBlock:(void (^)(NSError * _Nullable))failure;

- (NSArray<MBLocker *> * _Nullable)parseServerResponse:(NSDictionary *)serverResponse;

@end

NS_ASSUME_NONNULL_END
