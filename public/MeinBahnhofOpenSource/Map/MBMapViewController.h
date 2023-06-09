// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBMapView.h"
#import "MBStation.h"
#import "MBMapConsent.h"

#define PRESET_STATION_INFO @"stationinfos"
#define PRESET_SHOPPING @"shopping"
#define PRESET_TIMETABLE @"timetable"
#define PRESET_DB_TIMETABLE @"db timetable"
#define PRESET_LOCAL_TIMETABLE @"local timetable"
#define PRESET_ELEVATORS @"elevators"
#define PRESET_PARKING @"parking"
#define PRESET_SEV @"local_timetable SEV"
#define PRESET_LOCKER @"locker"
#define PRESET_LUGGAGE @"luggage"

//used when opening the map for the shopping categories
#define PRESET_SHOPCAT_GROCERIES @"shop_groceries"
#define PRESET_SHOPCAT_GASTRO @"shop_gastro"
#define PRESET_SHOPCAT_BACKERY @"shop_bakery"
#define PRESET_SHOPCAT_SHOP @"shop_shop"
#define PRESET_SHOPCAT_HEALTH @"shop_health"
#define PRESET_SHOPCAT_SERVICES @"shop_services"
#define PRESET_SHOPCAT_PRESS @"shop_press"

#define PRESET_INFO_ONSITE @"info_on_site"

#define PRESET_INFO_MISSION @"stationmission"


//used in the station infrastructure view
#define PRESET_WIFI @"wifi"
#define PRESET_TOILET @"toilet"
#define PRESET_BIKE_PARKING @"bike_parking"
#define PRESET_TAXI @"taxi"
#define PRESET_CAR_RENTAL @"car_rental"
#define PRESET_DB_INFO @"db_info"
#define PRESET_TRIPCENTER @"tripcenter"
#define PRESET_DB_LOUNGE @"db_lounge"
#define PRESET_LOCKER @"locker"
#define PRESET_LOSTFOUND @"lostfound"

@class MBMarker;

@protocol MBMapViewControllerDelegate <NSObject>

@optional
-(id)mapSelectedPOI;
-(MBMarker*)mapSelectedMarker;//when this is implemented, mapSelectedPOI is not used!
-(BOOL)mapShouldCenterOnUser;
-(BOOL)mapDisplayFilter;//default is YES
-(NSArray<NSString*>*)mapFilterPresets;//one or of the preset keys defined above
-(NSArray *)mapNearbyStations;

@end

@interface MBMapViewController : UIViewController

-(void)configureWithStation:(MBStation*)station;
-(void)configureWithDelegate;//call only when configureWithStation is not used!

@property(nonatomic,weak) id<MBMapViewControllerDelegate> delegate;

+(NSMutableArray<NSString*>*)filterForFilterPresets:(NSArray<NSString*>*)filterPresets;

+(BOOL)canDisplayMap;

@end
