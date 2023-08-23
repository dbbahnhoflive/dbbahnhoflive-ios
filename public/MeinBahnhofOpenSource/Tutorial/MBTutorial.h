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
    MBTutorialViewType_H1_FacilityPush,
    MBTutorialViewType_D1_FacilityPush,
    MBTutorialViewType_Zuglauf_StationLink,
} ;

@interface MBTutorial : NSObject

typedef BOOL (^TutorialRuleBlock)(MBTutorial*);

@property(nonatomic) MBTutorialViewType identifier;
@property(nonatomic,strong) NSString* title;
@property(nonatomic,strong) NSString* text;
@property(nonatomic) NSInteger currentCount;
@property(nonatomic) NSInteger countdown;
@property(nonatomic) BOOL closedByUser;
@property(nonatomic) BOOL markedAsAbsolete;
@property (nonatomic, copy) TutorialRuleBlock ruleBlock;

+(MBTutorial *)tutorialWithIdentifier:(MBTutorialViewType)identifier title:(NSString *)title text:(NSString *)text countdown:(NSInteger)countdown;
+(MBTutorial*)tutorialWithIdentifier:(MBTutorialViewType)identifier title:(NSString*)title text:(NSString*)text countdown:(NSInteger)countdown ruleBlock:(TutorialRuleBlock)ruleBlock;

@end
