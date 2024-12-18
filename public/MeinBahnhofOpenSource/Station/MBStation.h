// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "MBStationDetails.h"

@class MBTravelcenter;
@class MBOPNVStation;
@class MBMarker;
@class RIMapPoi;
@class RIMapSEV;
@class MBLocker;
@class GMSMarker;
@class MBNews;
@class MBParkingInfo;
@class LevelplanWrapper;
@class MBPXRShopCategory;
@class FacilityStatus;
@class MBPlatformAccessibility;
@class MBStationFromSearch;

@interface MBStation : NSObject

@property (nonatomic, copy, readonly) NSNumber *mbId;//station id (stada)
@property (nonatomic, copy, readonly) NSString *title;

@property (nonatomic, strong, readwrite) NSArray<LevelplanWrapper*> *levels;

@property(nonatomic,strong) MBTravelcenter* travelCenter;

@property (nonatomic, strong) NSArray<RIMapPoi*>* riPois;
@property (nonatomic, strong) NSArray<MBPXRShopCategory*>* riPoiCategories;
@property (nonatomic, strong) NSArray<RIMapSEV*>* sevPois;
@property (nonatomic, strong) NSArray<MBLocker*>* lockerList;

// FacilityStatus
@property (nonatomic, strong) NSArray<FacilityStatus*> *facilityStatusPOIs;

// Parking
@property( nonatomic,strong) NSArray<MBParkingInfo*>* parkingInfoItems;

// RIS:Station Details
@property(nonatomic,strong) MBStationDetails* stationDetails;

// Hafas
@property(nonatomic,strong) NSArray<MBOPNVStation*>* nearestStationsForOPNV;

@property(nonatomic,strong) NSArray<MBNews*>* newsList;//includes news+coupons
@property(nonatomic,strong) NSArray<MBNews*>* couponsList;

@property(nonatomic,strong) id occupancy;

-(instancetype)initWithId:(NSNumber *)stationId name:(NSString *)title evaIds:(NSArray<NSString*>*)evaIds location:(NSArray<NSNumber*>*)location;

- (NSArray<NSString*>*)stationEvaIds;
- (CLLocationCoordinate2D) positionAsLatLng;

- (GMSMarker*)markerForStation;

-(BOOL)displayStationMap;
-(BOOL)hasDirtService;
-(BOOL)hasShops;
-(BOOL)isGreenStation;
-(BOOL)hasChatbot;
-(BOOL)hasOccupancy;
-(BOOL)useOSM;
-(BOOL)hasSEVStations;
-(BOOL)hasStaticAdHocBox;
-(BOOL)hasStaticAdHocBox:(NSString*)stationId;
-(void)testSEVStationsDataIntegrity;
-(NSArray<MBStationFromSearch*>*)sevStationsMatchingSearchString:(NSString*)text;
-(BOOL)hasARTeaser;
-(BOOL)hasAccompanimentService;
-(NSArray<NSString*>*)accompanimentStationsTitles;
-(BOOL)hasAccompanimentServiceActive;
+(BOOL)stationShouldBeLoadedAsOPNV:(NSString*)stationId;

+ (NSArray<NSString*>*) categoriesForShoppen;

-(NSArray<MBMarker*>*)getFacilityMapMarker;
-(NSArray<MBMarker*>*)getSEVMapMarker;

-(void)updateEvaIds:(NSArray<NSString*>*)evaIds;
-(void)updateStationWithDetails:(MBStationDetails*)details;
-(void)parseOpeningTimesWithCompletion:(void (^)(void))completion;

-(NSString*)isAdditionalEvaId_MappedToMainEva:(NSString*)evaId;

-(void)addPlatformAccessibility:(NSArray<MBPlatformAccessibility *> *)platformList;
-(NSArray<MBPlatformAccessibility*>*)platformAccessibility;
-(NSArray<MBPlatformAccessibility*>*)platformForTrackInfo;
-(RIMapPoi*)poiForPlatform:(NSString*)platformNumber;
-(NSString*)linkedPlatformForPlatform:(NSString*)platform;
-(NSArray<NSString*>*)linkedPlatformsForPlatform:(NSString*)platform;
-(BOOL)platformIsHeadPlatform:(NSString*)platform;
-(NSString*)levelForPlatform:(NSString*)platform;
-(void)addLevelInformationToPlatformAccessibility;
+(BOOL)displayPlaformInfo;
@end
