// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

@interface MBTrackingManager : NSObject

+(void)setupWithOptOut:(BOOL)optOut;
+(void)setCurrentStationForCrashTracking:(NSInteger)stationId;

+(void)trackPushMessageClick:(NSDictionary*)userInfo;

+(NSArray*)stationInfoArray;

+(void)trackState:(NSString*)state;
+(void)trackStateWithStationInfo:(NSString*)state;
+(void)trackAction:(NSString*)action;
+(void)trackActionWithStationInfo:(NSString*)action;


+(void)trackStatesWithStationInfo:(NSArray *)states;
+(void)trackStates:(NSArray *)states;
+(void)trackActionsWithStationInfo:(NSArray *)actions;
+(void)trackActions:(NSArray*)actions;
+(void)trackActions:(NSArray *)states withStationInfo:(BOOL)stationInfo additionalVariables:(NSDictionary*)variables;

+(void)setOptOut:(BOOL)optOut;

#define TRACK_KEY_DEPARTURE @"departure"
#define TRACK_KEY_TIMETABLE @"timetable"

@end
