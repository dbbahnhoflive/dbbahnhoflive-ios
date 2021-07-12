// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "RIMapManager2.h"

@implementation RIMapManager2

+ (instancetype)client
{
    static RIMapManager2 *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *baseUrl = [NSURL URLWithString:@""];
        sharedClient = [[self alloc] initWithBaseURL:baseUrl];
    });
    return sharedClient;
}

-(NSURLSessionTask *)requestMapPOI:(NSNumber *)stationId osm:(BOOL)osm forcedByUser:(BOOL)forcedByUser success:(void (^)(NSArray<RIMapPoi *> * _Nonnull))success failureBlock:(void (^)(NSError * _Nullable))failure{
    failure(nil);
    return nil;
}





- (NSURLSessionTask *)requestMapStatus:(NSNumber*)stationId
                                   osm:(BOOL)osm
                                   eva:(NSString*)evaId
                          forcedByUser:(BOOL)forcedByUser
                               success:(void (^)(NSArray<LevelplanWrapper*> *levels))success
                          failureBlock:(void (^)(NSError * _Nullable))failure{
    failure(nil);
    return nil;
}

@end
