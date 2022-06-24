// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBParkingOccupancyManager.h"
#import "Constants.h"
#import "NSDictionary+MBDictionary.h"

@implementation MBParkingOccupancyManager

+ (instancetype)client
{
    static MBParkingOccupancyManager *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *baseUrl = [NSURL URLWithString:[Constants kDBAPI]];
        sharedClient = [[self alloc] initWithBaseURL:baseUrl];
    });
    return sharedClient;
}

- (NSURLSessionTask *)requestParkingOccupancy:(NSString*)siteId
                                      success:(void (^)(NSNumber *allocationCategory))success
                                 failureBlock:(void (^)(NSError *error))failure{
    
    if(!siteId){
        failure(nil);
        return nil;
    }
    
    NSString* endPoint = [NSString stringWithFormat:@"%@/parking-information/db-bahnpark/v2/parking-facilities/%@/capacities", [Constants kDBAPI], siteId ];
    NSLog(@"endPoint %@",endPoint);
    [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [self.requestSerializer setValue:[Constants dbAPIKey] forHTTPHeaderField:@"db-api-key"];
    [self.requestSerializer setValue:[Constants dbAPIClient] forHTTPHeaderField:@"db-client-id"];

    return [self GET:endPoint parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        //
    } success:^(NSURLSessionTask *operation, id responseObject) {
        //NSLog(@"got allocation response: %@",responseObject);
        
        NSDictionary* responseDict = responseObject;
        if([responseDict isKindOfClass:NSDictionary.class]){
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
            if(cat > 0){
                success([NSNumber numberWithInteger:cat]);
                return;
            }
        }
        failure(nil);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"failure in parking: %@",error);
        failure(error);
    }];
}


@end
