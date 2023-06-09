// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//
#import "MBLockerRequestManager.h"
#import "MBNetworkFactory.h"
#import "Constants.h"
#import "NSDictionary+MBDictionary.h"

@implementation MBLockerRequestManager

+ (MBLockerRequestManager *)shared{
    static MBLockerRequestManager *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[self alloc] init];
    });
    return sharedClient;
}

-(MBCacheResponseType)cacheType{
    return MBCacheResponseRISLocker;
}

-(NSString*)requestUrlForStationId:(NSNumber*)stationId{
    return [NSString stringWithFormat:@"%@/%@/station-equipments/locker/by-key?key=%@&keyType=STATION_ID",[Constants kDBAPI],[Constants kRISStationsPath], stationId];
}

-(void)requestLocker:(NSNumber *)stationId forcedByUser:(BOOL)forcedByUser success:(void (^)(NSArray<MBLocker *> * _Nonnull))success failureBlock:(void (^)(NSError * _Nullable))failure{
    
    [self requestData:stationId forcedByUser:forcedByUser success:^(NSDictionary * _Nonnull responseObject) {
        NSArray* list = [self parseServerResponse:responseObject];
        if(list){
            success(list);
        } else {
            failure(nil);
        }
    } failureBlock:^(NSError * _Nullable error) {
        failure(error);
    }];
}



- (NSArray<MBLocker *> * _Nullable)parseServerResponse:(NSDictionary *)serverResponse{
    if(!serverResponse || ![serverResponse isKindOfClass:NSDictionary.class]){
        return nil;
    }
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:10];
    NSArray* lockerList = [serverResponse db_arrayForKey:@"lockerList"];
    if(!lockerList){
        return res;
    }
    for(NSDictionary* lockerGroup in lockerList){
        if(![lockerGroup isKindOfClass:NSDictionary.class]){
            continue;
        }
        NSArray* lockers = [lockerGroup db_arrayForKey:@"lockers"];
        for(NSDictionary* dict in lockers){
            if(![dict isKindOfClass:NSDictionary.class]){
                continue;
            }
            MBLocker* locker = [[MBLocker alloc] initWithDict:dict];
            [res addObject:locker];
        }
    }
    return res;
}


@end
