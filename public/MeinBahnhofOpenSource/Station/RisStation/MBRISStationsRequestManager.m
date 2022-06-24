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
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        sharedClient = [[self alloc] init];
        if(MBTestHelper.isTestRun){
            sharedClient.sessionManager = [[MBAFNetworkMock alloc] initWithSessionConfiguration:configuration];
        } else {
            sharedClient.sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
        }
        [sharedClient.sessionManager.requestSerializer setValue:@"application/json, application/vnd.de.db.ris+json, */*" forHTTPHeaderField:@"Accept"];

        [sharedClient.sessionManager.requestSerializer setValue:[Constants dbAPIKey] forHTTPHeaderField:@"db-api-key"];
        [sharedClient.sessionManager.requestSerializer setValue:[Constants dbAPIClient] forHTTPHeaderField:@"db-client-id"];
        sharedClient.sessionManager.responseSerializer.acceptableContentTypes = [sharedClient.sessionManager.responseSerializer.acceptableContentTypes setByAddingObject:@"application/vnd.de.db.ris+json"];


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
        NSLog(@"using RIS:Station:services data from cache!");
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

-(void)requestStationData:(NSNumber *)stationId forcedByUser:(BOOL)forcedByUser success:(void (^)(MBStationDetails *response))success failureBlock:(void (^)(NSError *))failure{
    
    //we combine the results from two requests here
    
    MBCacheResponseType type = MBCacheResponseRISStationServices;
    MBCacheState cacheState = [[MBCacheManager sharedManager] cacheStateForStationId:stationId type:type];
    if(forcedByUser && cacheState == MBCacheStateValid){
        cacheState = MBCacheStateOutdated;
    }
    if(cacheState == MBCacheStateValid){
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
    NSString* requestUrlWithParams = [NSString stringWithFormat:@"%@/%@/stop-places/by-position?latitude=%.3f&longitude=%.3f&radius=2000&limit=%ld",
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

-(void)requestAccessibility:(NSString *)eva success:(void (^)(NSArray<MBPlatformAccessibility*>* platformList))success failureBlock:(void (^)(NSError *))failure{
    NSString* requestUrlWithParams = [NSString stringWithFormat:@"%@/%@/platforms/%@?includeAccessibility=true",[Constants kDBAPI], [Constants kRISStationsPath],eva];
    NSLog(@"RIS:Stations: %@",requestUrlWithParams);
    [self.sessionManager GET:requestUrlWithParams parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
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


-(void)requestEvaIdsForStation:(MBStationFromSearch*)station success:(void (^)(NSArray<NSString*>* evaIds))success failureBlock:(void (^)(NSError *))failure{
    NSString* searchTerm = [station.title stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet letterCharacterSet]];
    NSString* requestUrlWithParams = [NSString stringWithFormat:@"%@/%@/stop-places/by-name/%@",[Constants kDBAPI], [Constants kRISStationsPath], searchTerm];
    NSLog(@"RIS:Stations: %@",requestUrlWithParams);
    [self.sessionManager GET:requestUrlWithParams parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        //
    } success:^(NSURLSessionTask *operation, id responseObject) {
        
        if([responseObject isKindOfClass:NSDictionary.class]){
            NSArray* stations = [self parseResponse:responseObject];
            for(MBStationFromSearch* searchResult in stations){
                if([searchResult.stationId isEqualToNumber:station.stationId]){
                    success(searchResult.eva_ids);
                    return;
                }
            }
            NSLog(@"Error: station not found in search");
        }
        failure(nil);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"risstations stopPlaces failed: %@",error.localizedDescription);
        failure(error);
    }];
}

@end
