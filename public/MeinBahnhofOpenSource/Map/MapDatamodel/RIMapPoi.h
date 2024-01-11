// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Mantle/Mantle.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "MBPXRShopCategory.h"
#import "RIMapPoiOpenTime.h"

@class MBMarker;
@class RIMapConfigItem;
@class POIFilterItem;

typedef NS_ENUM(NSInteger, ShopOpenState) {
    POI_OPEN = 1,
    POI_CLOSED = 2,
    POI_UNKNOWN = 3
};

@interface RIMapPoi : MTLModel <MTLJSONSerializing>

@property(nonatomic,strong,readonly) NSNumber* idNum;

//@property(nonatomic,strong,readonly) NSString* src_layer;//no longer used
@property(nonatomic,strong,readonly) NSString* levelcode;
@property(nonatomic,strong,readonly) NSString* type;
@property(nonatomic,strong,readonly) NSString* category;//no longer used
@property(nonatomic,strong,readonly) NSString* name;
@property(nonatomic,strong,readonly) NSString* displname;
@property(nonatomic,strong,readonly) NSString* displmap;//no longer used
@property(nonatomic,strong,readonly) NSString* detail;
@property(nonatomic,strong,readonly) NSString* tags;

@property(nonatomic,strong,readonly) NSString* menucat;
@property(nonatomic,strong,readonly) NSString* menusubcat;
@property(nonatomic,strong,readonly) NSNumber* display_x;
@property(nonatomic,strong,readonly) NSNumber* display_y;

@property(nonatomic,strong,readonly) NSString* day_1;
@property(nonatomic,strong,readonly) NSString* day_2;
@property(nonatomic,strong,readonly) NSString* day_3;
@property(nonatomic,strong,readonly) NSString* day_4;
@property(nonatomic,strong,readonly) NSString* time_1;
@property(nonatomic,strong,readonly) NSString* time_2;
@property(nonatomic,strong,readonly) NSString* time_3;
@property(nonatomic,strong,readonly) NSString* time_4;

@property(nonatomic,strong) NSArray<RIMapPoiOpenTime*>* openingTimes;

@property(nonatomic,strong,readonly) NSArray* bbox;

@property(nonatomic,strong) NSString* phone;
@property(nonatomic,strong) NSString* email;
@property(nonatomic,strong) NSString* website;

-(MBMarker*)mapMarker;
-(NSInteger)mapZoomLevel;
-(NSString*)lowCaseLevelCode;
-(BOOL)isValid;
-(BOOL)hasOpeningInfo;
-(BOOL)isOpen;
-(NSTimeInterval)isOpenTime;

-(NSString*)allOpenTimes;
-(NSString *)allOpenTimesForVoiceOver:(BOOL)voiceOver;
-(BOOL)isTrack;
-(BOOL)isLocker;
-(UIImage*)iconImageForFlyout:(BOOL)forFlyout;
-(NSString*)iconNameForFlyout:(BOOL)forFlyout;
-(NSString*)title;
-(CLLocationCoordinate2D)center;

-(BOOL)isDBInfoPOI;

-(void)getFilterTitle:(NSString**)filterTitle andSubTitle:(NSString**)filterSubTitle;

+(NSArray<POIFilterItem*>*)createFilterItems;
+(NSArray*)filterConfig;
+(RIMapConfigItem*)configForMenuCat:(NSString*)cat subCat:(NSString*)subcat;
+(NSString*)levelCodeToDisplayString:(NSString*)levelCode;
+(NSString*)levelCodeToDisplayStringShort:(NSString*)levelCode;
+(NSArray<NSString*>*)levelList;
+(NSArray<NSString*>*)levelListShort;

+(NSString*)mapPXRToShopCategory:(RIMapPoi*)poi;
+(NSArray*)mapShopCategoryToFilterPresets:(NSString*)shopCategory;

+(NSArray<MBPXRShopCategory*>*)generatePXRGroups:(NSArray<RIMapPoi*>*)pois;
@end
