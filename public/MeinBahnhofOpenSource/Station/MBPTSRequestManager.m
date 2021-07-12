// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBPTSRequestManager.h"
#import "MBCacheManager.h"
#import "Constants.h"
#import "NSDictionary+MBDictionary.h"
@interface MBPTSRequestManager()

@end

@implementation MBPTSRequestManager

//for debugging set this to true to test the fallback to hafas-api
static BOOL simulateSearchFailure = NO;

+ (MBPTSRequestManager*)sharedInstance
{
    static MBPTSRequestManager *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *baseUrl = [NSURL URLWithString:[Constants kBusinessHubProdBaseUrl]];
        sharedClient = [[self alloc] initWithBaseURL:baseUrl];
        
    });
    return sharedClient;
}

-(NSURLSessionTask *)requestStationData:(NSNumber *)stationId forcedByUser:(BOOL)forcedByUser success:(void (^)(MBPTSStationResponse *response))success failureBlock:(void (^)(NSError *))failure{
    
    MBCacheResponseType type = MBCacheResponsePTS;
    MBCacheState cacheState = [[MBCacheManager sharedManager] cacheStateForStationId:stationId type:type];
    if(forcedByUser && cacheState == MBCacheStateValid){
        cacheState = MBCacheStateOutdated;
    }
    if(cacheState == MBCacheStateValid){
        NSDictionary* cachedResponse = [[MBCacheManager sharedManager] cachedResponseForStationId:stationId type:type];
        if(cachedResponse){
            NSLog(@"using PTS data from cache!");
            MBPTSStationResponse* response = [[MBPTSStationResponse alloc] initWithResponse:cachedResponse];
            success(response);
            return nil;
        }
    }
    
    NSString* endPoint = [NSString stringWithFormat:@"%@/%@/stop-places/%@",[Constants kBusinessHubProdBaseUrl],[Constants kPTSPath], stationId];
    NSLog(@"endPoint %@",endPoint);
    [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [self.requestSerializer setValue:[Constants kBusinesshubKey] forHTTPHeaderField:@"key"];
    
    return [self GET:endPoint parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        //
    } success:^(NSURLSessionTask *operation, id responseObject) {
        
        MBPTSStationResponse* response = [[MBPTSStationResponse alloc] initWithResponse:responseObject];
        if(response.isValid){
            [[MBCacheManager sharedManager] storeResponse:responseObject forStationId:stationId type:type];
            success(response);
        } else {
            failure(nil);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        //NSData* data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        //NSLog(@"data: %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        
        if(cacheState == MBCacheStateOutdated){
            NSDictionary* cachedResponse = [[MBCacheManager sharedManager] cachedResponseForStationId:stationId type:type];
            if(cachedResponse){
                NSLog(@"using outdated PTS data from cache!");
                MBPTSStationResponse* response = [[MBPTSStationResponse alloc] initWithResponse:cachedResponse];
                success(response);
                return;
            }
        }
        
        failure(error);
    }];
}


-(NSURLSessionTask *)searchStationByName:(NSString *)text success:(void (^)(NSArray<MBPTSStationFromSearch*>* stationList))success failureBlock:(void (^)(NSError *))failure{
    NSString* searchTerm = [text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet letterCharacterSet]];
    NSInteger size = 100;
    NSString* requestUrlWithParams = [NSString stringWithFormat:@"%@/%@/stop-places/by-name/%@?limit=%ld",[Constants kBusinessHubProdBaseUrl], [Constants kRISStationsPath],searchTerm,(long)size];
    [self.requestSerializer setValue:@"application/json, application/vnd.de.db.ris+json, */*" forHTTPHeaderField:@"Accept"];

    [self.requestSerializer setValue:[Constants kBusinesshubKey] forHTTPHeaderField:@"db-api-key"];
    self.responseSerializer.acceptableContentTypes = [self.responseSerializer.acceptableContentTypes setByAddingObject:@"application/vnd.de.db.ris+json"];
    NSLog(@"RIS:Stations: %@",requestUrlWithParams);
    return [self GET:requestUrlWithParams parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        //
    } success:^(NSURLSessionTask *operation, id responseObject) {
        
        if(simulateSearchFailure){
            failure(nil);
            return;
        }

        if([responseObject isKindOfClass:NSDictionary.class]){
            [MBTrackingManager trackActions:@[@"risstations_request", @"text", @"success"]];
            success([self parseResponse:responseObject]);
        } else {
            [MBTrackingManager trackActions:@[@"risstations_request", @"text", @"failure"]];
            failure(nil);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        [MBTrackingManager trackActions:@[@"risstations_request", @"text", @"failure"]];
        NSLog(@"risstations search failed: %@",error.localizedDescription);
        failure(error);
    }];
}

-(NSURLSessionTask *)searchStationByGeo:(CLLocationCoordinate2D)geo success:(void (^)(NSArray<MBPTSStationFromSearch*>* stationList))success failureBlock:(void (^)(NSError *))failure{
    NSInteger size = 100;
    NSString* requestUrlWithParams = [NSString stringWithFormat:@"%@/%@/stop-places/by-position?latitude=%.3f&longitude=%.3f&radius=2000&limit=%ld",
                            [Constants kBusinessHubProdBaseUrl],
                            [Constants kRISStationsPath],
                            geo.latitude,
                            geo.longitude,
                            (long)size];

    self.responseSerializer.acceptableContentTypes = [self.responseSerializer.acceptableContentTypes setByAddingObject:@"application/vnd.de.db.ris+json"];
    [self.requestSerializer setValue:[Constants kBusinesshubKey] forHTTPHeaderField:@"db-api-key"];
    [self.requestSerializer setValue:@"application/json, application/vnd.de.db.ris+json, */*" forHTTPHeaderField:@"Accept"];
    NSLog(@"RIS:Stations: %@",requestUrlWithParams);

    return [self GET:requestUrlWithParams parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        //
    } success:^(NSURLSessionTask *operation, id responseObject) {
        
        if(simulateSearchFailure){
            failure(nil);
            return;
        }

        if([responseObject isKindOfClass:NSDictionary.class]){
            [MBTrackingManager trackActions:@[@"risstations_request", @"geo", @"success"]];
            success([self parseResponse:responseObject]);
        } else {
            [MBTrackingManager trackActions:@[@"risstations_request", @"geo", @"failure"]];
            failure(nil);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        [MBTrackingManager trackActions:@[@"risstations_request", @"geo", @"failure"]];
        failure(error);
    }];
}

-(NSArray<MBPTSStationFromSearch*>*)parseResponse:(NSDictionary*)response{
    NSArray* results = nil;
    if(![response isKindOfClass:NSDictionary.class]){
        return nil;
    }
    results = [response db_arrayForKey:@"stopPlaces"];
    if(results){
        NSMutableArray<MBPTSStationFromSearch*>* resultsTransformed = [NSMutableArray arrayWithCapacity:results.count];
        for(NSDictionary* res in results){
            
            NSString* stationID = [res db_stringForKey:@"stationID"];
            NSString* evaNumber = [res db_stringForKey:@"evaNumber"];
            NSArray* evaNumbers = [res db_arrayForKey:@"groupMembers"];
            NSArray* availableTransports = [res db_arrayForKey:@"availableTransports"];
            if(availableTransports.count == 0){
                continue;//skip stations without any transports
            }

            NSNumber* stationNumber = nil;
            if(stationID){
                stationNumber = [NSNumber numberWithLongLong:stationID.longLongValue];
            }
            NSString* title = [[[res db_dictForKey:@"names"] db_dictForKey:@"DE"] db_stringForKey:@"nameLong"];
            NSNumber* longitude = nil;
            NSNumber* latitude = nil;
            NSDictionary* location = [res db_dictForKey:@"position"];
            longitude = [location db_numberForKey:@"longitude"];
            latitude = [location db_numberForKey:@"latitude"];
            
            NSMutableArray* evaIdsWithMainEvaFirst = [NSMutableArray arrayWithCapacity:evaNumbers.count];
            if(evaNumbers){
                [evaIdsWithMainEvaFirst addObjectsFromArray:evaNumbers];
                [evaIdsWithMainEvaFirst removeObject:evaNumber];
            }
            [evaIdsWithMainEvaFirst insertObject:evaNumber atIndex:0];
            evaNumbers = evaIdsWithMainEvaFirst;
            if(title && evaNumbers.count > 0 && longitude && latitude){
                MBPTSStationFromSearch* res = [MBPTSStationFromSearch new];
                res.stationId = stationNumber;
                res.isOPNVStation = stationNumber == nil;
                res.title = title;
                res.eva_ids = evaNumbers;
                res.coordinate = CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue);
                res.distanceInKm = @0;
                [resultsTransformed addObject:res];
            } else {
                NSLog(@"missing data, ignored: %@",title);
            }
        }
        return resultsTransformed;
    }
    return nil;
}

#pragma mark Platform api

-(NSURLSessionTask *)requestAccessibility:(NSString *)eva success:(void (^)(NSArray<MBPlatformAccessibility*>* platformList))success failureBlock:(void (^)(NSError *))failure{
    NSString* requestUrlWithParams = [NSString stringWithFormat:@"%@/%@/platforms/%@/?includeAccessibility=true",[Constants kBusinessHubProdBaseUrl], [Constants kRISStationsPath],eva];
    [self.requestSerializer setValue:@"application/json, application/vnd.de.db.ris+json, */*" forHTTPHeaderField:@"Accept"];

    [self.requestSerializer setValue:[Constants kBusinesshubKey] forHTTPHeaderField:@"db-api-key"];
    self.responseSerializer.acceptableContentTypes = [self.responseSerializer.acceptableContentTypes setByAddingObject:@"application/vnd.de.db.ris+json"];
    NSLog(@"RIS:Stations: %@",requestUrlWithParams);
    return [self GET:requestUrlWithParams parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        //
    } success:^(NSURLSessionTask *operation, id responseObject) {
        
        if([responseObject isKindOfClass:NSDictionary.class]){
            NSDictionary* dict = responseObject;
            NSArray* platforms = [dict db_arrayForKey:@"platforms"];
            if(platforms){
                NSMutableArray* list = [NSMutableArray arrayWithCapacity:platforms.count];
                for(NSDictionary* platformsDict in platforms){
                    if(![platformsDict isKindOfClass:NSDictionary.class]){
                        continue;
                    }
                    MBPlatformAccessibility* pa = [MBPlatformAccessibility parseDict:platformsDict];
                    if(pa){
                        [list addObject:pa];
                    }
                }
                success(list);
                return;
            }
        }
        failure(nil);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"risstations platforms failed: %@",error.localizedDescription);
        failure(error);
    }];
}


@end
