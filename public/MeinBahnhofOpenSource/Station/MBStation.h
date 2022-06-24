// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <Mantle/Mantle.h>
#import "MBStationDetails.h"


#define STATION_ID_BERLIN_HBF 1071
#define STATION_ID_FRANKFURT_MAIN_HBF 1866
#define STATION_ID_HAMBURG_HBF 2514
#define STATION_ID_MUENCHEN_HBF 4234
#define STATION_ID_KOELN_HBF 3320

@class MBTravelcenter;
@class MBOPNVStation;
@class MBMarker;
@class RIMapPoi;
@class RIMapMetaData;
@class RIMapSEV;
@class GMSMarker;
@class MBNews;
@class MBParkingInfo;
@class MBEinkaufsbahnhofCategory;
@class LevelplanWrapper;
@class MBPXRShopCategory;
@class FacilityStatus;
@class MBPlatformAccessibility;

@interface MBStation : NSObject

@property (nonatomic, copy, readonly) NSNumber *mbId;//station id (stada)
@property (nonatomic, copy, readonly) NSString *title;

@property (nonatomic, strong) NSArray<MBEinkaufsbahnhofCategory*> *einkaufsbahnhofCategories;
@property (nonatomic) BOOL isEinkaufsbahnhof;


@property (nonatomic, strong, readwrite) NSArray<LevelplanWrapper*> *levels;
@property(nonatomic,strong) RIMapMetaData* additionalRiMapData;

@property(nonatomic,strong) MBTravelcenter* travelCenter;

@property (nonatomic, strong) NSArray<RIMapPoi*>* riPois;
@property (nonatomic, strong) NSArray<MBPXRShopCategory*>* riPoiCategories;
@property (nonatomic, strong) NSArray<RIMapSEV*>* sevPois;

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
-(BOOL)hasPickPack;
-(BOOL)hasOccupancy;
-(BOOL)useOSM;
-(BOOL)hasSEVStations;
+(BOOL)stationShouldBeLoadedAsOPNV:(NSString*)stationId;

+ (NSArray<NSString*>*) categoriesForShoppen;

-(NSArray<MBMarker*>*)getFacilityMapMarker;
-(NSArray<MBMarker*>*)getSEVMapMarker;

-(void)updateStationWithDetails:(MBStationDetails*)details;
-(void)parseOpeningTimesWithCompletion:(void (^)(void))completion;
-(void)addPlatformAccessibility:(NSArray<MBPlatformAccessibility *> *)platformList;
-(NSArray<MBPlatformAccessibility*>*)platformAccessibility;

-(RIMapPoi*)poiForPlatform:(NSString*)platformNumber;

+(NSString*)platformNumberFromPlatform:(NSString*)platform;

@end
