// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "RIMapManager.h"
#import "LevelplanWrapper.h"
#import "RIMapPoi.h"
#import "MBCacheManager.h"

@implementation RIMapManager

+ (instancetype)client
{
    static RIMapManager *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *baseUrl = [NSURL URLWithString:@"https://"];
        sharedClient = [[self alloc] initWithBaseURL:baseUrl];
    });
    return sharedClient;
}

+(NSString*)accesskey{
    return @"";
}


- (NSURLSessionTask *)requestMapPOI:(NSNumber*)stationId
                       forcedByUser:(BOOL)forcedByUser
                               success:(void (^)(NSArray<RIMapPoi*> *pois))success
                          failureBlock:(void (^)(NSError *error))failure{
    
    RIMapPoi* testPoi = [MTLJSONAdapter modelOfClass:RIMapPoi.class fromJSONDictionary:@{
        @"id":@12345,
        @"levelcode": @"L0",
        @"name": @"Testshop",
        @"menucat": @"Einkaufen",
        @"menusubcat": @"Einkaufen",
        @"display_x": @52.5255,
        @"display_y": @13.3695,
        @"displmap": @"Y",
    } error:nil];    
    
    success(@[testPoi]);    
    return nil;
}


- (NSURLSessionTask *)requestMapStatus:(NSNumber*)stationId eva:(NSString*)evaId
                          forcedByUser:(BOOL)forcedByUser 
                               success:(void (^)(NSArray<LevelplanWrapper*> *levels, RIMapMetaData* additionalData))success
                          failureBlock:(void (^)(NSError *error))failure{
    failure(nil);
    return nil;
}

@end
