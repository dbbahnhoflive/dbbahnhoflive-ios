// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBMapViewController.h"
#import "MBMapView.h"
#import "RIMapPoi.h"
#import "SharedMobilityAPI.h"
#import "MBMapLevelPicker.h"

#import "MBMapPoiDetailScrollView.h"
#import "SharedMobilityMappable.h"
#import "MBPoiFilterView.h"
#import "RIMapFilterCategory.h"
#import "MBUrlOpening.h"
#import "AppDelegate.h"
#import "MBRoutingHelper.h"

#import "MBGPSLocationManager.h"
#import "MBParkingManager.h"
#import "MBTutorialManager.h"

#import "MBTimetableViewController.h"
#import "HafasRequestManager.h"
#import "HafasTimetable.h"
#import "MBStationSearchViewController.h"
#import "MBRootContainerViewController.h"
#import "MBStationNavigationViewController.h"

#import "MBUIHelper.h"
#import "MBTrackingManager.h"

@interface MBMapViewController ()<MBMapLevelPickerDelegate,MBMapViewDelegate,UIScrollViewDelegate,MBPoiFilterViewDelegate,MBMapFlyoutDelegate>

@property(nonatomic,strong) MBMapView* mapView;

@property(nonatomic,strong) UIButton* mapCloseButton;

@property (nonatomic, strong) MBMapLevelPicker *levelPicker;
@property (nonatomic, strong) UIButton *pinToUserButton;
@property (nonatomic, strong) UILabel *osmCopyrightLabel;
@property (nonatomic, strong) UIButton *filterToggleButton;
@property (nonatomic, strong) MBMapPoiDetailScrollView* poiDetailsScrollView;
@property(nonatomic,strong) UIView* mapFlyoutLefter;
@property(nonatomic,strong) UIView* mapFlyoutLeft;
@property(nonatomic,strong) UIView* mapFlyoutCenter;
@property(nonatomic,strong) UIView* mapFlyoutRight;
@property(nonatomic,strong) UIView* mapFlyoutRighter;
@property(nonatomic,strong) MBMarker* preselectedInitialMarker;
@property(nonatomic,strong) UIView* darkLayer;

@property (nonatomic,strong) MBPoiFilterView* filterView;

@property (nonatomic,strong) MBStation* station;

@property (nonatomic,strong) NSArray<POIFilterItem*>* allFilterItems;
@end

@implementation MBMapViewController

-(instancetype)init{
    self = [super init];
    if(self){
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.allFilterItems= [RIMapPoi createFilterItems];
    
    self.mapView = [[MBMapView alloc] initMapViewWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.mapView setMapType:OSM];
    [self.view addSubview:self.mapView];
    self.mapView.delegate = self;
    
    self.mapCloseButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0, 60, 60)];
    self.mapCloseButton.accessibilityLabel = @"Karte schließen";
    [self.mapCloseButton setBackgroundImage:[UIImage db_imageNamed:@"MapToggleButtonClose"] forState:UIControlStateNormal];
    BOOL assetsMissing = NO;
    if(![UIImage db_imageNamed:@"MapToggleButtonClose"]){
        //open source app without assets
        assetsMissing = YES;
        self.mapCloseButton.backgroundColor = [UIColor whiteColor];
    }
    [self.mapCloseButton addTarget:self action:@selector(mapCloseButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.mapCloseButton];
    

    //code moved here from MBMapView
    self.levelPicker = [[MBMapLevelPicker alloc] initWithLevels:@[]];
    self.levelPicker.hidden = YES;
    self.levelPicker.delegate = self;
    
    self.pinToUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.pinToUserButton.accessibilityLabel = @"Aktuelle Position zentrieren";
    self.pinToUserButton.frame = CGRectMake(0,0, 60, 60);
    if(assetsMissing){
        self.pinToUserButton.backgroundColor = [UIColor whiteColor];
    }
    [self.pinToUserButton setBackgroundImage:[UIImage db_imageNamed:@"MapUserLocation"] forState:UIControlStateNormal];
    self.pinToUserButton.enabled = YES;
    
    [self.pinToUserButton addTarget:self action:@selector(userDidTapOnPinToUserButton:) forControlEvents:UIControlEventTouchUpInside];
    
    self.osmCopyrightLabel = [[UILabel alloc] init];
    self.osmCopyrightLabel.isAccessibilityElement = NO;
    
    NSURL *URL = [NSURL URLWithString: @"www.openstreetmap.org/copyright"];
    NSMutableAttributedString * str = [[NSMutableAttributedString alloc] initWithString:@"© OpenStreetMap-Mitwirkende"];
    [str addAttribute: NSLinkAttributeName value:URL range: NSMakeRange(0, str.length)];
    [str addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, str.length)];
    [str addAttribute:NSFontAttributeName value:[UIFont db_RegularTen] range:NSMakeRange(0, str.length)];
    self.osmCopyrightLabel.attributedText = str;
    [self.osmCopyrightLabel sizeToFit];
    self.osmCopyrightLabel.backgroundColor = [UIColor colorWithWhite:1 alpha:0.6];
    self.osmCopyrightLabel.userInteractionEnabled = YES;
    [self.osmCopyrightLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleOSMLabelTap:)]];
    
    self.filterToggleButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0, 60, 60)];
    self.filterToggleButton.accessibilityLabel = @"Filter öffnen";
    [self.filterToggleButton setBackgroundImage:[UIImage db_imageNamed:@"MapFilterButton"] forState:UIControlStateNormal];
    if(assetsMissing){
        self.filterToggleButton.backgroundColor = [UIColor whiteColor];
    }
    [self.filterToggleButton addTarget:self action:@selector(filterToggleButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.filterToggleButton];

    self.poiDetailsScrollView = [[MBMapPoiDetailScrollView alloc] initWithFrame:CGRectMake(0, 0, [self poiDetailsWidth], 188)];
    self.poiDetailsScrollView.pagingEnabled = YES;
    self.poiDetailsScrollView.clipsToBounds = NO;
    self.poiDetailsScrollView.delegate = self;
    self.poiDetailsScrollView.backgroundColor = [UIColor clearColor];
    self.poiDetailsScrollView.hidden = YES;
    
    [self.view addSubview:self.levelPicker];
    [self.view addSubview:self.pinToUserButton];
    [self.view addSubview:self.osmCopyrightLabel];
    [self.view addSubview:self.poiDetailsScrollView];
    
    self.darkLayer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.sizeWidth, self.view.sizeHeight)];
    self.darkLayer.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.darkLayer];
    self.darkLayer.hidden = YES;
    self.osmCopyrightLabel.hidden = NO;

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.mapView resume];
    
    [MBTrackingManager trackStateWithStationInfo:@"f1"];
    
    if (nil == _station) {
        // zoom to user
        GMSCameraPosition *cameraPosition = [GMSCameraPosition cameraWithTarget:[[[MBGPSLocationManager sharedManager] lastKnownLocation] coordinate]
                                                                           zoom:13
                                                                        bearing:0
                                                                   viewingAngle:0];
        
        [self.mapView moveCameraToUser:cameraPosition animated:animated];
        if ([self.delegate respondsToSelector:@selector(mapNearbyStations)]) {
            self.mapView.nearbyStations = [self.delegate mapNearbyStations];
            [self.mapView updateNearbyStationsMarker];
        }

    }
    
    if(self.station.displayStationMap){
        [[MBTutorialManager singleton] displayTutorialIfNecessary:MBTutorialViewType_F3_Map_Departures withOffset:0];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveLocationUpdate:) name:NOTIF_GPS_LOCATION_UPDATE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveTimetableUpdate:)
                                                 name:NOTIF_TIMETABLE_UPDATE
                                               object:nil];

    if ([self.navigationController isKindOfClass:[MBStationNavigationViewController class]]) {
        ((MBStationNavigationViewController *)self.navigationController).hideEverything = YES;
        [(MBStationNavigationViewController *)self.navigationController hideNavbar:YES];
    }
    
    [self updateMobilityMarker];
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIF_GPS_LOCATION_UPDATE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIF_TIMETABLE_UPDATE object:nil];

    [[MBTutorialManager singleton] hideTutorials];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

-(void)configureWithStation:(MBStation *)station{
    self.station = station;
    if(self.view){
        self.levelPicker.levels = station.levels;
        [self.mapView configureMapForStation:station];
        
        [self configureWithDelegate];
    }
}

- (void)didReceiveTimetableUpdate:(NSNotification *)notification {
    if ([notification.object isEqual:[TimetableManager sharedManager]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"received a timetable update in mapView!");
        });
    }
}

-(void)hideFilter{
    self.filterToggleButton.hidden = YES;
    [self.view setNeedsLayout];
}

+(NSMutableArray<NSString*>*)filterForFilterPresets:(NSArray<NSString*>*)filterPresets{
    NSArray<RIMapFilterCategory*>* filterConfig = [RIMapPoi filterConfig];
    
    NSMutableArray<NSString*>* filterKeys = [NSMutableArray arrayWithCapacity:20];
    for(NSString* presetKey in filterPresets){
        //find the preset and add the filters
        for(RIMapFilterCategory* cat in filterConfig){
            if([cat.presets containsObject:presetKey]){
                //the filters may contain child or category elements... since we only use the child elements here, we transform the category into the children
                //[filterKeys addObject:cat.appcat];
                for(RIMapFilterEntry* entry in cat.items){
                    [filterKeys addObject:entry.title];
                }
            } else {
                for(RIMapFilterEntry* entry in cat.items){
                    if([entry.presets containsObject:presetKey]){
                        [filterKeys addObject:entry.title];
                    }
                }
            }
        }
    }
    //NSLog(@"filter presets %@ lead to filter settings %@",filterPresets, filterKeys);
    return filterKeys;
}

-(void)configureWithDelegate{
    if(self.view && self.delegate){
        if([self.delegate respondsToSelector:@selector(mapDisplayFilter)]){
            BOOL displayFilter = [self.delegate mapDisplayFilter];
            if(!displayFilter){
                [self hideFilter];
            }
        }
        
        if([self.delegate respondsToSelector:@selector(mapFilterPresets)]){
            NSArray<NSString*>* filters = self.delegate.mapFilterPresets;
            if(filters.count > 0){
                self.mapView.filterValues = [MBMapViewController filterForFilterPresets:filters];
                [self.filterToggleButton setBackgroundImage:[UIImage db_imageNamed:@"MapFilterButtonActive"] forState:UIControlStateNormal];
            }
            [self.mapView updateMarkers];
        } else {
            [self.mapView.filterValues removeAllObjects];
        }
        
        if([self.delegate respondsToSelector:@selector(mapSelectedMarker)] && self.delegate.mapSelectedMarker != nil){
            MBMarker* marker = self.delegate.mapSelectedMarker;
            self.preselectedInitialMarker = marker;
        } else if([self.delegate respondsToSelector:@selector(mapSelectedPOI)]){
            id poiToSelect = self.delegate.mapSelectedPOI;
            if(poiToSelect){
                MBMarker* marker = [self.mapView findMarkerForPOI:poiToSelect];
                if(marker){
                    self.preselectedInitialMarker = marker;
                }
            }
        } else if([self.delegate respondsToSelector:@selector(mapShouldCenterOnUser)]){
            if([self.delegate mapShouldCenterOnUser]){
                [self userDidTapOnPinToUserButton:nil];
            }
        }
        
        if(!self.preselectedInitialMarker && self.mapView.filterValues.count > 0){
            //no marker preselected but some filter settings are set, preselect a matching marker
            NSLog(@"preselect a visible marker");
            MBMarker* marker = [self.mapView preselectMarkerAfterFilterChange];
            if(marker){
                self.preselectedInitialMarker = marker;
            }
        }
    }
}

-(void)setPreselectedInitialMarker:(MBMarker *)selectedMarker{
    // NSLog(@"setpreselectedInitialMarker %@",selectedMarker);
    _preselectedInitialMarker = selectedMarker;
    
    if(selectedMarker){
        
        //then update level
        NSNumber *markerLevelNumber = [self.preselectedInitialMarker.userData objectForKey:@"level"];
        if(markerLevelNumber && self.levelPicker.levels.count > 1){
            //we may need to change the level
            for(LevelplanWrapper* level in self.levelPicker.levels){
                if(level.levelNumber == markerLevelNumber.integerValue){
                    [self.levelPicker setCurrentLevelByLevelNumber:level.levelNumber forced:YES];
                    [self.mapView setCurrentLevel:level];
                    break;
                }
            }
        }
        
        //we need a delay here for the map to setup the markers (else we don't get a larger selected marker)
        [self highlightPreSelectedMarker:YES];
    }
}

- (void) highlightPreSelectedMarker:(BOOL) delayed
{
    if (self.preselectedInitialMarker) {
        NSInteger delay = delayed ? 1 : 0;
        //update zoom level
        [self.mapView updatePositionAndZoomForMarker:self.preselectedInitialMarker animated:NO];
        [self.mapView performSelector:@selector(setPOISelected:) withObject:self.preselectedInitialMarker.userData[@"venue"] afterDelay:delay];
    }
}

- (void) handleOSMLabelTap:(id)sender
{
    [MBUrlOpening openURL:[NSURL URLWithString:@"https://www.openstreetmap.org/copyright"]];
}


- (void)userDidTapOnPinToUserButton:(id)sender
{
    [self.mapView userDidTapOnPinToUserButton:sender];
}



#pragma -
#pragma MBGPSManager Notifications


- (void) didReceiveLocationUpdate:(NSNotification*)notification;
{
    if (notification.userInfo) {
        CLLocation *location = [notification.userInfo objectForKey:kGPSNotifLocationPayload];
        if(location){
            if ([self.delegate respondsToSelector:@selector(mapNearbyStations)]) {
                self.mapView.nearbyStations = [self.delegate mapNearbyStations];
                [self.mapView updateNearbyStationsMarker];
            }
            [self.mapView updateMarkers];
            [self.mapView showUserMarkerAtLocation:location animate:YES];
        }
    }
}


-(void)updateVisibilityStatusForUI{
    BOOL mapHasNoLevelsAssigned = self.station.levels.count == 0;
    self.levelPicker.hidden = mapHasNoLevelsAssigned || !self.mapView.filterMarkerByLevel;
    
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
 
    [self updateVisibilityStatusForUI];

    self.mapView.frame = CGRectMake(0, 0, self.view.sizeWidth, self.view.sizeHeight);
    
    NSInteger spaceRight = ceilf(self.view.frame.size.width*0.02666)-10;//-10 because the images contain shadows
    [self.mapCloseButton setGravityTop:MAX(30,ceilf(self.view.frame.size.height*0.057-8))];
    [self.mapCloseButton setGravityRight:spaceRight];
    [self.osmCopyrightLabel setGravityRight:spaceRight];
    [self.pinToUserButton setGravityRight:spaceRight];
    [self.levelPicker setGravityRight:spaceRight];
    [self.filterToggleButton setGravityRight:spaceRight];
    
    NSInteger padding = ceilf(self.view.frame.size.height*0.045)-20;
    [self.filterToggleButton setBelow:self.mapCloseButton withPadding:padding];
    if(self.filterToggleButton.hidden){
        [self.pinToUserButton setBelow:self.mapCloseButton withPadding:padding];
    } else {
        [self.pinToUserButton setBelow:self.filterToggleButton withPadding:padding];
    }
    [self.levelPicker setBelow:self.pinToUserButton withPadding:padding];
    
    [self.osmCopyrightLabel setGravityBottom:0];
    
    self.poiDetailsScrollView.frame = CGRectMake(0, self.view.frame.size.height-188, [self poiDetailsWidth], 188);
    [self.poiDetailsScrollView centerViewHorizontalInSuperView];
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    //this is not optimal, but we have no better option to detect "user scrolled one item"
    [[MBTutorialManager singleton] displayTutorialIfNecessary:MBTutorialViewType_F3_Map withOffset:self.poiDetailsScrollView.sizeHeight];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    NSInteger index = scrollView.contentOffset.x/[self poiDetailsWidth];
    if(index < self.mapView.visiblePOIList.count){
        MBMarker* center = [self loadScrollViewWithPage:index];
        if(center){
            [self.mapView selectAndCenterMarker:center];
            if (nil != self.mapFlyoutCenter) {
                [MBTrackingManager trackActionsWithStationInfo:@[@"f1", @"scroll", @"pois"]];
                MBMapFlyout *centerFlyout = [[self.mapFlyoutCenter subviews] lastObject];
                [centerFlyout setupAbfahrtsTafel];
            }
        }
    }
}


-(UIView*)addFlyoutForPage:(NSInteger)page{
    return [self addFlyoutForPage:page isCentral:NO];
}
-(UIView*)addFlyoutForPage:(NSInteger)page isCentral:(BOOL)isCentral{
    if(page >= 0 && page < self.mapView.visiblePOIList.count){
        MBMarker* poi = self.mapView.visiblePOIList[page];
        UIView* flyoutContainer = [[UIView alloc] initWithFrame:CGRectMake([self poiDetailsWidth]*page+1, 0, [self poiDetailsWidth]-2, self.poiDetailsScrollView.frame.size.height)];
        flyoutContainer.backgroundColor = [UIColor whiteColor];
        MBMapFlyout* fly = [MBMapFlyout flyoutForPOI:poi inSuperView:flyoutContainer controller:self supportingNavigation:NO detailLink:NO central:isCentral station:self.station];
        fly.delegate = self;
        fly.clipsToBounds = YES;
        fly.frame = CGRectMake(0, 0, [self poiDetailsWidth], self.poiDetailsScrollView.sizeHeight);
        [flyoutContainer addSubview:fly];
        [self.poiDetailsScrollView addSubview:flyoutContainer];
        return flyoutContainer;
    }
    return nil;
}

-(void)showRoutingForParking:(MBParkingInfo *)parking{
    [MBRoutingHelper showRoutingForParking:parking fromViewController:self];
}

- (void) showFacilityFavorites{}


-(MBMarker*)loadScrollViewWithPage:(NSInteger)page{
    //could implement more logic here to optimize memory usage
    [self.mapFlyoutCenter removeFromSuperview];
    [self.mapFlyoutLeft removeFromSuperview];
    [self.mapFlyoutRight removeFromSuperview];
    [self.mapFlyoutLefter removeFromSuperview];
    [self.mapFlyoutRighter removeFromSuperview];
    
    MBMarker* centerPoi = nil;
    self.mapFlyoutLefter = [self addFlyoutForPage:page-2];
    self.mapFlyoutLeft = [self addFlyoutForPage:page-1];
    self.mapFlyoutCenter = [self addFlyoutForPage:page isCentral:YES];
    if(self.mapFlyoutCenter){
        centerPoi = self.mapView.visiblePOIList[page];
    }
    self.mapFlyoutRight = [self addFlyoutForPage:page+1];
    self.mapFlyoutRighter = [self addFlyoutForPage:page+2];

    return centerPoi;
}

#pragma mark MBMapViewDelegate
- (void) willOpenFlyoutOnMapView:(MBMapView*)mapView marker:(MBMarker*)marker{
    // NSLog(@"willOpenFlyoutOnMapView: marker:%@",marker);
    NSInteger index = [mapView.visiblePOIList indexOfObject:marker];
    if(index != NSNotFound){
        [self loadScrollViewWithPage:index];

        // update the scroll view to the appropriate page
        CGRect bounds = self.poiDetailsScrollView.bounds;
        bounds.origin.x = CGRectGetWidth(bounds) * index;
        bounds.origin.y = 0;
        [self.poiDetailsScrollView scrollRectToVisible:bounds animated:NO];

        if(CGRectGetMaxY(self.levelPicker.frame) >= self.poiDetailsScrollView.originY){
            //hide control, it collides with the details scrollview
            self.levelPicker.hidden = YES;
        }
        self.poiDetailsScrollView.hidden = NO;
        if (nil != self.mapFlyoutCenter) {
            MBMapFlyout *centerFlyout = [[self.mapFlyoutCenter subviews] lastObject];
            [centerFlyout setupAbfahrtsTafel];
        }
        
        self.preselectedInitialMarker = nil;

    } else {
        // NSLog(@"marker not found in visible poi list!!!!!!");
    }
}
-(void)didCloseFlyoutMapView:(MBMapView *)mapView{
    self.poiDetailsScrollView.hidden = YES;
    
    [self updateVisibilityStatusForUI];
}
- (void) didChangeVisiblePOIList{
    // Add selection state
    self.poiDetailsScrollView.contentSize = CGSizeMake([self poiDetailsWidth]*self.mapView.visiblePOIList.count, self.poiDetailsScrollView.frame.size.height);
    [self highlightPreSelectedMarker:NO];
}

-(void)mapFlyout:(MBMapFlyout *)flyout wantsToExtendView:(UIView *)view{
    //we grab the view from the flyout and put it in front of the other views in self.view, then move up
    self.darkLayer.alpha = 0.0;
    self.darkLayer.hidden = NO;
    [self.view addSubview:view];
    [view centerViewHorizontalInSuperView];
    [view setY:self.poiDetailsScrollView.frame.origin.y];
    [UIView animateWithDuration:0.3 animations:^{
        self.darkLayer.alpha = 0.7;
        [view setGravityBottom:0];//move up!
        
        UIView* firstMovableView = [view viewWithTag:MOVABLE_SHRINK_TAG];
        CGRect f = firstMovableView.frame;
        if(firstMovableView && flyout.movableShrinkY != 0){
            for(UIView* subview in view.subviews){
                if(subview.frame.origin.y >= f.origin.y){
                    [subview setY:subview.frame.origin.y - flyout.movableShrinkY ];
                }
            }
        }
    } completion:^(BOOL finished) {
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:flyout action:@selector(headerOpenCloseTapped)];
        [self.darkLayer addGestureRecognizer:tap];
    }];
}
-(void)mapFlyout:(MBMapFlyout *)flyout wantsToCloseView:(UIView *)view withGradient:(UIView * _Nullable)gradient{
    for(UIGestureRecognizer* g in self.darkLayer.gestureRecognizers){
        [self.darkLayer removeGestureRecognizer:g];
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.darkLayer.alpha = 0;
        [view setY:self.poiDetailsScrollView.frame.origin.y];
        
        UIView* firstMovableView = [view viewWithTag:MOVABLE_SHRINK_TAG];
        CGRect f = firstMovableView.frame;
        if(firstMovableView && flyout.movableShrinkY != 0){
            for(UIView* subview in view.subviews){
                if(subview.frame.origin.y >= f.origin.y){
                    [subview setY:subview.frame.origin.y + flyout.movableShrinkY ];
                }
            }
        }

    } completion:^(BOOL finished) {
        self.darkLayer.hidden = YES;
        [flyout addSubview:view];
        [view setGravityTop:0];
        [view setGravityLeft:0];
        if(gradient){
            [flyout addSubview:gradient];
        }
    }];
}

-(void)mapFlyout:(MBMapFlyout *)flyout wantsToOpenTimetableWithTrack:(NSString *)track train:(Stop *)trainStop{
    [self dismissViewControllerAnimated:YES completion:^{
        [[MBRootContainerViewController currentlyVisibleInstance] selectTimetableTabAndDeparturesForTrack:track trainOrder:trainStop];
    }];
}

-(CGFloat)poiDetailsWidth{
    return (int)(self.view.frame.size.width*(303./375.));
}

-(void)mapCloseButtonPressed{
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(void)poiFilterWantsClose:(MBPoiFilterView *)view{
    [self.filterView removeFromSuperview];
    self.filterView = nil;
}
-(void)poiFilterDidChangeFilter:(MBPoiFilterView *)view{
    self.allFilterItems = view.currentFilterCategories;
    [self updateFilter];
}

-(void)updateFilter{
    NSMutableArray* filterValues = [NSMutableArray arrayWithCapacity:100];
    BOOL allActive = YES;
    for (POIFilterItem *filterItem in self.allFilterItems) {
        if (filterItem.subItems) {
            for (POIFilterItem *subItem in filterItem.subItems) {
                if (subItem.active) {
                    [filterValues addObject:subItem.title];
                } else {
                    allActive = NO;
                }
            }
        } else {
            if (filterItem.active) {
                [filterValues addObject:filterItem.title];
            } else {
                allActive = NO;
            }
        }
    }
    self.mapView.filterValues = filterValues;
    
    if(!allActive){
        [self.filterToggleButton setBackgroundImage:[UIImage db_imageNamed:@"MapFilterButtonActive"] forState:UIControlStateNormal];
    } else {
        [self.filterToggleButton setBackgroundImage:[UIImage db_imageNamed:@"MapFilterButton"] forState:UIControlStateNormal];
    }
    
    [self.mapView updateMarkers];
    
    if(self.mapView.filterValues && !allActive){
        NSLog(@"user set some filters, preselect a marker that is available for this filter config");
        MBMarker* marker = [self.mapView preselectMarkerAfterFilterChange];
        if(marker){
            self.preselectedInitialMarker = marker;
        }
    }

}

-(void)filterToggleButtonPressed{
    [MBTrackingManager trackActionWithStationInfo:@"f3"];
    [[MBTutorialManager singleton] markTutorialAsObsolete:MBTutorialViewType_F3_Map];
    
    if(self.mapView.filterValues){
        for (POIFilterItem *filterItem in self.allFilterItems) {
            if (filterItem.subItems) {
                for (POIFilterItem *subItem in filterItem.subItems) {
                    subItem.active = [self.mapView.filterValues containsObject:subItem.title];
                }
            }
        }
    }
    
    //create a copy of the filter state to allow changes without saving
    NSArray* allFilterCopy = [[NSArray alloc] initWithArray:self.allFilterItems copyItems:YES];
    
    MBPoiFilterView* filterView = [[MBPoiFilterView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) categories:allFilterCopy ];
    filterView.delegate = self;
    [self.view addSubview:filterView];
    self.filterView = filterView;
    [self.filterView animateInitialView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)updateMobilityMarker{
    if(self.station && CLLocationCoordinate2DIsValid(self.station.positionAsLatLng)){
        [[SharedMobilityAPI client] getMappables:self.station.positionAsLatLng success:^(NSArray *mappables) {
            NSMutableArray* markers = [NSMutableArray arrayWithCapacity:mappables.count];
            [mappables enumerateObjectsUsingBlock:^(MobilityMappable *mappable, NSUInteger idx, BOOL *stop) {
                MBMarker *marker = [mappable marker];
                [markers addObject:marker];
            }];
            [self.mapView updateMobilityMarker:markers];
            
        } failureBlock:^(NSError *error) {
            // NSLog(@"mobility failure %@",error);
        }];
    }
}

#pragma mark levelpicker
- (void)userDidSelectLevel:(LevelplanWrapper *)level onPicker:(MBMapLevelPicker *)picker
{
    self.mapView.cameraFollowsUser = NO;
    if(self.mapView.hasMarkerSelected){
        [self.mapView removeMarkerSelection];
    }
}

- (void)picker:(MBMapLevelPicker *)picker didChangeToLevel:(LevelplanWrapper*)level
{
    self.mapView.currentLevel = level;
}

#pragma mark rotation

- (BOOL) shouldAutorotate
{
    return ISIPAD ? YES : NO;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return ISIPAD ? (UIInterfaceOrientationMaskPortrait|UIInterfaceOrientationMaskPortraitUpsideDown) : UIInterfaceOrientationMaskPortrait;
}


#pragma mark tap on öpnv/stations
- (void)showTimetableForStationId:(NSString *)stationId stationName:(NSString *)stationName evas:(NSArray *)evas location:(NSArray *)location opnvStation:(MBOPNVStation *)opnvStation isOPNV:(BOOL)isOPNV{
    NSInteger stationInt = [stationId integerValue];
    // integerValue will return 0 if stationId is not a number
    if (!isOPNV && stationInt != 0) {
        if(!evas){
            evas = @[];
        }
        if(!location){
            location = @[];
        }
        NSDictionary* stationDict = @{ @"id":@(stationInt), @"title":stationName, @"eva_ids":evas, @"location":location };
        [self dismissViewControllerAnimated:YES completion:^{
            AppDelegate* app = (AppDelegate*) [UIApplication sharedApplication].delegate;
            MBStationSearchViewController* search = (MBStationSearchViewController*) app.viewController;
            [search openStation:stationDict];
        }];
    } else if(isOPNV){
        // open timetable for ÖPNV (this is pushed onto the (invisible) viewcontroller which will then become visible
        
        MBTimetableViewController *timeVC = [[MBTimetableViewController alloc] initWithFernverkehr:NO];
        if(opnvStation){
            timeVC.hafasTimetable = [[HafasTimetable alloc] init];
            timeVC.hafasTimetable.opnvStationForFiltering = opnvStation;
            timeVC.hafasTimetable.includedSTrains = YES;
            timeVC.hafasTimetable.needsInitialRequest = YES;
        }
        timeVC.oepnvOnly = YES;
        timeVC.trackingTitle = TRACK_KEY_TIMETABLE;
        timeVC.hafasStation = [MBOPNVStation stationWithId:stationId name:stationName];
        [self.navigationController pushViewController:timeVC animated:YES];

    }

}

+(BOOL)canDisplayMap{
    return !UIAccessibilityIsVoiceOverRunning();
}


@end
