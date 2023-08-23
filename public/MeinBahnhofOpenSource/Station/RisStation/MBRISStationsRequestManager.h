// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <AFNetworking/AFNetworking.h>
#import "MBStationDetails.h"
#import "MBStationFromSearch.h"
#import "MBPlatformAccessibility.h"

@interface MBRISStationsRequestManager  : NSObject

+ (MBRISStationsRequestManager*)sharedInstance;
- (void)requestStationData:(NSNumber*)stationId
                            forcedByUser:(BOOL)forcedByUser
                                    success:(void (^)(MBStationDetails *response))success
                               failureBlock:(void (^)(NSError *error))failure;

-(void)searchStationByEva:(NSString *)evaNumber success:(void (^)(MBStationFromSearch* station))success failureBlock:(void (^)(NSError *))failure;

- (void)searchStationByName:(NSString*)text
        success:(void (^)(NSArray<MBStationFromSearch*>* stationList))success
   failureBlock:(void (^)(NSError *error))failure;

- (void)searchStationByGeo:(CLLocationCoordinate2D)geo
     success:(void (^)(NSArray<MBStationFromSearch*>* stationList))success
failureBlock:(void (^)(NSError *error))failure;

-(void)requestEvaIdsForStation:(MBStationFromSearch*)station success:(void (^)(NSArray<NSString*>* evaIds))success failureBlock:(void (^)(NSError *))failure;

-(void)requestAccessibility:(NSString *)stationId success:(void (^)(NSArray<MBPlatformAccessibility*>* platformList))success failureBlock:(void (^)(NSError *))failure;
@end
