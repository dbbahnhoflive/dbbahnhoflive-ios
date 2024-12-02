// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBRISStationsRequestManager.h"
#import "MBCacheManager.h"
#import "Constants.h"
#import "NSDictionary+MBDictionary.h"
#import "MBStation.h"
#import "MBTrackingManager.h"

#import "MBTestHelper.h"
#import "MBAFNetworkMock.h"
#import "MBNetworkFactory.h"

@interface MBRISStationsRequestManager()
@property(nonatomic,strong) AFHTTPSessionManager* sessionManager;
@end

@implementation MBRISStationsRequestManager

//for debugging set this to true to test the fallback to hafas-api
static BOOL simulateSearchFailure = NO;

+ (MBRISStationsRequestManager*)sharedInstance
{
    static MBRISStationsRequestManager *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[self alloc] init];
        if(MBTestHelper.isTestRun){
            sharedClient.sessionManager = [MBNetworkFactory createNetworkMockSessionManager];
        } else {
            sharedClient.sessionManager = [MBNetworkFactory createRISSessionManager];
        }
    });
    return sharedClient;
}

-(NSInteger)stationCategoryFromStationData:(NSDictionary*)responseDict{
    if(![responseDict isKindOfClass:NSDictionary.class]){
        return 0;
    }
    NSString* cat = [responseDict db_stringForKey:@"stationCategory"];
    NSString* prefix = @"CATEGORY_";
    if([cat hasPrefix:prefix] && cat.length == prefix.length+1){
        NSString* numberPart = [cat substringFromIndex:prefix.length];
        return numberPart.integerValue;
    }
    return 0;
}
-(CLLocationCoordinate2D)geoPositionFromStationData:(NSDictionary*)responseDict{
    if(![responseDict isKindOfClass:NSDictionary.class]){
        return kCLLocationCoordinate2DInvalid;
    }
    NSDictionary* position = [responseDict db_dictForKey:@"position"];
    NSNumber* lng = [position db_numberForKey:@"longitude"];
    NSNumber* lat = [position db_numberForKey:@"latitude"];
    if(lng && lat){
        return CLLocationCoordinate2DMake(lat.doubleValue, lng.doubleValue);
    }
    return kCLLocationCoordinate2DInvalid;
}

-(MBStationDetails*)getStationFromCache:(NSNumber*)stationId{
    NSDictionary* cachedResponse = [[MBCacheManager sharedManager] cachedResponseForStationId:stationId type:MBCacheResponseRISStationServices];
    if(cachedResponse){
        NSLog(@"using RIS:Station data from cache!");
        MBStationDetails* response = [[MBStationDetails alloc] initWithResponse:cachedResponse];
        
        //do we also have the RIS:Station data?
        MBCacheState cacheState = [[MBCacheManager sharedManager] cacheStateForStationId:stationId type:MBCacheResponseRISStationData];
        if(cacheState == MBCacheStateValid){
            NSDictionary* cachedResponse = [[MBCacheManager sharedManager] cachedResponseForStationId:stationId type:MBCacheResponseRISStationData];
            [self parseStationDetails:cachedResponse intoDetailsData:response];
        }
        return response;
    }
    return nil;
}

-(void)requestStationGroups:(NSString *)evaId forcedByUser:(BOOL)forcedByUser success:(void (^)(NSArray<NSString*> *response))success failureBlock:(void (^)(NSError *))failure{
    
    MBCacheResponseType type = MBCacheResponseRISGroups;
    NSNumber* cacheKey = [NSNumber numberWithLongLong:evaId.longLongValue];
    MBCacheState cacheState = [[MBCacheManager sharedManager] cacheStateForStationId:cacheKey type:type];
    if(forcedByUser && cacheState == MBCacheStateValid){
        cacheState = MBCacheStateOutdated;
    }
    if(cacheState == MBCacheStateValid){
        NSLog(@"using RIS: /groups data from cache!");
        NSDictionary* data = [MBCacheManager.sharedManager cachedResponseForStationId:cacheKey type:type];
        NSArray* res = [self parseGroupsResponse:data forMainEva:evaId];
        if(res){
            success(res);
            return;
        }
        NSLog(@"cache failure");
    }
    
    NSString* endPoint = [NSString stringWithFormat:@"%@/%@/stop-places/%@/groups",[Constants kDBAPI],[Constants kRISStationsPath], evaId];
    NSLog(@"endPoint %@",endPoint);
    [self.sessionManager GET:endPoint parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        //
    } success:^(NSURLSessionTask *operation, id responseObject) {
        if([responseObject isKindOfClass:NSDictionary.class]){
            [[MBCacheManager sharedManager] storeResponse:responseObject forStationId:cacheKey type:type];
            NSArray* res = [self parseGroupsResponse:responseObject forMainEva:evaId];
            if(res){
                success(res);
                return;
            }
        }
        failure(nil);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"error: failed to load station data, continue with station services data. %@",error);
        failure(error);
    }];
}
-(NSArray*)parseGroupsResponse:(NSDictionary*)resp forMainEva:(NSString*)evaId{
    NSArray* groups = [resp db_arrayForKey:@"groups"];
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:20];
    //guido: only use SALES
    //[res addObjectsFromArray:[self getGroupMemberForType:@"STATION" fromList:groups]];
    //if(res.count == 0){
    //    return nil;
    //}
    NSArray* salesList = [self getGroupMemberForType:@"SALES" fromList:groups];
    if(salesList.count == 0){
        return nil;
    }
    for(NSString* eva in salesList){
        if(![res containsObject:eva]){
            [res addObject:eva];
        }
    }
    if([res containsObject:evaId]){
        //ensure that the mainEva is the first item
        [res removeObject:evaId];
        [res insertObject:evaId atIndex:0];
        return res;
    }
    return nil;
}

-(NSArray*)getGroupMemberForType:(NSString*)type fromList:(NSArray*)list{
    for(NSDictionary* dict in list){
        if([dict isKindOfClass:NSDictionary.class] && [[dict db_stringForKey:@"type"] isEqualToString:type]){
            NSArray* res = [dict db_arrayForKey:@"members"];
            if(res && [res.firstObject isKindOfClass:NSString.class]){
                return res;
            } else {
                break;//return empty array
            }
        }
    }
    return @[];
}

-(void)requestStationData:(NSNumber *)stationId forcedByUser:(BOOL)forcedByUser success:(void (^)(MBStationDetails *response))success failureBlock:(void (^)(NSError *))failure{
    
    //we combine the results from two requests here
    
    MBCacheResponseType type = MBCacheResponseRISStationServices;
    MBCacheState cacheState = [[MBCacheManager sharedManager] cacheStateForStationId:stationId type:type];
    if(forcedByUser && cacheState == MBCacheStateValid){
        cacheState = MBCacheStateOutdated;
    }
    if(cacheState == MBCacheStateValid){
        NSLog(@"using RIS: station services data from cache!");
        MBStationDetails* response = [self getStationFromCache:stationId];
        if(response){
            success(response);
            return;
        }
    }
    
    //first get the more important station services
    NSString* endPoint = [NSString stringWithFormat:@"%@/%@/local-services/by-key?keyType=STATION_ID&key=%@",[Constants kDBAPI],[Constants kRISStationsPath], stationId];
    NSLog(@"endPoint %@",endPoint);
    
    [self.sessionManager GET:endPoint parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        //
    } success:^(NSURLSessionTask *operation, id responseObject) {
        
        MBStationDetails* response = [[MBStationDetails alloc] initWithResponse:responseObject];
        if(response.isValid){
            [[MBCacheManager sharedManager] storeResponse:responseObject forStationId:stationId type:type];
            
            //second: get the stationdata (we only need the category from that)
            NSString* endPoint = [NSString stringWithFormat:@"%@/%@/stations/%@",[Constants kDBAPI],[Constants kRISStationsPath], stationId];
            NSLog(@"endPoint %@",endPoint);
            [self.sessionManager GET:endPoint parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
                //
            } success:^(NSURLSessionTask *operation, id responseObject) {
                [[MBCacheManager sharedManager] storeResponse:responseObject forStationId:stationId type:MBCacheResponseRISStationData];
                [self parseStationDetails:responseObject intoDetailsData:response];
                success(response);

            } failure:^(NSURLSessionTask *operation, NSError *error) {
                NSLog(@"error: failed to load station data, continue with station services data. %@",error);
                success(response);
            }];
            
        } else {
            failure(nil);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSData* data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        NSLog(@"data: %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        
        if(cacheState == MBCacheStateOutdated){
            MBStationDetails* response = [self getStationFromCache:stationId];
            if(response){
                success(response);
                return;
            }
        }
        
        failure(error);
    }];;
}

-(void)parseStationDetails:(NSDictionary*)dict intoDetailsData:(MBStationDetails*)data{
    if(![dict isKindOfClass:NSDictionary.class]){
        return;
    }
    data.category = [self stationCategoryFromStationData:dict];
    data.coordinate = [self geoPositionFromStationData:dict];
    NSDictionary* address = [dict db_dictForKey:@"address"];
    data.state = [address db_stringForKey:@"state"];
    data.country = [address db_stringForKey:@"country"];
}

-(void)searchStationByEva:(NSString *)evaNumber success:(void (^)(MBStationFromSearch* station))success failureBlock:(void (^)(NSError *))failure{
    NSString* requestUrlWithParams = [NSString stringWithFormat:@"%@/%@/stop-places/by-key?keyType=EVA&key=%@&limit=10&onlyActive=false",[Constants kDBAPI], [Constants kRISStationsPath],evaNumber];
    NSLog(@"RIS:Stations: %@",requestUrlWithParams);
    [self.sessionManager GET:requestUrlWithParams parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        //
    } success:^(NSURLSessionTask *operation, id responseObject) {
        
        if(simulateSearchFailure){
            failure(nil);
            return;
        }

        if([responseObject isKindOfClass:NSDictionary.class]){
//            [MBTrackingManager trackActions:@[@"risstations_request", @"text", @"success"]];
            MBStationFromSearch* res = [self parseResponse:responseObject].firstObject;
            res.isFreshStationFromSearch = false;//stop-places/by-key does not contain all evaIDs, this flag leads to an additional search request on by-name which will contain all Evas.
            if(res){
                success(res);
            } else {
                failure(nil);
            }
        } else {
//            [MBTrackingManager trackActions:@[@"risstations_request", @"text", @"failure"]];
            failure(nil);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
//        [MBTrackingManager trackActions:@[@"risstations_request", @"text", @"failure"]];
        NSLog(@"risstations search failed: %@",error.localizedDescription);
        failure(error);
    }];
}
-(void)searchStationByStada:(NSString *)stadaNumber success:(void (^)(MBStationFromSearch* station))success failureBlock:(void (^)(NSError *))failure{
    
    MBCacheResponseType type = MBCacheResponseRISStopPlacesByKeyForStada;
    NSNumber* cacheKey = [NSNumber numberWithLongLong:stadaNumber.longLongValue];
    MBCacheState cacheState = [[MBCacheManager sharedManager] cacheStateForStationId:cacheKey type:type];
    if(cacheState == MBCacheStateValid){
        NSLog(@"using RIS: by-key?keyType=STADA data from cache!");
        NSDictionary* data = [MBCacheManager.sharedManager cachedResponseForStationId:cacheKey type:type];
        MBStationFromSearch* res = [self parseResponse:data].firstObject;
        res.isFreshStationFromSearch = false;
        if(res){
            success(res);
            return;
        }
        NSLog(@"cache failure");
    }
    
    NSString* requestUrlWithParams = [NSString stringWithFormat:@"%@/%@/stop-places/by-key?keyType=STADA&key=%@&limit=10&onlyActive=false",[Constants kDBAPI], [Constants kRISStationsPath],stadaNumber];
    NSLog(@"RIS:Stations: %@",requestUrlWithParams);
    [self.sessionManager GET:requestUrlWithParams parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        //
    } success:^(NSURLSessionTask *operation, id responseObject) {
        
        if(simulateSearchFailure){
            failure(nil);
            return;
        }

        if([responseObject isKindOfClass:NSDictionary.class]){
            MBStationFromSearch* res = [self parseResponse:responseObject].firstObject;
            res.isFreshStationFromSearch = false;
            if(res){
                [MBCacheManager.sharedManager storeResponse:responseObject forStationId:cacheKey type:type];
                success(res);
            } else {
                failure(nil);
            }
        } else {
            failure(nil);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"risstations by-key failed: %@",error.localizedDescription);
        failure(error);
    }];
}

-(void)searchStationByName:(NSString *)text success:(void (^)(NSArray<MBStationFromSearch*>* stationList))success failureBlock:(void (^)(NSError *))failure{
    NSString* searchTerm = [text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet letterCharacterSet]];
    NSInteger size = 100;
    NSString* requestUrlWithParams = [NSString stringWithFormat:@"%@/%@/stop-places/by-name/%@?limit=%ld",[Constants kDBAPI], [Constants kRISStationsPath],searchTerm,(long)size];

    NSLog(@"RIS:Stations: %@",requestUrlWithParams);
    [self.sessionManager GET:requestUrlWithParams parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
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

-(void)searchStationByGeo:(CLLocationCoordinate2D)geo success:(void (^)(NSArray<MBStationFromSearch*>* stationList))success failureBlock:(void (^)(NSError *))failure{
    NSInteger size = 100;
    NSString* requestUrlWithParams = [NSString stringWithFormat:@"%@/%@/stop-places/by-position?latitude=%.3f&longitude=%.3f&radius=2000&limit=%ld&onlyActive=false",
                            [Constants kDBAPI],
                            [Constants kRISStationsPath],
                            geo.latitude,
                            geo.longitude,
                            (long)size];

    NSLog(@"RIS:Stations: %@",requestUrlWithParams);

    [self.sessionManager GET:requestUrlWithParams parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
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

-(NSArray<MBStationFromSearch*>*)parseResponse:(NSDictionary*)response{
    NSArray* results = nil;
    if(![response isKindOfClass:NSDictionary.class]){
        return nil;
    }
    results = [response db_arrayForKey:@"stopPlaces"];
    if(results){
        MBStation* s = [MBStation new];
        
        NSMutableArray<MBStationFromSearch*>* resultsTransformed = [NSMutableArray arrayWithCapacity:results.count];
        for(NSDictionary* res in results){
            
            NSString* stationID = [res db_stringForKey:@"stationID"];
            if(stationID && [MBStation stationShouldBeLoadedAsOPNV:stationID]){
                stationID = nil;
            }
            NSString* evaNumber = [res db_stringForKey:@"evaNumber"];
            NSArray* evaNumbers = [res db_arrayForKey:@"groupMembers"];
            NSArray* availableTransports = [res db_arrayForKey:@"availableTransports"];
            if(availableTransports.count == 0){
                if(stationID && [s hasStaticAdHocBox:stationID]){
                    //use this: ensures that inactive Riedbahn stations are still displayed
                } else {
                    continue;//skip stations without any transports
                }
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
                MBStationFromSearch* res = [MBStationFromSearch new];
                res.isFreshStationFromSearch = true;
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

-(void)requestAccessibility:(NSString *)stationId success:(void (^)(NSArray<MBPlatformAccessibility*>* platformList))success failureBlock:(void (^)(NSError *))failure{
    
    MBCacheResponseType type = MBCacheResponseRISPlatforms;
    NSNumber* stationIdNum = [NSNumber numberWithLongLong:stationId.longLongValue];
    MBCacheState cacheState = [[MBCacheManager sharedManager] cacheStateForStationId:stationIdNum type:type];
    if(cacheState == MBCacheStateValid){
        NSDictionary* cachedResponse = [[MBCacheManager sharedManager] cachedResponseForStationId:stationIdNum type:type];
        NSMutableArray<MBPlatformAccessibility*>* list = [self parsePlatforms:cachedResponse];
        if(list){
            NSLog(@"using RIS: platforms data from cache!");
            success(list);
            return;
        }
    }
    
    NSString* requestUrlWithParams = [NSString stringWithFormat:@"%@/%@/platforms/by-key?includeAccessibility=true&includeSubPlatforms=false&keyType=STADA&key=%@",[Constants kDBAPI], [Constants kRISStationsPath], stationId];
    NSLog(@"RIS:Stations: %@",requestUrlWithParams);
    [self.sessionManager GET:requestUrlWithParams parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        //
    } success:^(NSURLSessionTask *operation, id responseObject) {
        if([responseObject isKindOfClass:NSDictionary.class]){
            NSDictionary* dict = responseObject;
            NSMutableArray<MBPlatformAccessibility*>* list = [self parsePlatforms:dict];
            if(list){
                [MBCacheManager.sharedManager storeResponse:dict forStationId:stationIdNum type:type];
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

-(NSMutableArray<MBPlatformAccessibility*>*)parsePlatforms:(NSDictionary*)dict{
    NSArray* platforms = [dict db_arrayForKey:@"platforms"];
    if(platforms){
        NSMutableArray<MBPlatformAccessibility*>* list = [NSMutableArray arrayWithCapacity:platforms.count];
        for(NSDictionary* platformsDict in platforms){
            if(![platformsDict isKindOfClass:NSDictionary.class]){
                continue;
            }
            MBPlatformAccessibility* pa = [MBPlatformAccessibility parseDict:platformsDict];
            if(pa){
                [list addObject:pa];
            }
        }
        return list;
    }
    return nil;
}


-(BOOL)platformlist:(NSArray<MBPlatformAccessibility*>*)list containsPlatformWithName:(NSString*)name{
    for(MBPlatformAccessibility* p in list){
        if([p.name isEqualToString:name]){
            return true;
        }
    }
    return false;
}



@end
