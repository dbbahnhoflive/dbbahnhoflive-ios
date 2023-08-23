// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "FacilityStatus.h"

#define PUSH_FACILITY_TOPIC_PREFIX @"F"

@interface FacilityStatusManager : AFHTTPSessionManager<UIAlertViewDelegate>

+ (instancetype)client;
- (NSURLSessionTask *)requestFacilityStatus:(NSNumber*)stationId
                                          success:(void (^)(NSArray<FacilityStatus*> *facilityStatusItems))success
                                          failureBlock:(void (^)(NSError *error))failure;

- (NSURLSessionTask *)requestFacilityStatusForFacilities:(NSSet<NSString*>*)equipmentNumbers
                                                 success:(void (^)(NSArray<FacilityStatus*> *facilityStatusItems))success
                                            failureBlock:(void (^)(NSError *bhfError))failure;

-(void)disablePushForFacility:(NSString*)equipmentNumber completion:(void (^)(BOOL success,NSError *))completion;
-(void)enablePushForFacility:(NSString*)equipmentNumber completion:(void (^)(BOOL success,NSError *))completion;
-(void)setGlobalPushActive:(BOOL)active completion:(void (^)(NSError *))completion;
-(BOOL)isGlobalPushActive;
-(BOOL)isSystemPushActive;
-(BOOL)isPushActiveForFacility:(NSString*)equipmentNumber;
-(BOOL)isPushActiveForAtLeastOneFacility;

-(BOOL)isFavoriteFacility:(NSString*)equipmentNumber;
-(void)addToFavorites:(NSString*)equipmentNumber stationNumber:(NSString*)stationNumber stationName:(NSString*)stationName;
-(void)removeFromFavorites:(NSString*)equipmentNumber;
-(NSSet<NSString*>*)storedFavorites;

-(void)removeAll;
-(NSString*)stationNameForStationNumber:(NSString*)stationNumber;
-(void)handleRemoteNotification:(NSDictionary *)userInfo;

-(void)openFacilityStatusWithLocalNotification:(NSDictionary*)userInfo;

-(UIAlertController*)alertForPushNotActive;

//debug methods
-(void)registerDebugPushes;
-(void)removeDebugPushes;
-(void)validateTopics;

@end
