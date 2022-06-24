// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MBTrainJourneyEvent : NSObject

-(MBTrainJourneyEvent *)initWithDict:(NSDictionary * _Nullable)dict;
-(BOOL)isArrival;

@property(nonatomic) BOOL additional;
@property(nonatomic) BOOL canceled;

@property(nonatomic,strong) NSString* name;
@property(nonatomic,strong) NSString* evaNumber;

@property(nonatomic,strong) NSString* _Nullable platform;
@property(nonatomic,strong) NSString* _Nullable platformSchedule;

@property(nonatomic,strong) NSString* _Nullable time;
@property(nonatomic,strong) NSString* _Nullable timeSchedule;

@property(nonatomic,strong) NSString* _Nullable type;
@property(nonatomic,strong) NSString* _Nullable timeType;

@property(nonatomic,strong) MBTrainJourneyEvent* linkedDepartureForThisArrival;

-(BOOL)isScheduleEvent;

@end

NS_ASSUME_NONNULL_END
