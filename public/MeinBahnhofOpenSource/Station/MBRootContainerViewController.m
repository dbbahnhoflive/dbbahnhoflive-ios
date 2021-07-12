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
#import "MBContentSearchResult.h"

#import "FacilityStatusManager.h"

#import "MBStationNavigationViewController.h"
#import "MBStationSearchViewController.h"
#import "MBOverlayViewController.h"


#import "MBPTSRequestManager.h"
#import "MBNewsRequestManager.h"
#import "MBEinkaufsbahnhofManager.h"
#import "MBStationOccupancyRequestManager.h"
#import "MBSettingViewController.h"

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

- (void)dealloc
{
    NSLog(@"dealloc MBRootContainerViewController");
}

#pragma mark MBStationTabBarViewControllerDelegate
- (void)goBackToSearch {
    [self.navigationController popViewControllerAnimated:YES];
    AppDelegate* app = (AppDelegate*) [UIApplication sharedApplication].delegate;
    if([app.navigationController.topViewController isKindOfClass:[MBStationSearchViewController class]]){
        MBStationSearchViewController* station = (MBStationSearchViewController*)app.navigationController.topViewController;
        [station freeStation];
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

- (void) didSelectChooseEntry:(id)entry;
{
    [[TimetableManager sharedManager] resetTimetable];
    [self.navigationController popToRootViewControllerAnimated:NO];
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
    
    BOOL requestNewsAndCoupons = YES;
    BOOL requestParking = YES;
    BOOL requestOccupancy = YES;
    
    _openRequests = 5;
    // - StationData (PTS)
    // - RIMapStatus
    // - EinkaufsbahnhofOverview
    // - MapPOIs
    // - FacilityStatus
    if(requestParking){
        _openRequests = _openRequests+1;
    }
    
    if(requestNewsAndCoupons){
        _openRequests = _openRequests+1;
    }
    if(requestOccupancy){
        _openRequests = _openRequests+1;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[MBPTSRequestManager sharedInstance] requestStationData:station.mbId forcedByUser:forcedByUser success:^(MBPTSStationResponse *response) {
            
            [station updateStationWithDetails:response ];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[HafasCacheManager sharedManager] addKnownEvaIds:station.stationEvaIds];
            });
            
            if([self.rootDelegate respondsToSelector:@selector(didLoadStationData:)] && del == self.rootDelegate){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.rootDelegate didLoadStationData:YES];
                });
            }
            
            [self changeOpenRequests:-1];
            [self requestMapStationInfo:station forcedByUser:forcedByUser del:del];
            [self requestOccupancy:station forcedByUser:forcedByUser];
        } failureBlock:^(NSError *error) {
            NSLog(@"PTS: %@",error);
            if([self.rootDelegate respondsToSelector:@selector(didLoadStationData:)] && del == self.rootDelegate){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.rootDelegate didLoadStationData:NO];
                });
            }

            [self changeOpenRequests:-1];
            [self requestMapStationInfo:station forcedByUser:forcedByUser del:del];
        }];
        
        [self loadEinkaufsbahnhofListStation:station forcedByUser:forcedByUser del:del];

        if(requestNewsAndCoupons){
            [[MBNewsRequestManager sharedInstance] requestNewsForStation:station.mbId forcedByUser:forcedByUser success:^(MBNewsResponse *response) {
                //NSLog(@"loaded news: %@",response.currentNewsItems);
                station.newsList = response.currentNewsItems;
                station.couponsList = response.currentOfferItems;
                
                //debugdata:
                //station.newsList = [MBNews debugData]; station.couponsList = station.newsList;
                
                [self changeOpenRequests:-1];
            } failureBlock:^(NSError *error) {
                NSLog(@"news failure: %@",error);
                [self changeOpenRequests:-1];
            }];
        }

        if(requestParking){
            //load parking status
            [[MBParkingManager client] requestParkingStatus:station.mbId forcedByUser:forcedByUser success:^(NSArray *parkingInfoItems) {
                // NSLog(@"got requestParkingStatus");
                
                station.parkingInfoItems = parkingInfoItems;
                
                if([self.rootDelegate respondsToSelector:@selector(didLoadParkingData:)] && del == self.rootDelegate){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.rootDelegate didLoadParkingData:YES];
                    });
                }

                //[self changeOpenRequests:+1];//the next request
                //[self changeOpenRequests:-1];//for this one

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
                    if([self.rootDelegate respondsToSelector:@selector(didLoadParkingOccupancy:)] && del == self.rootDelegate){
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.rootDelegate didLoadParkingOccupancy:occupancySuccess];
                        });
                    }
                    [self changeOpenRequests:-1];
                });
                
            } failureBlock:^(NSError *error) {
                if([self.rootDelegate respondsToSelector:@selector(didLoadParkingData:)] && del == self.rootDelegate){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.rootDelegate didLoadParkingData:NO];
                    });
                }
                [self changeOpenRequests:-1];
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
            if(pois.count == 0){
                NSLog(@"missing ripoi, fallback to einkaufsbahnhof");
                [self loadEinkaufsbahnhofStation:station forcedByUser:forcedByUser del:del];
            } else {
                if([self.rootDelegate respondsToSelector:@selector(didLoadEinkaufData:)] && del == self.rootDelegate){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.rootDelegate didLoadEinkaufData:NO];
                    });
                }
            }
            [self changeOpenRequests:-1];
        } failureBlock:^(NSError *error) {
            // NSLog(@"map poi failed %@",error);
            if([self.rootDelegate respondsToSelector:@selector(didLoadMapPOIs:)] && del == self.rootDelegate){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.rootDelegate didLoadMapPOIs:NO];
                });
            }
            NSLog(@"failure ripoi, fallback to einkaufsbahnhof");
            [self loadEinkaufsbahnhofStation:station forcedByUser:forcedByUser del:del];
            [self changeOpenRequests:-1];
        }];
        
        
        [[FacilityStatusManager client] requestFacilityStatus:station.mbId success:^(NSArray *facilityStatusItems) {
            
            //sort items by their state but keep the server sorting for same state
            NSMutableArray* disabledFacility = [NSMutableArray arrayWithCapacity:5];
            NSMutableArray* unknownFacility = [NSMutableArray arrayWithCapacity:5];
            NSMutableArray* activeFacility = [NSMutableArray arrayWithCapacity:facilityStatusItems.count];
            for(FacilityStatus* f in facilityStatusItems){
                if(f.state == INACTIVE){
                    [disabledFacility addObject:f];
                } else if(f.state == UNKNOWN){
                    [disabledFacility addObject:f];
                } else {
                    [activeFacility addObject:f];
                }
            }
            NSMutableArray* sortedList = [NSMutableArray arrayWithCapacity:facilityStatusItems.count];
            [sortedList addObjectsFromArray:disabledFacility];
            [sortedList addObjectsFromArray:unknownFacility];
            [sortedList addObjectsFromArray:activeFacility];

            station.facilityStatusPOIs = sortedList;
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
    [[RIMapManager2 client] requestMapStatus:station.mbId osm:station.useOSM eva:station.stationEvaIds.firstObject forcedByUser:forcedByUser success:^(NSArray<LevelplanWrapper*> *levels) {
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
            NSLog(@"no occupancy: %@",error);
            [self changeOpenRequests:-1];
        }];
    } else {
        [self changeOpenRequests:-1];
    }
}


-(void)loadEinkaufsbahnhofStation:(MBStation*)station forcedByUser:(BOOL)forcedByUser del:(NSObject*)del{
    [self changeOpenRequests:+1];
    [[MBEinkaufsbahnhofManager sharedManager] requestEinkaufPOI:station.mbId forcedByUser:forcedByUser success:^(NSArray *categories) {
        station.einkaufsbahnhofCategories = categories;
        if([self.rootDelegate respondsToSelector:@selector(didLoadEinkaufData:)] && del == self.rootDelegate){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.rootDelegate didLoadEinkaufData:YES];
            });
        }
        [self changeOpenRequests:-1];
    } failureBlock:^(NSError *error) {
        if([self.rootDelegate respondsToSelector:@selector(didLoadEinkaufData:)] && del == self.rootDelegate){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.rootDelegate didLoadEinkaufData:NO];
            });
        }
        [self changeOpenRequests:-1];
    }];
}
-(void)loadEinkaufsbahnhofListStation:(MBStation*)station forcedByUser:(BOOL)forcedByUser del:(NSObject*)del{
    [[MBEinkaufsbahnhofManager sharedManager] requestAllEinkaufsbahnhofIdsForcedByUser:forcedByUser success:^(NSArray *idList) {
        station.isEinkaufsbahnhof = [idList containsObject:station.mbId];
        [self changeOpenRequests:-1];
    } failureBlock:^(NSError *error) {
        [self changeOpenRequests:-1];
    }];
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

+(void)presentViewControllerAsOverlay:(MBOverlayViewController*)vc {
    [self presentViewControllerAsOverlay:vc allowNavigation:NO];
}

+(void)presentViewControllerAsOverlay:(MBOverlayViewController*)vc allowNavigation:(BOOL)allowNavigation{
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
    if(search.isTimetableSearch){
        [self.timetableViewController handleSearchResult:search];
        [self selectTimetableTab];
        if(self.timetableViewController.navigationController.presentedViewController != self.timetableViewController){
            [self.timetableViewController.navigationController popToRootViewControllerAnimated:NO];
        }
    } else if(search.isShopSearch){
        [self.shopServiceListViewController.navigationController popToRootViewControllerAnimated:NO];
        self.shopServiceListViewController.searchResult = search;
        [self selectShopTab];
    } else if(search.isStationInfoSearch || search.isFeedbackSearch){
        [self.infoServiceListViewController.navigationController popToRootViewControllerAnimated:NO];
        self.infoServiceListViewController.searchResult = search;
        if(search.isFeedbackSearch){
            self.infoServiceListViewController.openServiceNumberScreen = true;
        }
        [self selectInfoTab];
    } else if(search.isMapSearch || search.isSettingSearch || search.isOPNVOverviewSearch || search.isStationFeatureSearch){
        [self selectStationTab];
        [self.stationContainerViewController.navigationController popToRootViewControllerAnimated:NO];
        UIViewController* finalVC = nil;
        if(search.isMapSearch){
            MBMapViewController* vc = [MBMapViewController new];
            [vc configureWithStation:self.station];
            [self.stationTabBarViewController presentViewController:vc animated:YES completion:nil];
            return;
        } else if(search.isSettingSearch){
            MBSettingViewController* vc = [MBSettingViewController new];
            finalVC = vc;
            vc.currentStation = self.station;
            vc.title = @"Einstellungen";
        } else if(search.isOPNVOverviewSearch){
            [self.stationContainerViewController openOPNV];
            return;
        } else if(search.isStationFeatureSearch){
            [self.stationContainerViewController openStationFeatures];
            return;
        }
        if(finalVC){
            [self.stationContainerViewController.navigationController pushViewController:finalVC animated:YES];
        }
    } else {
        NSLog(@"unknown search action, not implemented %@",search);
    }
}

-(void)cleanup{
    NSLog(@"cleanup");
    self.rootDelegate = nil;
    self.currentViewController = nil;
    self.stationContainerViewController.tabBarViewController = nil;
    [self.stationContainerViewController removeFromParentViewController];
    self.stationContainerViewController = nil;
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
}

@end
