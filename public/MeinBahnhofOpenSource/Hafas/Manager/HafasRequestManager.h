// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM(NSUInteger, HAFASProductCategory) {
    HAFASProductCategoryNONE = 0,
    HAFASProductCategoryICE = 1,//klasse 0
    HAFASProductCategoryIC  = 2,//klasse 1
    HAFASProductCategoryIR  = 4,//klasse 2
    HAFASProductCategoryREGIO  = 8,//klasse 3
    HAFASProductCategoryS  = 16,//klasse 4
    HAFASProductCategoryBUS  = 32,//klasse 5
    HAFASProductCategorySHIP = 64,//klasse 6
    HAFASProductCategoryU = 128,//klasse 7
    HAFASProductCategoryTRAM = 256,//klasse 8
    HAFASProductCategoryCAL = 512,//klasse 9
};

#define HAFAS_LOCAL (HAFASProductCategoryBUS | HAFASProductCategorySHIP | HAFASProductCategoryU | HAFASProductCategoryTRAM | HAFASProductCategoryCAL)

#define HAFAS_NONLOCAL_BITMASK (HAFASProductCategoryICE | HAFASProductCategoryIC | HAFASProductCategoryIR | HAFASProductCategoryREGIO | HAFASProductCategoryS)

@class HafasDeparture;
@class MBOPNVStation;
@class HafasTimetable;

@interface HafasRequestManager : NSObject

+ (instancetype)sharedManager;

-(void)requestNearbyStopsForCoordinate:(CLLocationCoordinate2D)coordinate filterOutDBStation:(BOOL)filterOutDBStation withCompletion:(void(^)(NSArray<MBOPNVStation*> *nearbyStations))completion;

- (void)loadDeparturesForStopId:(NSString *)stationId timetable:(HafasTimetable*)timetable withCompletion:(void(^)(HafasTimetable *timetable))completion;
-(void)requestJourneyDetails:(HafasDeparture*)departure completion:(void(^)(HafasDeparture *, NSError *))completion;

- (void)manualRefresh:(HafasTimetable*)timetable withCompletion:(void (^)(HafasTimetable *))completion;



@end
