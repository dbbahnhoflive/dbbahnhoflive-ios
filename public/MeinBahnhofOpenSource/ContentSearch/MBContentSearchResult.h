// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import "Stop.h"
#import "RIMapPoi.h"
#import "MBPXRShopCategory.h"
#import "MBEinkaufsbahnhofStore.h"
#import "MBEinkaufsbahnhofCategory.h"
#import "MBService.h"
#import "HafasRequestManager.h"
#import "MBNews.h"


NS_ASSUME_NONNULL_BEGIN

#define CONTENT_SEARCH_KEY_STATIONINFO_INFOSERVICE_DBINFO @"Bahnhofsinformation Info & Services DB Information"

@interface MBContentSearchResult : NSObject

//property for train table
@property(nonatomic,strong) Stop* stop;
@property(nonatomic) BOOL departure;

//property for shops
@property(nonatomic,strong) RIMapPoi* poi;
@property(nonatomic,strong) MBPXRShopCategory* poiCat;
@property(nonatomic,strong) MBEinkaufsbahnhofStore* store;
@property(nonatomic,strong) MBEinkaufsbahnhofCategory* storeCat;

//property for info services
@property(nonatomic,strong) MBService* service;

@property(nonatomic,strong) NSString* platformSearch;

//property for opnv
@property(nonatomic,strong) NSString* opnvLineIdentifier;
@property(nonatomic) HAFASProductCategory opnvCat;
@property(nonatomic) NSString* opnvLine;

@property(nonatomic,strong) NSString* searchText;

@property(nonatomic,strong) MBNews* couponItem;


//special type for past searches and search suggestions
+(MBContentSearchResult*)searchResultWithSearchText:(NSString*)searchText;

+(MBContentSearchResult*)searchResultWithStop:(Stop*)stop departure:(BOOL)departure;
+(MBContentSearchResult*)searchResultWithKeywords:(NSString*)key;
+(MBContentSearchResult*)searchResultWithPOI:(nullable RIMapPoi*)poi inCat:(MBPXRShopCategory*)cat;
+(MBContentSearchResult*)searchResultWithStore:(nullable MBEinkaufsbahnhofStore*)poi inCat:(MBEinkaufsbahnhofCategory*)cat;
+(MBContentSearchResult*)searchResultWithPlatform:(NSString*)platform;
+(MBContentSearchResult*)searchResultWithOPNV:(NSString*)lineIdentifier category:(HAFASProductCategory)category line:(NSString*)line;
//these two are not used in the search but only for internal linking
+(MBContentSearchResult*)searchResultForChatbot;
+(MBContentSearchResult *)searchResultForPickpack;
+(MBContentSearchResult*)searchResultWithCoupon:(MBNews*)couponNews;

-(NSString*)title;
-(NSString*)iconName;
- (NSComparisonResult)compare:(MBContentSearchResult *)other;

-(BOOL)isTextSearch;

-(BOOL)isTimetableSearch;
-(BOOL)isOPNVSearch;
-(HAFASProductCategory)hafasProductForKeyword;
-(BOOL)isPlatformSearch;
-(BOOL)isWagenreihung;
-(BOOL)isShopSearch;
-(BOOL)isMapSearch;
-(BOOL)isSettingSearch;
-(BOOL)isFeedbackSearch;
-(BOOL)isOPNVOverviewSearch;
-(BOOL)isStationFeatureSearch;
-(BOOL)isStationInfoSearch;
-(BOOL)isChatBotSearch;
-(BOOL)isPickpackSearch;

-(BOOL)isStationInfoLocalServicesSearch;
-(BOOL)isLocalServiceDBInfo;
-(BOOL)isLocalServiceMobileService;
-(BOOL)isLocalMission;
-(BOOL)isLocalTravelCenter;
-(BOOL)isLocalLounge;

-(BOOL)isStationInfoPhoneSearch;
-(BOOL)isStationInfoPhoneMobility;
-(BOOL)isStationInfoPhone3S;
-(BOOL)isStationInfoPhoneLostservice;

-(BOOL)isParkingSearch;
-(BOOL)isSteplessAccessSearch;
-(BOOL)isWifiSearch;
-(BOOL)isElevatorSearch;

-(BOOL)isShopOpenSearch;
@end

NS_ASSUME_NONNULL_END
