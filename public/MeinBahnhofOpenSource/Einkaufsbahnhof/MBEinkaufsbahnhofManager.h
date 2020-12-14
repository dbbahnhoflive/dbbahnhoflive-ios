// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

@interface MBEinkaufsbahnhofManager : NSObject

+ (instancetype)sharedManager;

- (void)requestEinkaufPOI:(NSNumber*)stationId
                       forcedByUser:(BOOL)forcedByUser
                            success:(void (^)(NSArray *pois))success
                       failureBlock:(void (^)(NSError *error))failure;

-(void)requestAllEinkaufsbahnhofIdsForcedByUser:(BOOL)forcedByUser success:(void (^)(NSArray<NSNumber*> *))success failureBlock:(void (^)(NSError *))failure;
@end
