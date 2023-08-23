// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import "Stop.h"
#import "RIMapPoi.h"
#import "MBPXRShopCategory.h"
#import "MBService.h"
#import "HafasRequestManager.h"
#import "MBNews.h"


NS_ASSUME_NONNULL_BEGIN

#define CONTENT_SEARCH_KEY_STATIONINFO @"Bahnhofsinformation"

#define CONTENT_SEARCH_KEY_STATIONINFO_SEV @"Bahnhofsinformation Ersatzverkehr"
#define CONTENT_SEARCH_KEY_STATIONINFO_LOCKER @"Bahnhofsinformation Schließfächer"
#define CONTENT_SEARCH_KEY_STATIONINFO_ELEVATOR @"Bahnhofsinformation Aufzüge"
#define CONTENT_SEARCH_KEY_STATIONINFO_PARKING @"Bahnhofsinformation Parkplätze"
#define CONTENT_SEARCH_KEY_STATIONINFO_ACCESSIBILITY @"Bahnhofsinformation Barrierefreiheit"
#define CONTENT_SEARCH_KEY_STATIONINFO_WIFI @"Bahnhofsinformation WLAN"

//subcategory: Info & Services
#define CONTENT_SEARCH_KEY_STATIONINFO_SERVICES @"Bahnhofsinformation Info & Services"

#define CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_DBINFO @"Bahnhofsinformation Info & Services DB Information"
#define CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_MOBILITY_SERVICE @"Bahnhofsinformation Info & Services Mobilitätsservice"
#define CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_LOSTANDFOUND @"Bahnhofsinformation Info & Services Fundservice"
#define CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_3S @"Bahnhofsinformation Info & Services 3-S-Zentrale"
#define CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_LOUNGE @"Bahnhofsinformation Info & Services DB Lounge"
#define CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_TRAVELCENTER @"Bahnhofsinformation Info & Services DB Reisezentrum"
#define CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_MISSION @"Bahnhofsinformation Info & Services Bahnhofsmission"
#define CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_MOBILE_SERVICE @"Bahnhofsinformation Info & Services Mobiler Service"
#define CONTENT_SEARCH_KEY_STATIONFINO_SERVICES_CHATBOT @"Bahnhofsinformation Info & Services Chatbot"

//Station facilities
#define CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE @"Bahnhofsausstattung"

#define CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_ELEVATOR @"Bahnhofsausstattung Aufzüge"
#define CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_LOUNGE @"Bahnhofsausstattung DB Lounge"
#define CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_DBINFO @"Bahnhofsausstattung DB Info"
#define CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_TRAVELCENTER @"Bahnhofsausstattung DB Reisezentrum"
#define CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_PARKING @"Bahnhofsausstattung Parkplätze"
#define CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_LOCKER @"Bahnhofsausstattung Schließfächer"
#define CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_WIFI @"Bahnhofsausstattung WLAN"
#define CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_BIKEPARK @"Bahnhofsausstattung Fahrradstellplatz"
#define CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_TAXI @"Bahnhofsausstattung Taxistand"
#define CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_CARRENTAL @"Bahnhofsausstattung Mietwagen"
#define CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_WC @"Bahnhofsausstattung WC"
#define CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_TRAVELNECESSITIES @"Bahnhofsausstattung Reisebedarf"

#define CONTENT_SEARCH_KEY_MAP @"Karte"
#define CONTENT_SEARCH_KEY_SETTINGS @"Einstellungen"
#define CONTENT_SEARCH_KEY_FEEDBACK @"Feedback"
#define CONTENT_SEARCH_KEY_SHOP_AND_EAT @"Shoppen & Schlemmen"
#define CONTENT_SEARCH_KEY_OPNV @"ÖPNV Anschluss"
#define CONTENT_SEARCH_KEY_SHOP_OPEN @"Geöffnet"
#define CONTENT_SEARCH_KEY_TRAINORDER @"Wagenreihung"
#define CONTENT_SEARCH_KEY_DEPARTURES @"Abfahrtstafel"
#define CONTENT_SEARCH_KEY_ARRIVALS @"Ankunftstafel"

#define CONTENT_SEARCH_KEY_TRAVELPRODUCT @"Verkehrsmittel"
#define CONTENT_SEARCH_KEY_TRAVELPRODUCT_U_TRAIN @"Verkehrsmittel Ubahn"
#define CONTENT_SEARCH_KEY_TRAVELPRODUCT_S_TRAIN @"Verkehrsmittel S-Bahn"
#define CONTENT_SEARCH_KEY_TRAVELPRODUCT_TRAM @"Verkehrsmittel Tram"
#define CONTENT_SEARCH_KEY_TRAVELPRODUCT_BUS @"Verkehrsmittel Bus"
#define CONTENT_SEARCH_KEY_TRAVELPRODUCT_FERRY @"Verkehrsmittel Fähre"


@interface MBContentSearchResult : NSObject

//property for train table
@property(nonatomic,strong) Stop* stop;
@property(nonatomic) BOOL departure;

//property for shops
@property(nonatomic,strong) RIMapPoi* poi;
@property(nonatomic,strong) MBPXRShopCategory* poiCat;

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

+(MBContentSearchResult*)searchResultWithPlatform:(NSString*)platform;
+(MBContentSearchResult*)searchResultWithOPNV:(NSString*)lineIdentifier category:(HAFASProductCategory)category line:(NSString*)line;
//these are not used in the search but only for internal linking
+(MBContentSearchResult*)searchResultForChatbot;
+(MBContentSearchResult*)searchResultWithCoupon:(MBNews*)couponNews;
+(MBContentSearchResult*)searchResultForServiceNumbers;

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
-(BOOL)isSEVSearch;
-(BOOL)isLockerSearch;
-(BOOL)isElevatorSearch;

-(BOOL)isShopOpenSearch;
@end

NS_ASSUME_NONNULL_END
