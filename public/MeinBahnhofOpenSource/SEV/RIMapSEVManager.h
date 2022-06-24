// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "RIMapSEV.h"

NS_ASSUME_NONNULL_BEGIN

@interface RIMapSEVManager : NSObject

+ (instancetype)shared;

//initialized on first use
@property(nonatomic,strong) AFHTTPSessionManager* networkManager;

-(void)requestSEV:(NSNumber *)stationId forcedByUser:(BOOL)forcedByUser success:(void (^)(NSArray<RIMapSEV *> * _Nonnull))success failureBlock:(void (^)(NSError * _Nullable))failure;

//helper methods
-(NSArray<RIMapSEV*>*)parseServerResponse:(NSDictionary*)serverResponse;

@end

NS_ASSUME_NONNULL_END
