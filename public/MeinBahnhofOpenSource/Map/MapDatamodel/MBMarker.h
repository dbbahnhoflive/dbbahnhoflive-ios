// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <GoogleMaps/GoogleMaps.h>


@class RIMapPoi;

typedef NS_ENUM(NSUInteger, MBMarkerType) {
    MBMarkerType_VENUE = 2,
    MBMarkerType_FACILITY = 3,
    MBMarkerType_USER = 4,
    MBMarkerType_STATION = 5,//this is the currently opened station, it is not selectable on the map
    MBMarkerType_PARKING = 6,
    MBMarkerType_SERVICESTORE = 7,
    MBMarkerType_RIMAPPOI = 8,
    MBMarkerType_STATION_SELECTABLE = 9,
    MBMarkerType_OEPNV_SELECTABLE = 10,
    MBMarkerType_SEV = 11,
};


@interface MBMarker : GMSMarker <NSCopying>

@property (nonatomic, assign) MBMarkerType markerType;
@property (nonatomic, strong) NSString *category;
@property (nonatomic, strong) NSString *secondaryCategory;
@property (nonatomic, assign) BOOL outdoor;

@property (nonatomic, strong) RIMapPoi* riMapPoi;
@property (nonatomic) NSInteger zoomLevel;

@property (nonatomic, strong) UIImage* iconWithoutText;
@property (nonatomic, strong) UIImage* iconWithText;
@property (nonatomic) NSInteger zoomForIconWithText;

@property(nonatomic,strong) UIImage* iconNormal;
@property(nonatomic,strong) UIImage* iconLarge;


+ (instancetype)markerWithPosition:(CLLocationCoordinate2D)position andType:(MBMarkerType)type;
- (id)copyWithZone:(NSZone *)zone;

+ (void)renderTextIntoIconFor:(MBMarker *)marker markerIcon:(UIImage *)markerIcon titleText:(NSString *)titleText zoomForIconWithText:(NSInteger)zoomForIconWithText;
@end
