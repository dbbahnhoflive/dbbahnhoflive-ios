// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RIMapPoiOpenTime : NSObject

#define kWeekDayHoliday @"Feiertag"
#define kWeekDayMo @"Montag"
#define kWeekDayDi @"Dienstag"
#define kWeekDayMi @"Mittwoch"
#define kWeekDayDo @"Donnerstag"
#define kWeekDayFr @"Freitag"
#define kWeekDaySa @"Samstag"
#define kWeekDaySo @"Sonntag"

#define kWeekDayMoShort @"Mo"
#define kWeekDayDiShort @"Di"
#define kWeekDayMiShort @"Mi"
#define kWeekDayDoShort @"Do"
#define kWeekDayFrShort @"Fr"
#define kWeekDaySaShort @"Sa"
#define kWeekDaySoShort @"So"


@property(nonatomic,strong) NSString* daysDisplayString;
@property(nonatomic,strong) NSArray<NSString*>* days;//list of all the weeksdays with these openTimes
@property(nonatomic,strong) NSArray<NSString*>* openTimes;//list of hh:mm-hh:mm
@property(nonatomic,strong) NSArray<NSString*>* openTimesVoiceOver;//list of "hh Uhr mm bis hh Uhr mm"

-(BOOL)validForDay:(NSString*)weekday;
+(BOOL)isValidWeekday:(NSString*)s;
+(NSArray*)weekdayList;
+(NSArray *)weekdayListShort;
-(NSString*)openTimesStringForVoiceOver:(BOOL)voiceOver;
@end

NS_ASSUME_NONNULL_END
