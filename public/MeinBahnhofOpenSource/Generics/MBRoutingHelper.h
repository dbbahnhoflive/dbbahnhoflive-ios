// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "MBParkingInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBRoutingHelper : NSObject
+ (BOOL) hasGoogleMaps;
+ (BOOL) hasAppleMaps;
+(void)showRoutingForParking:(MBParkingInfo *)parking fromViewController:(UIViewController*)fromViewController;
+(void)routeToName:(NSString*)name location:(CLLocationCoordinate2D)location  fromViewController:(UIViewController* _Nullable)fromViewController;

@end

NS_ASSUME_NONNULL_END
