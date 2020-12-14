// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBTrackingManager.h"

@implementation MBTrackingManager

+(void)setupWithOptOut:(BOOL)optOut{}
+(void)setCurrentStationForCrashTracking:(NSInteger)stationId{}
+(void)trackPushMessageClick:(NSDictionary *)userInfo{}
+ (void)setOptOut:(BOOL)optOut{}
+ (NSArray *)stationInfoArray{ return nil; }
+(NSString *)mapShopTitleToTrackingName:(NSString *)internalName{
    return @"";
}
+(NSString *)mapMainMenuTypeToTrackingName:(NSString *)type{
    return @"";
}
+(NSString *)mapInternalServiceToTrackingName:(NSString *)internalName{
    return @"";
}
+(void)trackAction:(NSString *)action{}
+(void)trackActions:(NSArray *)actions{}
+(void)trackActionWithStationInfo:(NSString *)action{}
+(void)trackActionsWithStationInfo:(NSArray *)actions{}
+(void)trackActions:(NSArray *)states withStationInfo:(BOOL)stationInfo additionalVariables:(NSDictionary *)variables{}

+ (void)trackState:(NSString *)state{}
+(void)trackStates:(NSArray *)states{}
+(void)trackStateWithStationInfo:(NSString *)state{}
+(void)trackStatesWithStationInfo:(NSArray *)states{}

@end
