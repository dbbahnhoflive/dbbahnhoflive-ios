// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MBTutorialViewType)  {
    MBTutorialViewType_00_Hub_Start,
    MBTutorialViewType_00_Hub_Abfahrt,
    MBTutorialViewType_H1_Live,
    MBTutorialViewType_H1_Tips,
    MBTutorialViewType_H2_Departure,
    MBTutorialViewType_D1_ServiceStores_Details,
    MBTutorialViewType_D1_Aufzuege,
    MBTutorialViewType_D1_Parking,
    MBTutorialViewType_F3_Map,
    MBTutorialViewType_F3_Map_Departures,
    MBTutorialViewType_H1_Search,
    MBTutorialViewType_H1_Coupons,
} ;

@interface MBTutorial : NSObject

@property(nonatomic) MBTutorialViewType identifier;
@property(nonatomic,strong) NSString* title;
@property(nonatomic,strong) NSString* text;
@property(nonatomic) NSInteger currentCount;
@property(nonatomic) NSInteger countdown;
@property(nonatomic) BOOL closedByUser;

+(MBTutorial*)tutorialWithIdentifier:(MBTutorialViewType)identifier title:(NSString*)title text:(NSString*)text countdown:(NSInteger)countdown;
-(instancetype)initWithIdentifier:(MBTutorialViewType)identifier title:(NSString*)title text:(NSString*)text countdown:(NSInteger)countdown;

@end
