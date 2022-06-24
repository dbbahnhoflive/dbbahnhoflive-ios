// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "RIMapSEVManager.h"
#import "Constants.h"
#import "NSDictionary+MBDictionary.h"
#import "MBCacheManager.h"
#import "RIMapManager2.h"

@implementation RIMapSEVManager

+ (instancetype)shared
{
    static RIMapSEVManager *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[self alloc] init];
        NSURL *baseUrl = [NSURL URLWithString: [Constants.rimapHost stringByAppendingString:@"/"]];
        sharedClient.networkManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseUrl];
    });
    return sharedClient;
}

-(void)requestSEV:(NSNumber *)stationId forcedByUser:(BOOL)forcedByUser success:(void (^)(NSArray<RIMapSEV *> * _Nonnull))success failureBlock:(void (^)(NSError * _Nullable))failure{
    failure(nil);
}

- (NSArray<RIMapSEV *> *)parseServerResponse:(NSDictionary *)serverResponse{
    return @[];
}

@end
