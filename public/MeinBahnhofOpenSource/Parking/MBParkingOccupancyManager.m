// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBParkingOccupancyManager.h"
#import "Constants.h"
#import "NSDictionary+MBDictionary.h"
#import "MBNetworkFactory.h"
#import "MBCacheManager.h"

@implementation MBParkingOccupancyManager

+ (instancetype)client
{
    static MBParkingOccupancyManager *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *baseUrl = [NSURL URLWithString:[Constants kDBAPI]];
        sharedClient = [[self alloc] initWithBaseURL:baseUrl];
        [MBNetworkFactory configureRISHeader:sharedClient];

    });
    return sharedClient;
}

- (NSURLSessionTask *)requestParkingOccupancy:(NSString*)siteId
                                 forcedByUser:(BOOL)forcedByUser 
                                      success:(void (^)(NSNumber *allocationCategory))success
                                 failureBlock:(void (^)(NSError *error))failure{
    
    if(!siteId){
        failure(nil);
        return nil;
    }
    
    NSNumber* siteIdNum = [NSNumber numberWithLongLong:siteId.longLongValue];
    MBCacheResponseType type = MBCacheResponseParkingCapacity;
    if(!forcedByUser){
        MBCacheState cacheState = [[MBCacheManager sharedManager] cacheStateForStationId:siteIdNum type:type];
        if(cacheState == MBCacheStateValid){
            NSDictionary* cachedResponse = [[MBCacheManager sharedManager] cachedResponseForStationId:siteIdNum type:type];
            if(cachedResponse){
                NSLog(@"using parking capacity data from cache!");
                NSNumber* cat = [self parseCat:cachedResponse];
                success(cat);
                return nil;
            }
        }
    }
    
    NSString* endPoint = [NSString stringWithFormat:@"%@/parking-information/db-bahnpark/v2/parking-facilities/%@/capacities", [Constants kDBAPI], siteId ];
    NSLog(@"endPoint %@",endPoint);
    return [self GET:endPoint parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        //
    } success:^(NSURLSessionTask *operation, id responseObject) {
        //NSLog(@"got allocation response: %@",responseObject);
        NSDictionary* responseDict = responseObject;
        if([responseDict isKindOfClass:NSDictionary.class]){
            NSNumber* cat = [self parseCat:responseDict];
            [MBCacheManager.sharedManager storeResponse:responseDict forStationId:siteIdNum type:type];
            success(cat);
            return;
        }
        failure(nil);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"failure in parking: %@",error);
        failure(error);
    }];
}

-(NSNumber*)parseCat:(NSDictionary*)responseDict{
    NSArray* _embedded = [responseDict db_arrayForKey:@"_embedded"];
    NSInteger cat = 0;
    for(NSDictionary* dict in _embedded){
        if([dict isKindOfClass:NSDictionary.class]){
            NSString* type = [dict db_stringForKey:@"type"];
            if([type isEqualToString:@"PARKING"]){
                NSString* total = [dict db_stringForKey:@"total"];
                NSInteger totalNumber = total.integerValue;
                if(totalNumber > 50){
                    cat = 4;
                    break;
                }
                if(totalNumber > 30){
                    cat = 3;
                    break;
                }
                if(totalNumber > 10){
                    cat = 2;
                    break;
                }
                cat = 1;
                break;
            }
        }
    }
    return [NSNumber numberWithInteger:cat];
}


@end
