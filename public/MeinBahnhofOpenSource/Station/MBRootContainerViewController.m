// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBRootContainerViewController.h"

#import "MBStationViewController.h"
#import "TimetableManager.h"

#import "MBServiceListCollectionViewController.h"

#import "WagenstandRequestManager.h"

#import "MBTimetableViewController.h"
#import "HafasCacheManager.h"

#import "AppDelegate.h"

#import "MBGPSLocationManager.h"

#import "MBParkingManager.h"
#import "MBParkingOccupancyManager.h"
#import "RIMapManager2.h"
#import "RIMapSEVManager.h"
#import "MBLockerRequestManager.h"
#import "MBContentSearchResult.h"

#import "FacilityStatusManager.h"

#import "MBStationNavigationViewController.h"
#import "MBStationSearchViewController.h"
#import "MBOverlayViewController.h"


#import "MBRISStationsRequestManager.h"
#import "MBNewsRequestManager.h"
#import "MBStationOccupancyRequestManager.h"
#import "MBSettingViewController.h"
#import "MBUIHelper.h"
#import "MBTrackingManager.h"

@interface MBRootContainerViewController ()

@property (nonatomic, strong) MBTimetableViewController *timetableViewController;

@property (nonatomic, strong) MBServiceListCollectionViewController *shopServiceListViewController;
@property (nonatomic, strong) MBServiceListCollectionViewController *infoServiceListViewController;

@property (nonatomic, strong) MBStationViewController *stationContainerViewController;

@property (nonatomic, strong) UIViewController *currentViewController;

@property (nonatomic) NSInteger openRequests;
@property (nonatomic,strong) NSLock *lockForRequests;

@property (nonatomic) BOOL initialRequestDone;

@end

@implementation MBRootContainerViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.lockForRequests = [[NSLock alloc] init];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.stationContainerViewController = [[MBStationViewController alloc] init];
    [self.stationContainerViewController setStation:self.station];
    MBStationNavigationViewController *mainNav = [[MBStationNavigationViewController alloc] initWithRootViewController:self.stationContainerViewController];
    mainNav.station = self.station;
    MBTimetableViewController* vcTrains = [[MBTimetableViewController alloc] initWithBackButton:NO fernverkehr:YES];
    self.timetableViewController = vcTrains;
    vcTrains.station = self.station;
    vcTrains.departure = YES;
    vcTrains.trackingTitle = TRACK_KEY_DEPARTURE;
    MBStationNavigationViewController* navTrains = [[MBStationNavigationViewController alloc]
                                                  initWithRootViewController:vcTrains];
    navTrains.station = self.station;

    MBServiceListCollectionViewController* vcInfo = [[MBServiceListCollectionViewController alloc] initWithType:MBServiceCollectionTypeInfo];
    self.infoServiceListViewController = vcInfo;
    self.infoServiceListViewController.station = self.station;
    vcInfo.station = self.station;
    MBStationNavigationViewController* navInfo = [[MBStationNavigationViewController alloc]
                                                  initWithRootViewController:vcInfo];
    navInfo.station = self.station;

    self.shopServiceListViewController = [[MBServiceListCollectionViewController alloc] initWithType:MBServiceCollectionTypeShopping];
    self.shopServiceListViewController.station = self.station;

    MBStationNavigationViewController *servicesNavigationController = [[MBStationNavigationViewController alloc] initWithRootViewController:self.shopServiceListViewController];
    
    servicesNavigationController.viewControllers = @[self.shopServiceListViewController];
    servicesNavigationController.station = self.station;
                                                            
    NSArray *viewControllers = @[
                                 [UIViewController new],//placeholder for "back to search"
                                 mainNav,
                                 navTrains,
                                 navInfo,
                                 servicesNavigationController,
                                 ];
    
    
    self.stationTabBarViewController = [[MBStationTabBarViewController alloc] initWithViewControllers:viewControllers station:self.station];
    self.stationTabBarViewController.delegate = self;
    self.stationContainerViewController.tabBarViewController = self.stationTabBarViewController;
    
    self.currentViewController = self.stationTabBarViewController;
    
    self.rootDelegate = self.stationContainerViewController;

    [self.stationTabBarViewController willMoveToParentViewController:self];
    [self addChildViewController:self.stationTabBarViewController];
    [self.view addSubview:self.stationTabBarViewController.view];
    
    self.title = self.station.title;
    
    
}

-(MBTimetableViewController *)timetableVC{
    return self.timetableViewController;
}
-(MBServiceListCollectionViewController*)infoVC{
    return self.infoServiceListViewController;
}

- (void)dealloc
{
    NSLog(@"dealloc MBRootContainerViewController");
}

#pragma mark MBStationTabBarViewControllerDelegate
- (void)goBackToSearchAnimated:(BOOL)animated{
    [self goBackToSearchAnimated:animated clearBackHistory:true];
}
- (void)goBackToSearchAnimated:(BOOL)animated clearBackHistory:(BOOL)clearBackHistory{
    [[TimetableManager sharedManager] resetTimetable];
    [self.navigationController popViewControllerAnimated:animated];
    AppDelegate* app = (AppDelegate*) [UIApplication sharedApplication].delegate;
    if([app.navigationController.topViewController isKindOfClass:[MBStationSearchViewController class]]){
        MBStationSearchViewController* station = (MBStationSearchViewController*)app.navigationController.topViewController;
        [station freeStationAndClearBackHistory:clearBackHistory];
    }
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.currentViewController;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(!self.initialRequestDone){
        self.initialRequestDone = YES;
        [self reloadStationForcedByUser:NO];
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];    
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
}

- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}


- (void) loadView
{
    [super loadView];
    
    self.navigationItem.hidesBackButton = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.title = @"";
    self.title.accessibilityLanguage = @"de-DE";
    
}

-(void)updateFacilityUI
{
    [self.stationContainerViewController updateMapMarkersForFacilities];
}

#pragma -
#pragma App Lifecyle Events


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)changeOpenRequests:(NSInteger)delta{
    [_lockForRequests lock];
    _openRequests = _openRequests + delta;
    if(_openRequests == 0){
        if([self.rootDelegate respondsToSelector:@selector(didFinishAllLoading)]){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.rootDelegate didFinishAllLoading];
            });
        }
    }
    [_lockForRequests unlock];
}

-(void)reloadStation{
    [self reloadStationForcedByUser:YES];
}

-(void)reloadStationForcedByUser:(BOOL)forcedByUser{
    MBStation* station = self.station;
    NSObject* del = self.rootDelegate;
    
    BOOL requestNewsAndCoupons = NO;
    BOOL requestParking = YES;
    
    _openRequests = 5;
    // - StationData (RIS:Station): Station.stationDetails
    // - RIMapStatus (Station.levels)
    // - MapPOIs
    // - FacilityStatus
    // - Occupancy in station
    
    //the following are requested, but not required for H1 layout setup. Those marked with (*) show up in the Info-tab and search:
    // - RiMaps SEV (*)
    // - RIS:StationEquipments (locker) (*)
    // - Parking (*)
    // - ParkingOccupancy (*)
    // - News
    
    if(station.hasStaticAdHocBox){
        station.newsList = [MBNews staticInfoData];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNumber* requestId = station.mbId;
        
        if([self.rootDelegate respondsToSelector:@selector(willStartLoadingData)] && del == self.rootDelegate){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.rootDelegate willStartLoadingData];
            });
        }

        [[MBRISStationsRequestManager sharedInstance] requestStationData:requestId forcedByUser:forcedByUser success:^(MBStationDetails *response) {
            
            [station updateStationWithDetails:response ];
            [station parseOpeningTimesWithCompletion:^{
                if([self.rootDelegate respondsToSelector:@selector(didLoadStationData:)] && del == self.rootDelegate){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.rootDelegate didLoadStationData:YES];
                    });
                }
                
                [self changeOpenRequests:-1];
            }];
            
        } failureBlock:^(NSError *error) {
            NSLog(@"RIS:Station: %@",error);
            if([self.rootDelegate respondsToSelector:@selector(didLoadStationData:)] && del == self.rootDelegate){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.rootDelegate didLoadStationData:NO];
                });
            }

            [self changeOpenRequests:-1];
        }];

        [self requestMapStationInfo:station forcedByUser:forcedByUser del:del];

        [self requestOccupancy:station forcedByUser:forcedByUser];
        
        if(requestNewsAndCoupons){
            [[MBNewsRequestManager sharedInstance] requestNewsForStation:station.mbId forcedByUser:forcedByUser success:^(MBNewsResponse *response) {
                //NSLog(@"loaded news: %@",response.currentNewsItems);
                station.newsList = response.currentNewsItems;
                station.couponsList = response.currentOfferItems;
                
                //debugdata:
                //station.newsList = [MBNews debugData]; station.couponsList = station.newsList;
                
                if(station.newsList.count > 0 && [self.rootDelegate respondsToSelector:@selector(didLoadNewsData)] && del == self.rootDelegate){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.rootDelegate didLoadNewsData];
                    });
                }
                
            } failureBlock:^(NSError *error) {
                NSLog(@"news failure: %@",error);
            }];
        }

        if(requestParking){
            //load parking status
            [[MBParkingManager client] requestParkingStatus:station.mbId forcedByUser:forcedByUser success:^(NSArray *parkingInfoItems) {
                // NSLog(@"got requestParkingStatus");
                
                station.parkingInfoItems = parkingInfoItems;
                
                dispatch_group_t group = dispatch_group_create();
                dispatch_group_enter(group);
                __block BOOL occupancySuccess = YES;
                //note: the allocation data is requested async, the station might be visible before the allocation is loaded
                for(MBParkingInfo* parkingInfo in parkingInfoItems){
                    if(parkingInfo.hasPrognosis){
                        NSString* num = parkingInfo.idValue;
                        // NSLog(@"request occupancy for id %@",num);
                        dispatch_group_enter(group);
                        
                        [[MBParkingOccupancyManager client] requestParkingOccupancy:num success:^(NSNumber *allocationCategory) {
                            // NSLog(@"got requestParkingOccupancy");
                            //update allocationCategory
                            parkingInfo.allocationCategory = allocationCategory;
                            dispatch_group_leave(group);
                        } failureBlock:^(NSError *error) {
                            //ignore
                            NSLog(@"error: %@",error);
                            occupancySuccess = NO;
                            dispatch_group_leave(group);
                        }];
                        
                    }
                }
                dispatch_group_leave(group);
                
                dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    
                    if(station.parkingInfoItems.count > 0 && [self.rootDelegate respondsToSelector:@selector(didLoadParkingData)] && del == self.rootDelegate){
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.rootDelegate didLoadParkingData];
                        });
                    }

                });
                
            } failureBlock:^(NSError *error) {
            }];
        }

        
        //request map-poi data
        [[RIMapManager2 client] requestMapPOI:station.mbId osm:station.useOSM forcedByUser:forcedByUser success:^(NSArray *pois) {
            //NSLog(@"got map pois: %@",pois);
            station.riPois = pois;
            if([self.rootDelegate respondsToSelector:@selector(didLoadMapPOIs:)] && del == self.rootDelegate){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.rootDelegate didLoadMapPOIs:YES];
                });
            }
            
            [self changeOpenRequests:-1];
        } failureBlock:^(NSError *error) {
            // NSLog(@"map poi failed %@",error);
            if([self.rootDelegate respondsToSelector:@selector(didLoadMapPOIs:)] && del == self.rootDelegate){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.rootDelegate didLoadMapPOIs:NO];
                });
            }
            [self changeOpenRequests:-1];
        }];
        
        if(station.hasStaticAdHocBox){
            station.sevPois = @[[[RIMapSEV alloc] initWithDict:@{}]];
        }
        [RIMapSEVManager.shared requestSEV:station.mbId forcedByUser:forcedByUser success:^(NSArray<RIMapSEV *> * _Nonnull list) {
            station.sevPois = list;
            
            if(station.hasStaticAdHocBox && list.count == 0){
                //fallback, use empty object
                station.sevPois = @[[[RIMapSEV alloc] initWithDict:@{}]];
            }
            
            if(list.count > 0 && [self.rootDelegate respondsToSelector:@selector(didLoadSEVData)] && del == self.rootDelegate){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.rootDelegate didLoadSEVData];
                });
            }
        } failureBlock:^(NSError * _Nullable error) {
            
        }];
        
        [MBLockerRequestManager.shared requestLocker:station.mbId forcedByUser:forcedByUser success:^(NSArray<MBLocker *> * _Nonnull list) {
            /*NSLog(@"lockers:");
            for(MBLocker* locker in list){
                NSLog(@"%@",locker.headerText);
                NSLog(@"%@",[locker lockerDescriptionTextForVoiceOver:false]);
                NSLog(@"--\n");
            }*/
            station.lockerList = list;
            NSLog(@"didLoad locker");
            if(list.count > 0 && [self.rootDelegate respondsToSelector:@selector(didLoadLockerData)] && del == self.rootDelegate){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.rootDelegate didLoadLockerData];
                });
            }
        } failureBlock:^(NSError * _Nullable error) {
        }];
        
        [FacilityStatusManager.client requestFacilityStatus:station.mbId success:^(NSArray *facilityStatusItems) {
            
            station.facilityStatusPOIs = facilityStatusItems;
            if([self.rootDelegate respondsToSelector:@selector(didLoadFacilityData:)] && del == self.rootDelegate){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.rootDelegate didLoadFacilityData:YES];
                });
            }
            [self changeOpenRequests:-1];
        } failureBlock:^(NSError *error) {
            if([self.rootDelegate respondsToSelector:@selector(didLoadFacilityData:)] && del == self.rootDelegate){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.rootDelegate didLoadFacilityData:NO];
                });
            }
            [self changeOpenRequests:-1];
        }];

    });
}

-(void)requestMapStationInfo:(MBStation*)station forcedByUser:(BOOL)forcedByUser del:(NSObject*)del{
    //request map-station info
    [[RIMapManager2 client] requestMapStatus:station.mbId osm:station.useOSM forcedByUser:forcedByUser success:^(NSArray<LevelplanWrapper*> *levels) {
        // NSLog(@"got map levels: %@",levels);
        station.levels = levels;
        if([self.rootDelegate respondsToSelector:@selector(didLoadIndoorMapLevels:)] && del == self.rootDelegate){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.rootDelegate didLoadIndoorMapLevels:YES];
            });
        }
        [self changeOpenRequests:-1];
    } failureBlock:^(NSError *error) {
        // NSLog(@"map status failed %@",error);
        if([self.rootDelegate respondsToSelector:@selector(didLoadIndoorMapLevels:)] && del == self.rootDelegate){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.rootDelegate didLoadIndoorMapLevels:NO];
            });
        }
        [self changeOpenRequests:-1];
    }];
}

-(void)requestOccupancy:(MBStation*)station forcedByUser:(BOOL)forcedByUser{
    if(station.hasOccupancy){
        [[MBStationOccupancyRequestManager sharedInstance] getOccupancyForStation:station.mbId forcedByUser:forcedByUser success:^(MBStationOccupancy *response) {
            station.occupancy = response;
            [self changeOpenRequests:-1];
        } failureBlock:^(NSError *error) {
            //NSLog(@"no occupancy: %@",error);
            [self changeOpenRequests:-1];
        }];
    } else {
        [self changeOpenRequests:-1];
    }
}


-(void)showFacilities{
    //called from a push notification
    [self selectStationTab];
    [self.stationContainerViewController showFacilityViewAndReload:true];
}

- (void) showAlertForStationDownloadFailed
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorHeadline = @"Bahnhof live";
        NSString *errorMessage = @"Der gewählte Bahnhof konnte nicht geladen werden. Bitte versuchen Sie es später erneut.";
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:errorHeadline message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:nil]];
         [self presentViewController:alert animated:YES completion:nil];        
    });
}

+(UIViewController*)rootViewController{
    AppDelegate* app = (AppDelegate*) [UIApplication sharedApplication].delegate;
    MBStationSearchViewController* search = (MBStationSearchViewController*) app.viewController;
    UIViewController* root = search.stationMapController;//MBRootContainerViewController*
    if(!root){
        //we are probably in H0 or the map from H0 or in the OEPNV-View from H0
        root = search.navigationController;
        if(root.presentedViewController != nil && [root.presentedViewController isKindOfClass:MBStationNavigationViewController.class]){
            NSLog(@"special overlay case");
            //special case: the user opened the map from H0, then selected oepnv station detail and then the filter
            root = root.presentedViewController;
        }
    }
    return root;
}

+(void)presentViewControllerAsOverlay:(MBOverlayViewController*)vc {
    [self presentViewControllerAsOverlay:vc allowNavigation:NO];
}

+(void)presentViewControllerAsOverlay:(MBOverlayViewController*)vc allowNavigation:(BOOL)allowNavigation{
    UIViewController* root = [self rootViewController];
    if(root){
        if(allowNavigation){
            vc.overlayIsPresentedAsChildViewController = NO;
            MBStationNavigationViewController *navi = [[MBStationNavigationViewController alloc] initWithRootViewController:vc];
            navi.modalPresentationStyle = UIModalPresentationOverFullScreen;
            navi.behindViewBackgroundColor = [UIColor clearColor];//we want to see the status bar etc
            [navi showBackgroundImage:NO];
            [navi setShowRedBar:NO];
            [navi hideNavbar:YES];
            [root presentViewController:navi animated:NO completion:nil];
        } else {
            if(root.presentedViewController){
                root = root.presentedViewController;
            }
            if([root isKindOfClass:UINavigationController.class]){
                UINavigationController* navi = (UINavigationController*)root;
                if(navi.presentedViewController){
                    //this is the case when OPNVOverlay->Departures->Map->Departures->Filter is opened!
                    root = navi.presentedViewController;
                }
            }
            
            vc.overlayIsPresentedAsChildViewController = YES;
            //[vc willMoveToParentViewController:root];
            [root addChildViewController:vc];
            
            vc.view.frame = CGRectMake(0, 0, root.view.sizeWidth, root.view.sizeHeight);
            [root.view addSubview:vc.view];
            [vc didMoveToParentViewController:root];
        }
        vc.view.accessibilityViewIsModal = YES;
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, vc.view);
    }
}
+(MBRootContainerViewController*)currentlyVisibleInstance{
    AppDelegate* app = (AppDelegate*) [UIApplication sharedApplication].delegate;
    MBStationSearchViewController* search = (MBStationSearchViewController*) app.viewController;
    MBRootContainerViewController* root = search.stationMapController;
    return root;
}

-(UINavigationController *)stationContainerNavigationController{
    return self.stationContainerViewController.navigationController;
}
-(UINavigationController*)timetableNavigationController{
    return self.timetableViewController.navigationController;
}
-(void)selectStationTab{
    [self.stationTabBarViewController selectViewControllerAtIndex:1];
}
-(void)selectTimetableTab{
    [self.stationTabBarViewController selectViewControllerAtIndex:2];
}
-(void)selectInfoTab{
    [self.stationTabBarViewController selectViewControllerAtIndex:3];
}
-(void)selectShopTab{
    [self.stationTabBarViewController selectViewControllerAtIndex:4];
}
-(void)selectTimetableTabAndDeparturesForTrack:(NSString*)track trainOrder:(Stop*)trainStop{
    [self.stationTabBarViewController selectViewControllerAtIndex:2];
    [self.timetableViewController showTrack:track trainOrder:trainStop];
}
-(void)handleSearchResult:(MBContentSearchResult*)search{
    //close a possible overlay on H1 first
    if(self.stationContainerViewController.presentedViewController != nil){
        [self.stationContainerViewController dismissViewControllerAnimated:true completion:^{
            [self handleSearchResult:search];
        }];
        return;
    }

    if(search.isTimetableSearch){
        [self.timetableViewController handleSearchResult:search];
        [self selectTimetableTab];
        if(self.timetableViewController.navigationController.presentedViewController != self.timetableViewController){
            [self popThisControllerToRootController:self.timetableViewController];
        }
    } else if(search.isShopSearch){
        self.shopServiceListViewController.searchResult = search;
        [self selectShopTab];
        [self popThisControllerToRootController:self.shopServiceListViewController];
    } else if(search.isStationInfoSearch || search.isFeedbackSearch){
        self.infoServiceListViewController.searchResult = search;
        if(search.isFeedbackSearch){
            self.infoServiceListViewController.openServiceNumberScreen = true;
        }
        [self selectInfoTab];
        [self popThisControllerToRootController:self.infoServiceListViewController];
    } else if(search.isMapSearch || search.isSettingSearch || search.isOPNVOverviewSearch || search.isStationFeatureSearch){
        [self selectStationTab];
        [self popThisControllerToRootController:self.stationContainerViewController];
        if(search.isMapSearch){
            [MBMapConsent.sharedInstance showConsentDialogInViewController:self.stationTabBarViewController completion:^{
                MBMapViewController* vc = [MBMapViewController new];
                [vc configureWithStation:self.station];
                [self.stationTabBarViewController presentViewController:vc animated:YES completion:nil];
            }];
        } else if(search.isSettingSearch){
            MBSettingViewController* vc = [MBSettingViewController new];
            vc.currentStation = self.station;
            vc.title = @"Einstellungen";
            [self.stationContainerViewController.navigationController pushViewController:vc animated:YES];
        } else if(search.isOPNVOverviewSearch){
            [self.stationContainerViewController openOPNV];
        } else if(search.isStationFeatureSearch){
            [self.stationContainerViewController openStationFeatures];
        }
    } else {
        NSLog(@"unknown search action, not implemented %@",search);
    }
}

-(void)popThisControllerToRootController:(UIViewController*)vc{
    //popToRootViewControllerAnimated creates a "unbalanced calls" warning from UIKit
    //[vc.navigationController popToRootViewControllerAnimated:false];
    //this method does not create this warning:
    [vc.navigationController setViewControllers:@[vc.navigationController.viewControllers.firstObject] animated:NO];
}

-(void)cleanup{
    NSLog(@"cleanup");
    self.rootDelegate = nil;
    [self.timetableViewController removeFromParentViewController];
    self.timetableViewController = nil;
    self.stationTabBarViewController.viewControllers = nil;
    self.stationTabBarViewController.delegate = nil;
    [self.stationTabBarViewController removeFromParentViewController];
    self.stationTabBarViewController = nil;
    self.shopServiceListViewController.tabBarViewController = nil;
    self.shopServiceListViewController = nil;
    self.infoServiceListViewController.tabBarViewController = nil;
    self.infoServiceListViewController = nil;
    self.stationContainerViewController.tabBarViewController = nil;
    [self.stationContainerViewController removeFromParentViewController];
    self.stationContainerViewController = nil;
    self.currentViewController = nil;
}

@end
