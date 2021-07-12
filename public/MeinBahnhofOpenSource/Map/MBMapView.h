// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import "LevelplanWrapper.h"
#import "MBMapFlyout.h"
#import "MBStation.h"

typedef NS_ENUM(NSInteger, MAP_TYPE) {
    OSM = 0,
    GOOGLE = 1
};




#define MAX_ZOOM_NOINDOOR_OSM 17.00001

#define MAX_ZOOM_REST 20.00001

#define DEFAULT_ZOOM_LEVEL_WITH_INDOOR 17

#define DEFAULT_ZOOM_LEVEL_WITHOUT_INDOOR 17

@class Venue, MBMapView, MBParkingInfo;

@protocol MBMapViewDelegate <NSObject>

@optional
- (void) showRoutingForParking:(MBParkingInfo*)parking;
- (void) showFacilityFavorites;
//- (void) showViewController:(UIViewController*)vc;

- (void) didTapOnFilterToggleButton:(id)sender;
- (void) showRoutingControllerFor:(MBMarker*)item;
- (void) mapViewIdleAtLocation:(CLLocationCoordinate2D)location;

- (void) willOpenFlyoutOnMapView:(MBMapView*)mapView marker:(MBMarker*)marker;
- (void) didCloseFlyoutMapView:(MBMapView*)mapView;
- (void) mapView:(MBMapView*)mapView didChangeLevelTo:(LevelplanWrapper*)level;

- (void) didChangeVisiblePOIList;

@end

@interface MBMapView : UIView <GMSMapViewDelegate, MBMapFlyoutDelegate>

@property (nonatomic, weak) id<MBMapViewDelegate>delegate;
@property (nonatomic, strong) LevelplanWrapper *currentLevel;

@property (nonatomic, strong) NSArray *levels;

@property (nonatomic, strong) NSMutableArray *filterValues;

@property (nonatomic, assign) BOOL filterMarkerByLevel;
@property (nonatomic, strong) NSArray *nearbyStations;

@property (nonatomic, assign) BOOL supportsIndoor;
@property (nonatomic, assign) BOOL showFilterToggle;
@property (nonatomic, assign) BOOL showLinkToDetail;
@property (nonatomic, assign) BOOL cameraFollowsUser;

@property (nonatomic, assign) int defaultZoomLevel;

@property (nonatomic,strong) MBStation* station;


- (instancetype) initMapViewWithFrame:(CGRect)frame;

- (void) showUserMarkerAtLocation:(CLLocation*)location animate:(BOOL)animate;

- (void) moveCameraTo:(GMSCameraPosition*)cameraPosition animated:(BOOL)animated;
- (void) moveCameraToUser:(GMSCameraPosition*)cameraPosition animated:(BOOL)animated;

// MapView Lifecycle
- (void) resume;
- (void) suspend;

- (void)updateNearbyStationsMarker;

-(void)configureMapForStation:(MBStation*)station;

-(void)userDidTapOnPinToUserButton:(id)sender;

-(void)setMapType:(MAP_TYPE)newMapType;
-(void)setPOIs:(NSArray*)riPois;
-(void)updateMobilityMarker:(NSArray*)mobilityMarker;
- (void) updateMarkers;
-(MBMarker*)preselectMarkerAfterFilterChange;
-(void)updateFacilityMarker;
-(void)selectAndCenterMarker:(MBMarker*)marker;
-(void)removeMarkerSelection;
-(BOOL)hasMarkerSelected;

-(void)setPOISelected:(id)poi;
-(void)updatePositionAndZoomForMarker:(MBMarker*)marker animated:(BOOL)animated;
-(MBMarker*)findMarkerForPOI:(id)poi;
-(NSArray<MBMarker*>*)visiblePOIList;
@end
