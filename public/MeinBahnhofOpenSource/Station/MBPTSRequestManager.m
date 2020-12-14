// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBPTSRequestManager.h"
#import "MBCacheManager.h"
#import "Constants.h"
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
    NSString* requestUrlWithParams = [NSString stringWithFormat:@"%@/%@/stop-places?size=%ld&name=%@",[Constants kBusinessHubProdBaseUrl], [Constants kPTSPath],(long)size,searchTerm];

    [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [self.requestSerializer setValue:[Constants kBusinesshubKey] forHTTPHeaderField:@"key"];
    NSLog(@"PTS: %@",requestUrlWithParams);
    return [self GET:requestUrlWithParams parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        //
    } success:^(NSURLSessionTask *operation, id responseObject) {
        
        if(simulateSearchFailure){
            failure(nil);
            return;
        }

        if([responseObject isKindOfClass:NSDictionary.class]){
            [MBTrackingManager trackActions:@[@"pts_request", @"text", @"success"]];
            success([self parseResponse:responseObject]);
        } else {
            [MBTrackingManager trackActions:@[@"pts_request", @"text", @"failure"]];
            failure(nil);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        [MBTrackingManager trackActions:@[@"pts_request", @"text", @"failure"]];
        NSLog(@"search failed: %@",error.localizedDescription);
        failure(error);
    }];
}

-(NSURLSessionTask *)searchStationByGeo:(CLLocationCoordinate2D)geo success:(void (^)(NSArray<MBPTSStationFromSearch*>* stationList))success failureBlock:(void (^)(NSError *))failure{
    NSInteger size = 100;
    NSString* requestUrlWithParams = [NSString stringWithFormat:@"%@/%@/stop-places?latitude=%.3f&longitude=%.3f&radius=2000&size=%ld",
                            [Constants kBusinessHubProdBaseUrl],
                            [Constants kPTSPath],
                            geo.latitude,
                            geo.longitude,
                            (long)size];

    [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [self.requestSerializer setValue:[Constants kBusinesshubKey] forHTTPHeaderField:@"key"];
    NSLog(@"PTS: %@",requestUrlWithParams);

    return [self GET:requestUrlWithParams parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        //
    } success:^(NSURLSessionTask *operation, id responseObject) {
        
        if(simulateSearchFailure){
            failure(nil);
            return;
        }

        if([responseObject isKindOfClass:NSDictionary.class]){
            [MBTrackingManager trackActions:@[@"pts_request", @"geo", @"success"]];
            success([self parseResponse:responseObject]);
        } else {
            [MBTrackingManager trackActions:@[@"pts_request", @"geo", @"failure"]];
            failure(nil);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        [MBTrackingManager trackActions:@[@"pts_request", @"geo", @"failure"]];
        failure(error);
    }];
}

-(NSArray<MBPTSStationFromSearch*>*)parseResponse:(NSDictionary*)response{
    NSArray* results = nil;
    if([response isKindOfClass:NSDictionary.class]){
        NSDictionary* emb = response[@"_embedded"];
        if(emb){
            results = emb[@"stopPlaceList"];
            if(!results){
                //empty search results, handle this as a valid empty response
                results = @[];
            }
        }
    }
    if(results){
        NSMutableArray<MBPTSStationFromSearch*>* resultsTransformed = [NSMutableArray arrayWithCapacity:results.count];
        for(NSDictionary* res in results){
            NSNumber* stationNumber = nil;
            NSString* evaId = nil;
            NSArray* identifiers = res[@"identifiers"];
            for(NSDictionary* identifier in identifiers){
                if([identifier[@"type"] isEqualToString:@"STADA"]){
                    NSString* stadaString = identifier[@"value"];
                    stationNumber = [NSNumber numberWithLongLong:stadaString.longLongValue];
                } else if([identifier[@"type"] isEqualToString:@"EVA"]){
                    evaId = identifier[@"value"];
                    if([evaId isKindOfClass:NSNumber.class]){
                        evaId = ((NSNumber*)evaId).stringValue;
                    } else if([evaId isKindOfClass:NSString.class]) {
                        //remove leading 0 by converting into number
                        evaId = [NSString stringWithFormat:@"%lld",evaId.longLongValue];
                        //NSLog(@"got eva %@ from identifier %@",evaId,identifier);
                    }
                }
            }
            NSString* title = res[@"name"];
            NSNumber* longitude = nil;
            NSNumber* latitude = nil;
            NSDictionary* location = res[@"location"];
            longitude = location[@"longitude"];
            latitude = location[@"latitude"];
            
            MBPTSStationResponse* parsedStation = [[MBPTSStationResponse alloc] initWithResponse:res];
            //NSLog(@"process %@, got evaIDS from parsedStation: %@",evaId,parsedStation.evaIds);
            NSArray* evaIds = parsedStation.evaIds;
            if(evaIds.count == 0 && evaId){
                //fallback to single evaid from identifiers
                evaIds = @[ evaId ];
            }
            
            if(title && evaIds.count > 0 && longitude && latitude){
                MBPTSStationFromSearch* res = [MBPTSStationFromSearch new];
                res.stationId = stationNumber;
                res.isOPNVStation = stationNumber == nil;
                res.title = title;
                res.eva_ids = evaIds;
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


@end
