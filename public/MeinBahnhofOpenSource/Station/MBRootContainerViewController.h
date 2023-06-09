// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBUIViewController.h"
#import "MBStation.h"
#import "MBStationTabBarViewController.h"

@class MBOverlayViewController;
@class MBTimetableViewController;
@class MBContentSearchResult;
@class MBServiceListCollectionViewController;

@protocol MBRootContainerViewControllerDelegate <NSObject>

@optional
-(void)willStartLoadingData;
-(void)didLoadStationData:(BOOL)success;
-(void)didLoadIndoorMapLevels:(BOOL)success;
-(void)didLoadMapPOIs:(BOOL)success;
-(void)didLoadEinkaufData:(BOOL)success;
-(void)didLoadFacilityData:(BOOL)success;
-(void)didFinishAllLoading;

//might be called async later after didFinishAllLoading
-(void)didLoadSEVData;
-(void)didLoadLockerData;
-(void)didLoadParkingData;
-(void)didLoadNewsData;
-(void)didLoadEinkaufsbahnhofStatus;


@end

@interface MBRootContainerViewController : MBUIViewController <UIGestureRecognizerDelegate, UIBarPositioningDelegate, MBStationTabBarViewControllerDelegate>

-(void)updateFacilityUI;

-(void)reloadStation;
@property(nonatomic,weak) id<MBRootContainerViewControllerDelegate> rootDelegate;
@property (nonatomic, strong) MBStationTabBarViewController *stationTabBarViewController;
@property(nonatomic) BOOL startWithDepartures;

+(void)presentViewControllerAsOverlay:(MBOverlayViewController*)vc allowNavigation:(BOOL)allowNavigation;
+(void)presentViewControllerAsOverlay:(MBOverlayViewController*)vc;
+(MBRootContainerViewController*)currentlyVisibleInstance;
+(UIViewController*)rootViewController;

-(UINavigationController*)stationContainerNavigationController;
-(UINavigationController*)timetableNavigationController;
-(MBTimetableViewController*)timetableVC;
-(MBServiceListCollectionViewController*)infoVC;
-(void)selectTimetableTab;
-(void)selectTimetableTabAndDeparturesForTrack:(NSString*)track trainOrder:(Stop*)trainStop;
-(void)cleanup;

-(void)handleSearchResult:(MBContentSearchResult*)search;
@end
