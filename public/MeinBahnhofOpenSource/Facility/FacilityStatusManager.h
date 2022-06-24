// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "FacilityStatus.h"

#define kFacilityStatusManagerGlobalPushChangedNotification @"kFacilityStatusManagerGlobalPushChangedNotification"

@interface FacilityStatusManager : AFHTTPSessionManager<UIAlertViewDelegate>

+ (instancetype)client;
- (NSURLSessionTask *)requestFacilityStatus:(NSNumber*)stationId
                                          success:(void (^)(NSArray<FacilityStatus*> *facilityStatusItems))success
                                          failureBlock:(void (^)(NSError *error))failure;

- (NSURLSessionTask *)requestFacilityStatusForFacilities:(NSSet<NSString*>*)equipmentNumbers
                                                 success:(void (^)(NSArray<FacilityStatus*> *facilityStatusItems))success
                                            failureBlock:(void (^)(NSError *bhfError))failure;

-(void)disablePushForFacility:(NSString*)equipmentNumber;
-(void)enablePushForFacility:(NSString*)equipmentNumber stationNumber:(NSString*)stationNumber stationName:(NSString*)stationName;
-(void)setGlobalPushActive:(BOOL)active;
-(BOOL)isGlobalPushActive;
-(BOOL)isPushActiveForFacility:(NSString*)equipmentNumber;
-(BOOL)isFavoriteFacility:(NSString*)equipmentNumber;
-(void)removeFromFavorites:(NSString*)equipmentNumber;
-(NSSet*)storedFavorites;
-(void)removeAll;
-(NSString*)stationNameForStationNumber:(NSString*)stationNumber;
-(void)handleRemoteNotification:(NSDictionary *)userInfo;

-(void)openFacilityStatusWithLocalNotification:(NSDictionary*)userInfo;

@end
