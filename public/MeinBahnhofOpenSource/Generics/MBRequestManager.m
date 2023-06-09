// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//
#import "MBRequestManager.h"
#import "MBNetworkFactory.h"

@implementation MBRequestManager

-(instancetype)init{
    self = [super init];
    if(self){
        self.networkManager = [MBNetworkFactory createRISSessionManager];
    }
    return self;
}

-(MBCacheResponseType)cacheType{
    return MBCacheResponseTypeInvalid;
}

-(NSDictionary* _Nullable)cachedDataForStationId:(NSNumber*)stationId forcedByUser:(BOOL)forcedByUser{
    if(self.cacheType == MBCacheResponseTypeInvalid){
        return nil;
    }
    MBCacheState cacheState = [[MBCacheManager sharedManager] cacheStateForStationId:stationId type:self.cacheType];
    if(forcedByUser){
    } else if(cacheState == MBCacheStateValid){
        NSDictionary* cachedResponse = [[MBCacheManager sharedManager] cachedResponseForStationId:stationId type:self.cacheType];
        return cachedResponse;
    }
    return nil;
}


-(NSString*)requestUrlForStationId:(NSNumber*)stationId{
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return nil;
}

-(void)requestData:(NSNumber *)stationId forcedByUser:(BOOL)forcedByUser success:(void (^)(NSDictionary * _Nonnull))success failureBlock:(void (^)(NSError * _Nullable))failure{
    NSDictionary* cachedData = [self cachedDataForStationId:stationId forcedByUser:forcedByUser];
    if(cachedData){
        NSLog(@"using cached data for type %lu",(unsigned long)self.cacheType);
        success(cachedData);
        return;
    }
    NSString* endPoint = [self requestUrlForStationId:stationId];
    NSLog(@"endPoint %@",endPoint);
    [self.networkManager GET:endPoint parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if([responseObject isKindOfClass:NSDictionary.class]){
            if(self.cacheType != MBCacheResponseTypeInvalid){
                [MBCacheManager.sharedManager storeResponse:responseObject forStationId:stationId type:self.cacheType];
            }
            success(responseObject);
        } else {
            failure(nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@ failed: %@",endPoint,error);
        failure(error);
    }];
}

@end
