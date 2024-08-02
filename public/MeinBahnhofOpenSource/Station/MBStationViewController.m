// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBStationViewController.h"
#import "MBUIHelper.h"

#import "MBStationCollectionViewCell.h"
#import "MBStationNavigationCollectionViewCell.h"
#import "MBStationGreenTeaserCollectionViewCell.h"
#import "MBStationChatbotTeaserCollectionViewCell.h"
#import "MBStationARTeaserCollectionViewCell.h"
#import "MBUrlOpening.h"
#import "MBARAppTeaserView.h"
#import "MBNewsContainerViewController.h"

#import "MBStationNavigationViewController.h"
#import "MBServiceListCollectionViewController.h"

#import "RIMapPoi.h"
#import "FacilityStatus.h"
#import "MBParkingInfo.h"

#import "MBStationFernverkehrTableViewController.h"
#import "MBTimetableViewController.h"

#import "TimetableManager.h"
#import "MBMapViewController.h"

#import "MBStationInfrastructureViewController.h"
#import "MBOPNVInStationOverlayViewController.h"
#import "MBFacilityStatusViewController.h"
#import "MBParkingTableViewController.h"

#import "HafasRequestManager.h"
#import "MBOPNVStation.h"
#import "MBTutorialManager.h"
#import "MBSettingViewController.h"

#import "MBContentSearchViewController.h"

#import "MBStationOccupancyViewController.h"
#import "MBTrackingManager.h"

#import "MBStationSearchViewController.h"
#import "AppDelegate.h"
#import "MBAccompanimentTeaserView.h"
#import "MBContentSearchResult.h"

@interface MBStationViewController () <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UIAlertViewDelegate>

@property (nonatomic, strong) NSArray *stationInformation;

@property (nonatomic,strong) MBContentSearchButton* contentSearchButton;

@property(nonatomic,strong) MBNewsContainerViewController* newsVC;
@property(nonatomic,strong) UIView* newsContainerView;

@property (nonatomic, strong) UIView *tafelContainerView;
@property (nonatomic, strong) MBStationFernverkehrTableViewController *fernVC;

@property(nonatomic,strong) MBStationOccupancyViewController* occupancyVC;
@property(nonatomic,strong) UIView* occupancyContainerView;

@property (nonatomic, strong) NSDictionary *kachelSizes;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *kacheln;
@property (nonatomic, strong) MBStationKachel* opnvKachel;
@property (nonatomic, strong) MBStationKachel* karteKachel;
@property (nonatomic, strong) MBStationKachel* shopsKachel;
@property (nonatomic, strong) MBStationKachel* feedbackKachel;
@property (nonatomic, strong) MBStationKachel* settingKachel;
@property (nonatomic, strong) MBStationKachel* fahrstuhlKachel;
@property (nonatomic, strong) MBStationKachel* ausstattungKachel;

@property (nonatomic) CGFloat maxTopHeight;
@property (nonatomic) CGFloat currentTopHeight;

@property (nonatomic, strong) UIRefreshControl *refresher;

@property (nonatomic, strong) NSNumber *stationDataAvailable;
@property (nonatomic, strong) NSNumber *facilityDataAvailable;
@property (nonatomic, strong) NSNumber *opnvDataAvailable;

@property(nonatomic,strong) NSArray<MBOPNVStation*>* nearestStationsForOPNV;

@property (nonatomic) BOOL whiteNavBar;
@property (nonatomic) CGFloat currentNavbarHeight;

@property (nonatomic) BOOL viewWasVisibleBefore;

@end

@implementation MBStationViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.whiteNavBar) {
        return UIStatusBarStyleDefault;
    } else {
        return UIStatusBarStyleLightContent;
    }
}

-(void)popToPreviousStation{
    AppDelegate* app = (AppDelegate*) [UIApplication sharedApplication].delegate;
    MBStationSearchViewController* vc = (MBStationSearchViewController*) app.viewController;
    [vc goBackToPreviousStation];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if([MBRootContainerViewController currentlyVisibleInstance].allowBackFromStation){
        UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        [backButton setBackgroundImage:[UIImage imageNamed:@"ChevronBlackLeft"] forState:UIControlStateNormal];
        backButton.accessibilityLabel = @"Zurück zur vorherigen Station";
        UIBarButtonItem *barBackButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
        [backButton addTarget:self action:@selector(popToPreviousStation) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.leftBarButtonItem = barBackButtonItem;
        self.navigationItem.hidesBackButton = YES;
    }

    // make sure back button in navigation bar shows only back icon (<)
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:nil];

    self.currentNavbarHeight = STATION_NAVIGATION_PICTURE_HEIGHT;
    self.whiteNavBar = NO;

    if (nil != self.navigationController) {
        if ([self.navigationController isKindOfClass:[MBStationNavigationViewController class]]) {
            [(MBStationNavigationViewController *)self.navigationController showBackgroundImage:YES];
            if([MBRootContainerViewController currentlyVisibleInstance].allowBackFromStation){
                [(MBStationNavigationViewController *)self.navigationController showBackButtonForStationViewController:self];
            }
        }
    }

    // Do any additional setup after loading the view.
    // top view behind status bar
    // center bottom: title (station name)
    // center top: station icon
    // right top and bottom: weather info at that station
    // background filled with gradient
    // height: 120 points at 375 points width
    
    CGFloat topHeight = floor(self.view.bounds.size.width * 0.32);
    topHeight -= AppDelegate.statusBarHeight;
    self.maxTopHeight = topHeight;
    self.currentTopHeight = topHeight;
    
    
    CGFloat rowWidth2Items = self.view.bounds.size.width - 2*8-2;
    CGFloat smallWidth = floor(rowWidth2Items * 0.333);// width 1/3
    CGFloat largeWidth = rowWidth2Items - smallWidth;// width 2/3
    CGFloat mediumWidth = floor(rowWidth2Items / 2.0);// width 1/2
    CGFloat xlargeWidth = self.view.bounds.size.width - 16.0;// width 1/1
    CGFloat height = 180;
    self.kachelSizes = @{@"small": [NSValue valueWithCGSize:CGSizeMake(smallWidth, height)],
                         @"medium": [NSValue valueWithCGSize:CGSizeMake(mediumWidth, height)],
                         @"large": [NSValue valueWithCGSize:CGSizeMake(largeWidth, height)],
                         @"xlarge": [NSValue valueWithCGSize:CGSizeMake(xlargeWidth, height)],
                         };

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 2.0;
    layout.minimumLineSpacing = 8.0;
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    CGRect initialCollectionFrame = CGRectMake(0, 2, self.view.sizeWidth, self.view.frame.origin.y + self.view.frame.size.height-2);
    self.collectionView = [[UICollectionView alloc] initWithFrame:initialCollectionFrame collectionViewLayout:layout];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = [UIColor db_f0f3f5];
    self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.collectionView.contentInset = UIEdgeInsetsMake(STATION_NAVIGATION_PICTURE_HEIGHT, 8.0, 80.0, 8.0);//80 to keep space for map button, this is modified later after layout!
    
    self.collectionView.isAccessibilityElement = false;
    self.collectionView.shouldGroupAccessibilityChildren = true;

    self.refresher = [[UIRefreshControl alloc] init];
    [self.collectionView addSubview:self.refresher];
    self.collectionView.alwaysBounceVertical = YES;
    [self.refresher addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];

    [self.view addSubview:self.collectionView];
    
    [self.collectionView registerClass:[MBStationGreenTeaserCollectionViewCell class] forCellWithReuseIdentifier:@"GreenCell"];
    [self.collectionView registerClass:[MBStationChatbotTeaserCollectionViewCell class] forCellWithReuseIdentifier:@"ChatbotCell"];
    [self.collectionView registerClass:MBStationARTeaserCollectionViewCell.class forCellWithReuseIdentifier:@"ARTeaser"];
    [self.collectionView registerClass:[MBAccompanimentTeaserView class] forCellWithReuseIdentifier:@"Wegbegleitung"];

    [self.collectionView registerClass:[MBStationNavigationCollectionViewCell class] forCellWithReuseIdentifier:@"NaviCell"];

    //the content search button is part of the navigation controller since it is above the content
    MBStationNavigationViewController *navCon = (MBStationNavigationViewController *)self.navigationController;
    if(UIAccessibilityIsVoiceOverRunning()){
        [navCon removeSearchButton];
        self.contentSearchButton = [MBContentSearchButton new];
        [self.collectionView addSubview:self.contentSearchButton];
        [self.contentSearchButton addTarget:self action:@selector(openContentSearch) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [navCon.contentSearchButton addTarget:self action:@selector(openContentSearch) forControlEvents:UIControlEventTouchUpInside];
    }
    self.fernVC = [[MBStationFernverkehrTableViewController alloc] initWithTrains:nil];
    self.fernVC.title = @"Abfahrt";
    self.fernVC.tableView.scrollEnabled = NO;
    self.fernVC.view.userInteractionEnabled = NO;
    
    self.tafelContainerView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tafelContainerView configureH1Shadow];
    self.tafelContainerView.isAccessibilityElement = YES;
    self.tafelContainerView.accessibilityLabel = @"Abfahrt und Ankunft";
    self.tafelContainerView.accessibilityTraits = UIAccessibilityTraitButton;
    
    
    [self.collectionView addSubview:self.tafelContainerView];

    [self addChildViewController:self.fernVC];
    [self.tafelContainerView addSubview:self.fernVC.view];
    
    self.newsVC = [[MBNewsContainerViewController alloc] init];
    self.newsVC.station = self.station;
    self.newsContainerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.newsContainerView.userInteractionEnabled = YES;
    self.newsContainerView.backgroundColor = [UIColor clearColor];
    self.newsContainerView.hidden = true;
    [self.collectionView addSubview:self.newsContainerView];
    [self addChildViewController:self.newsVC];
    [self.newsContainerView addSubview:self.newsVC.view];
        
    [self setupOccupancy];
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gotoTafel:)];
    [self.tafelContainerView addGestureRecognizer:gesture];
    
    [self.tabBarViewController disableTabAtIndex:3];
    [self.tabBarViewController disableTabAtIndex:4];
    [self.tabBarViewController showTabbar];
}

-(void)setupOccupancy{
    self.occupancyVC = [[MBStationOccupancyViewController alloc] init];
    self.occupancyVC.station = self.station;
    self.occupancyContainerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.occupancyContainerView.userInteractionEnabled = YES;
    self.occupancyContainerView.clipsToBounds = NO;
    self.occupancyContainerView.backgroundColor = [UIColor clearColor];
    [self.collectionView addSubview:self.occupancyContainerView];
    [self addChildViewController:self.occupancyVC];
    [self.occupancyContainerView addSubview:self.occupancyVC.view];
    self.occupancyContainerView.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[MBTutorialManager singleton] displayTutorialIfNecessary:MBTutorialViewType_H1_Tips withOffset:60];
    if(!self.viewWasVisibleBefore){
        self.viewWasVisibleBefore = YES;
        [[MBTutorialManager singleton] displayTutorialIfNecessary:MBTutorialViewType_H1_Search withOffset:60];
    }
    if(self.station.couponsList.count > 0 && self.station.hasShops){
        [[MBTutorialManager singleton] displayTutorialIfNecessary:MBTutorialViewType_H1_Coupons withOffset:60];
    }
    [[MBTutorialManager singleton] displayTutorialIfNecessary:MBTutorialViewType_H1_FacilityPush withOffset:60];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSArray* stationInfo = [MBTrackingManager stationInfoArray];
    if(stationInfo){
        NSString* stationName = stationInfo[1];
        stationName = [stationName lowercaseString];
        stationName = [stationName stringByReplacingOccurrencesOfString:@":" withString:@""];
        stationName = [stationName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        [MBTrackingManager trackStatesWithStationInfo:@[@"h1",stationInfo[0],stationName]];
    } else {
        [MBTrackingManager trackStateWithStationInfo:@"h1"];
    }
    
    if (nil != self.navigationController) {
        if ([self.navigationController isKindOfClass:[MBStationNavigationViewController class]]) {
            [(MBStationNavigationViewController *)self.navigationController behindHeightConstraint].constant = self.currentNavbarHeight;
            [(MBStationNavigationViewController *)self.navigationController showBackgroundImage:!self.whiteNavBar];
            [(MBStationNavigationViewController *)self.navigationController setShowRedBar:self.whiteNavBar];
        }
    }

    if(self.station.isGreenStation || self.station.hasChatbot || self.station.hasARTeaser){
        //increase insets at bottom to avoid collision with map button
        UIEdgeInsets safeAreInsets = self.navigationController.view.safeAreaInsets;
        //NSLog(@"will appear with insets %@",NSStringFromUIEdgeInsets(safeAreInsets));
        self.collectionView.contentInset = UIEdgeInsetsMake(STATION_NAVIGATION_PICTURE_HEIGHT, 8.0, 80.0+40+safeAreInsets.top+safeAreInsets.bottom, 8.0);
    }

    //update position
    [self scrollViewDidScroll:self.collectionView];
    
    [self updateContainerFrames];
    [self.collectionView reloadData];
    if([MBRootContainerViewController currentlyVisibleInstance].startWithDepartures){
        [MBRootContainerViewController currentlyVisibleInstance].startWithDepartures = NO;
        [[MBRootContainerViewController currentlyVisibleInstance] selectTimetableTab];
    }
}

-(void)updateContainerFrames{
    
    NSInteger y = 46;
    if(self.contentSearchButton){
        [self.contentSearchButton layoutForScreenWidth:self.view.sizeWidth-2*8];
        [self.contentSearchButton setGravityTop:15];
        y = CGRectGetMaxY(self.contentSearchButton.frame)+15;
    }
    CGRect newsFrame = CGRectMake(0.0, 0.0, 0.0, 185.0);
    newsFrame.origin.y = y;
    newsFrame.size.width = self.view.frame.size.width - 2*8.0;
    NSInteger tafelY = y;
    self.newsContainerView.frame = newsFrame;
    //resize vc in view
    newsFrame.origin.y = 0;
    self.newsVC.view.frame = newsFrame;

    self.newsVC.newsList = self.station.newsList;
    //this should be refactored: without the necessary data the collectionView will contain no cells and thus the views above (news, teaser, tafel) wont't be accessible. That's why they are hidden until the necessary data was loaded. Ideally all these views are just collectionView cells or we at least have an invisible cell in the collection view.
    if(self.station.newsList.count > 0 && self.hasNecessaryData){
        self.newsContainerView.hidden = NO;
        tafelY = CGRectGetMaxY(self.newsContainerView.frame)+5;
    } else {
        self.newsContainerView.hidden = YES;
    }
    
    CGRect tafelFrameInCollectionView = CGRectMake(0.0, 0.0, 0.0, 242.0);
    tafelFrameInCollectionView.origin.y = tafelY;
    tafelFrameInCollectionView.size.width = self.view.frame.size.width - 2*8.0;
    
    self.tafelContainerView.frame = tafelFrameInCollectionView;
    
    CGRect f = tafelFrameInCollectionView;
    f.size.height = f.size.height-8;
    f.origin.y = 0;
    self.fernVC.view.frame = f;
    //NSLog(@"self.station.occupancy %@",self.station.occupancy);
    if(self.station.occupancy){
        [self.occupancyVC loadData];
        self.occupancyContainerView.hidden = NO;
        self.occupancyContainerView.frame = CGRectMake(0, CGRectGetMaxY(self.tafelContainerView.frame)+5, self.view.frame.size.width-2*8, 255);
        self.occupancyVC.view.frame = CGRectMake(0, 0, self.occupancyContainerView.sizeWidth, self.occupancyContainerView.sizeHeight);
    } else {
        self.occupancyContainerView.hidden = YES;
    }
}


- (void)refresh:(UIRefreshControl *)refresher {
    [refresher beginRefreshing];
    [[MBRootContainerViewController currentlyVisibleInstance] reloadStation];
}

-(void)openContentSearch{
    [MBTrackingManager trackActionsWithStationInfo:@[@"h1",@"tap",@"poi-suche"]];
    MBContentSearchViewController* vc = [[MBContentSearchViewController alloc] init];
    vc.station = self.station;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)gotoTafel:(UITapGestureRecognizer *)gesture {
    UINavigationController *nav = (UINavigationController *)[self.tabBarViewController selectViewControllerAtIndex:2];
    
    MBTimetableViewController *vc = (MBTimetableViewController *)nav.topViewController;
    if ([vc isKindOfClass:[MBTimetableViewController class]]) {
        vc.station = _station;
        vc.departure = YES;
        vc.trackingTitle = @"h2";
        BOOL oldState = vc.showFernverkehr;
            vc.showFernverkehr = YES;
        if(oldState != vc.showFernverkehr){
            vc.trackToggleChange = YES;
        }
    }//else: could be wagenstand!
    
    NSString *trackingKey = @"abfahrt_db";
    if (self.station) {
        [MBTrackingManager trackActionsWithStationInfo:@[@"h1", @"tap", trackingKey]];
    } else {
        [MBTrackingManager trackActions:@[@"h1", @"tap", trackingKey]];
    }
}

- (void)didReceiveTimetableUpdate:(NSNotification *)notification {
    TimetableManager *manager = (TimetableManager *)notification.object;
    if(manager != [TimetableManager sharedManager]){
        return;//FIX for some other manager posting notifications that we don't want here
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateTable];
    });
}

-(void)updateTable{
    if (self.refresher.refreshing) {
        [self.refresher endRefreshing];
    }
    //NSMutableArray *trains = [NSMutableArray array];
    NSArray *allStops = [[[TimetableManager sharedManager] timetable] departureStops];
    
    // only three
    if(allStops.count == 0){
        self.fernVC.trains = @[];
    } else {
        NSArray* trains = [allStops subarrayWithRange:NSMakeRange(0, MIN(3,allStops.count))];
        self.fernVC.trains = trains;
    }
    [self.fernVC.tableView reloadData];
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if (nil == parent) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIF_TIMETABLE_UPDATE object:nil];
        
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveTimetableUpdate:) name:NOTIF_TIMETABLE_UPDATE object:nil];
        
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)hasNecessaryData{
    return self.opnvDataAvailable && self.facilityDataAvailable && self.stationDataAvailable;
}


- (void)reloadStationData {
    if(!self.hasNecessaryData){
        return;
    }
    
    BOOL hasOPNV = self.opnvDataAvailable.boolValue;
    BOOL hasShop = _station.riPoiCategories.count > 0;
    BOOL hasEscalator = _station.facilityStatusPOIs.count > 0;
    
    //testcases
    //hasOPNV = hasShop = hasEscalator = true;
    //hasOPNV = hasShop = hasEscalator = false;
    //hasOPNV = true; hasShop = hasEscalator = false;
    //hasShop = true; hasOPNV = hasEscalator = false;
    //hasEscalator = true; hasOPNV = hasShop = false;
    //hasOPNV = hasShop = true; hasEscalator = false;
    //hasOPNV = hasEscalator = true; hasShop = false;
    //hasShop = hasEscalator = true; hasOPNV = false;
    
    
     NSLog(@"reloadStationData, isGreen %d",self.station.isGreenStation);
    [self updateContainerFrames];
    // fill station info array
    // array has up to 4 items (arrays again)
    // each subarray has a dictionary for the content
    NSMutableArray* kacheln = [NSMutableArray new];
    
    MBStationKachel *ausstatungKachel = [MBStationKachel new];
    ausstatungKachel.title = @"Ausstattung";
    ausstatungKachel.imageName = @"app_bahnhofinfo";
    if(self.stationDataAvailable && !self.stationDataAvailable.boolValue){
        ausstatungKachel.requestFailed = YES;
    }
    self.ausstattungKachel = ausstatungKachel;
    
    // Karte is always available, but can be located in different places
    MBStationKachel *karteKachel = [MBStationKachel new];
    self.karteKachel = karteKachel;
    karteKachel.title = @"Bahnhofskarte";
    karteKachel.imageName = @"map_placeholder";
    karteKachel.station = _station;
    if(!CLLocationCoordinate2DIsValid(self.station.positionAsLatLng)){
        //we have either no geopositon for this station or the poi requests failed, mark as failure
        karteKachel.requestFailed = YES;
    }

    if(nil == self.opnvKachel && hasOPNV){
        self.opnvKachel = [MBStationKachel new];
        self.opnvKachel.title = @"ÖPNV";
        self.opnvKachel.titleForVoiceOver = @"Ö P N V";
        self.opnvKachel.imageName = @"ÖPNV-Kombi-Icon";//special generated icon!
    }
    if(nil == self.shopsKachel && hasShop){
        self.shopsKachel = [MBStationKachel new];
        self.shopsKachel.title = @"Shoppen & Schlemmen";
        self.shopsKachel.imageName = @"app_shop_h1";
    }
    if (nil == self.fahrstuhlKachel && hasEscalator) {
        self.fahrstuhlKachel = [MBStationKachel new];
        self.fahrstuhlKachel.title = @"Aufzüge";
        self.fahrstuhlKachel.imageName = @"app_aufzug_h1";
    }
    // all stations get feedback and einstellungen
    MBStationKachel *einstellungenKachel = [MBStationKachel new];
    self.settingKachel = einstellungenKachel;
    einstellungenKachel.title = @"Einstellungen";
    einstellungenKachel.imageName = @"app_einstellung";
    
    MBStationKachel *feedbackKachel = [MBStationKachel new];
    self.feedbackKachel = feedbackKachel;
    feedbackKachel.title = @"Feedback";
    feedbackKachel.imageName = @"app_dialog";
    
    if (hasEscalator) {
        NSUInteger brokenEscalators = 0;
        for (FacilityStatus *poi in _station.facilityStatusPOIs) {
            if (poi.type == FacilityTypeElevator && (poi.state == FacilityStateUnknown || poi.state == FacilityStateInactive)) {
                brokenEscalators += 1;
            }
        }
        if (nil != self.fahrstuhlKachel) {
            if(brokenEscalators > 0){
                self.fahrstuhlKachel.showWarnIcon = YES;
            }
        }
    }
    
    //Layout
    
    //first row:
    //if we have OPNV it is displayed in one row together with austattung
    //if we don't have OPNV, map moves up and is displayed together with austattung

    //second row
    //if we have    shops and OPNV, then shops is displayed together with map
    //if we have NO shops and OPNV, then only the map is displayed
    //if we have NO shops and NO OPNV, then this line is empty (map+austattung is in line above)
    //if we have    shops and NO OPNV, then shops moves to third line
    
    //third row:
    //see above, can contain shops, followed by aufzüge
    //always followed by einstellung+feedback
    

    NSMutableArray *firstRowKacheln = [NSMutableArray new];
    NSMutableArray *secondRowKacheln = [NSMutableArray new];
    NSMutableArray *thirdRowKacheln = [NSMutableArray new];
    NSMutableArray *fourthRowKacheln = [NSMutableArray new];

    if(hasOPNV){
        [firstRowKacheln addObject:self.opnvKachel];
        [firstRowKacheln addObject:ausstatungKachel];
        if(hasShop){
            [secondRowKacheln addObject:self.shopsKachel];
        }
        [secondRowKacheln addObject:karteKachel];
    } else {
        [firstRowKacheln addObject:karteKachel];
        [firstRowKacheln addObject:ausstatungKachel];
        if(hasShop){
            //shop moves to next line
            [thirdRowKacheln addObject:self.shopsKachel];
        }
    }
    if(hasEscalator){
        [thirdRowKacheln addObject:self.fahrstuhlKachel];
    }

    NSMutableArray* nextLine;
    if(thirdRowKacheln.count >= 2){
        //add einstellungen+feedback in next line
        nextLine = fourthRowKacheln;
    } else {
        nextLine = thirdRowKacheln;
    }
    [nextLine addObject:einstellungenKachel];
    [nextLine addObject:feedbackKachel];

    //construct arrays
    if(self.station.hasAccompanimentServiceActive && UIAccessibilityIsVoiceOverRunning()){
        //fist element in CollectionView, directly below departures
        MBStationKachel* wegKachel = [MBStationKachel new];
        wegKachel.isWegbegleitungTeaser = YES;
        [kacheln addObject:@[ wegKachel ]];
    }
    [kacheln addObject:firstRowKacheln];
    if(secondRowKacheln.count > 0){
        [kacheln addObject:secondRowKacheln];
    }
    if(thirdRowKacheln.count > 0){
        [kacheln addObject:thirdRowKacheln];
    }
    if(fourthRowKacheln.count > 0){
        [kacheln addObject:fourthRowKacheln];
    }
    if(self.station.hasAccompanimentServiceActive && !UIAccessibilityIsVoiceOverRunning()){
        MBStationKachel* wegKachel = [MBStationKachel new];
        wegKachel.isWegbegleitungTeaser = YES;
        [kacheln addObject:@[ wegKachel ]];
    }
    if(self.station.hasARTeaser){
        MBStationKachel* arKachel = [MBStationKachel new];
        arKachel.isARTeaser = YES;
        [kacheln addObject:@[ arKachel ]];
    }
    if(self.station.hasChatbot){
        MBStationKachel* chatKachel = [MBStationKachel new];
        chatKachel.isChatbotTeaser = YES;
        [kacheln addObject:@[ chatKachel ]];
    }
    if(self.station.isGreenStation){
        MBStationKachel* greenKachel = [MBStationKachel new];
        greenKachel.isGreenTeaser = YES;
        [kacheln addObject:@[ greenKachel ]];
    }
    self.kacheln = kacheln;

    [self.collectionView reloadData];
    if(hasShop || hasEscalator){
        //[[MBTutorialManager singleton] displayTutorialIfNecessary:MBTutorialViewType_H1_Live withOffset:60];
    } else {
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[MBTutorialManager singleton] hideTutorials];
}

-(void)dealloc{
    NSLog(@"dealloc MBStationViewController");
}

-(void)updateMapMarkersForFacilities {
    //not implemented, needs to be updated when push services for facilities are available
}

// MARK: UICollectionViewDelegateFlowLayout methods
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    // different layouts, depending on content (_kacheln)
    
    // sizes -> 1: small, 2: medium, 3: large, 4: xlarge
    
    CGSize special = [self specialSizeKachel:indexPath];
    if(special.width > 0){
        return special;
    }
    CGSize itemSize = [[self.kachelSizes objectForKey:@"small"] CGSizeValue];
    // each section has 1 or 2 items
    if (indexPath.section == 0) {
        if (indexPath.item == 0) {
            itemSize = [[self.kachelSizes objectForKey:@"large"] CGSizeValue];
        } else {
            itemSize = [[self.kachelSizes objectForKey:@"small"] CGSizeValue];
        }
    } else if (indexPath.section == 1) {
            NSArray* kachelnLine2 = _kacheln[indexPath.section];
            if(kachelnLine2.count == 1){
                //single object, takes full size
                itemSize = [[self.kachelSizes objectForKey:@"xlarge"] CGSizeValue];
            } else if(kachelnLine2.count == 2) {
                //is there a map? it gets medium size, the other object
                if([kachelnLine2 containsObject:self.karteKachel]){
                    itemSize = [[self.kachelSizes objectForKey:@"small"] CGSizeValue];
                    if(kachelnLine2[indexPath.row] == self.karteKachel){
                        itemSize = [[self.kachelSizes objectForKey:@"large"] CGSizeValue];
                    }
                } else {
                    itemSize = [[self.kachelSizes objectForKey:@"medium"] CGSizeValue];
                }
            } else {
                itemSize = [[self.kachelSizes objectForKey:@"small"] CGSizeValue];
            }
    } else if (indexPath.section == 2) {
            //3 or two items?
            NSArray* kachelnLine2 = _kacheln[indexPath.section];
            if(kachelnLine2.count == 3){
                itemSize = [[self.kachelSizes objectForKey:@"small"] CGSizeValue];
            } else {
                itemSize = [[self.kachelSizes objectForKey:@"medium"] CGSizeValue];
            }
        
    } 
    return itemSize;
}

//return the size of some special sizes tiles, or CGZero for "Normal" ones
-(CGSize)specialSizeKachel:(NSIndexPath*)indexPath{
    MBStationKachel* kachel = _kacheln[indexPath.section][indexPath.row];
    if(kachel.isGreenTeaser || kachel.isChatbotTeaser || kachel.isARTeaser){
        return [self teaserSize];
    }
    if(kachel.isWegbegleitungTeaser){
        if(self.view.sizeWidth <= 320){
            //text will wrap into 4 lines, increased height
            return CGSizeMake(self.view.bounds.size.width - 16.0, 130);
        }
        return CGSizeMake(self.view.bounds.size.width - 16.0, 110);
    }
    return CGSizeZero;
}

-(CGSize)teaserSize{
    CGSize itemSize = [[self.kachelSizes objectForKey:@"xlarge"] CGSizeValue];
    return itemSize;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 8.0, 0);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat distance = scrollView.contentOffset.y;
    CGFloat maxHeight = STATION_NAVIGATION_PICTURE_HEIGHT;
    CGFloat minHeight = self.navigationController.navigationBar.frame.size.height;
    //NSLog(@"initial minHeight %f, distance %f",minHeight,distance);
    
    // safe area + 2 points for red bar, for iPhoneX this is a bit higher than usual
    // because of the camera area, for other iPhones this corresponds to the status bar,
    CGFloat additionalHeight = self.view.safeAreaInsets.top + 2.0;
    minHeight += additionalHeight;
    // do not manipulate the navigation bar if the scroll view content is too small
    if (scrollView.contentSize.height > self.view.frame.size.height - maxHeight) {
        if (nil != self.navigationController) {
            if ([self.navigationController isKindOfClass:[MBStationNavigationViewController class]]) {
                if ([self isEqual:self.navigationController.topViewController]) {
                    MBStationNavigationViewController *navCon = (MBStationNavigationViewController *)self.navigationController;
                    // alpha = 1 if not scrolled at all (or negative distance)
                    // alpha = 0 if scrolled more than minHeight
                    
                    distance = distance+STATION_NAVIGATION_PICTURE_HEIGHT;
                    
                    CGFloat newHeight = maxHeight - distance;
                    CGFloat navBarBottom = self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height;
                    minHeight = minHeight < navBarBottom + 2.0 ? navBarBottom + 2.0 : minHeight;
                    CGFloat alpha = (maxHeight - minHeight - distance) / (maxHeight - minHeight);
                    //NSLog(@"newHeight %f, minHeight %f, alpha %f",newHeight,minHeight,alpha);
                    if (alpha >= 0.0) {
                        navCon.behindView.alpha = alpha > 1.0 ? 1.0 : alpha;
                        self.whiteNavBar = NO;
                        [navCon showBackgroundImage:YES];
                        [navCon setShowRedBar:NO];
                    } else {
                        // change to white now
                        self.whiteNavBar = YES;
                        [navCon showBackgroundImage:NO];
                        [navCon setShowRedBar:YES];
                        navCon.behindView.alpha = 1.0;
                    }
                    if (newHeight > minHeight) {
                        navCon.behindHeightConstraint.constant = newHeight < maxHeight ? newHeight : maxHeight;
                    } else {
                        navCon.behindHeightConstraint.constant = minHeight;
                    }
                    [navCon.behindView setNeedsLayout];
                    
                    CGRect cvRect = self.view.frame;
                    CGFloat topOffset = self.whiteNavBar ? 4-minHeight : 2.0;
                    cvRect.size.height = self.view.frame.origin.y + self.view.frame.size.height - topOffset;
                    cvRect.origin.y = topOffset;
                    self.collectionView.frame = cvRect;
                    
                    self.currentNavbarHeight = navCon.behindHeightConstraint.constant;
                }
            }
        }
    }
}

// MARK: UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.kacheln.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSArray *subKacheln = self.kacheln[section];
    return subKacheln.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        CGSize size = CGSizeZero;
        // distance needed for header of section below
        if(self.occupancyContainerView.isHidden){
            size.height = CGRectGetMaxY(self.tafelContainerView.frame);//self.tafelContainerView.frame.size.height + 16.0;
        } else {
            size.height = CGRectGetMaxY(self.occupancyContainerView.frame)+11;
        }
        return size;
    } else {
        return CGSizeZero;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    BOOL isGreenTeaser = NO;
    MBStationKachel* kachel = _kacheln[indexPath.section][indexPath.item];
    if(kachel.isGreenTeaser){
        isGreenTeaser = YES;
    } else if(kachel.isChatbotTeaser){
        MBStationChatbotTeaserCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ChatbotCell" forIndexPath:indexPath];
        cell.reducedSize = false;
        return cell;
    } else if(kachel.isARTeaser){
        MBStationARTeaserCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ARTeaser" forIndexPath:indexPath];
        return cell;
    } else if(kachel.isWegbegleitungTeaser){
        MBAccompanimentTeaserView* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Wegbegleitung" forIndexPath:indexPath];
        return cell;
    }
    
    MBStationCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:(isGreenTeaser) ? @"GreenCell" : @"NaviCell" forIndexPath:indexPath];
    if([cell isKindOfClass:MBStationNavigationCollectionViewCell.class]){
        MBStationNavigationCollectionViewCell* naviCell = (MBStationNavigationCollectionViewCell*) cell;
        naviCell.kachel = _kacheln[indexPath.section][indexPath.item];
        
        if(naviCell.kachel == self.karteKachel
           ){
            naviCell.imageAsBackground = YES;
        }
    } else if([cell isKindOfClass:MBStationGreenTeaserCollectionViewCell.class]) {
        //green teaser
        
    }
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    MBStationKachel* kachel = _kacheln[indexPath.section][indexPath.item];
    if(kachel.isGreenTeaser)
    {
        if(UIAccessibilityIsVoiceOverRunning()){
            [MBStationGreenTeaserCollectionViewCell openExternalLink];
        }
        return;
    }
    if(kachel.isChatbotTeaser){
        //link to services
        [MBTrackingManager trackActionsWithStationInfo:@[@"h1",@"tap",@"chatbot"]];
        [self moveToServiceListControllerAndConfigureController:^(MBServiceListCollectionViewController * _Nonnull controller) {
            controller.openChatBotScreen = YES;
        }];
        return;
    }
    if(kachel.isARTeaser){
        [MBUrlOpening openURL:[NSURL URLWithString:AR_TEASER_LINK]];
        return;
    }
    if(kachel.isWegbegleitungTeaser){
        [self moveToServiceListControllerAndConfigureController:^(MBServiceListCollectionViewController * _Nonnull controller) {
            controller.openWegbegleitungScreen = YES;
        }];
        return;
    }
    
    NSString *trackingActionKey = @"";
    
    if(kachel == self.karteKachel){
        if(self.karteKachel.requestFailed){
            //return;//nope, some data my be available
        }
        [MBMapConsent.sharedInstance showConsentDialogInViewController:self completion:^{
            MBMapViewController* vc = [MBMapViewController new];
            [vc configureWithStation:self.station];
            [self presentViewController:vc animated:YES completion:nil];
        }];
        trackingActionKey = @"map";
    } else if (kachel == self.shopsKachel) {
        [self.tabBarViewController selectViewControllerAtIndex:4];
        MBServiceListCollectionViewController *listController
            = (MBServiceListCollectionViewController*)[self.tabBarViewController visibleViewController];
        if([listController isKindOfClass:MBServiceListCollectionViewController.class]){
            listController.tabBarViewController = self.tabBarViewController;
        }
        NSLog(@"controller != nil > %@", ([[self.tabBarViewController visibleViewController] class]));
        trackingActionKey = @"shops";
    } else if(kachel == self.fahrstuhlKachel){
        [self showFacilityViewAndReload:false];
        trackingActionKey = @"aufzuege";
    } else if(kachel == self.feedbackKachel){
        [MBTrackingManager trackActionsWithStationInfo:@[@"h1",@"tap",@"feedback"]];
        [self moveToServiceListControllerAndConfigureController:^(MBServiceListCollectionViewController * _Nonnull controller) {
            controller.openServiceNumberScreen = true;
        }];
        return;
    } else if(kachel == self.settingKachel){
        MBSettingViewController* vc = [MBSettingViewController new];
        vc.currentStation = self.station;
        vc.title = kachel.title;
        [self.navigationController pushViewController:vc animated:YES];
        trackingActionKey = @"einstellungen";
    } else if(kachel == self.ausstattungKachel){
        [self openStationFeatures];
        trackingActionKey = @"ausstattungs_merkmale";
    } else if(kachel == self.opnvKachel){
        [self openOPNV];
        trackingActionKey = @"oepnv";
    }
    
    if (self.station) {
        [MBTrackingManager trackActionsWithStationInfo:@[@"h1", @"tap", trackingActionKey]];
    } else {
        [MBTrackingManager trackActions:@[@"h1", @"tap", trackingActionKey]];
    }
}

-(void)showFacilityViewAndReload:(BOOL)reload{
    MBFacilityStatusViewController *vc = [MBFacilityStatusViewController new];
    vc.station = _station;
    vc.reloadStatusOnFirstView = reload;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)moveToServiceListControllerAndConfigureController:(void (^)(MBServiceListCollectionViewController * _Nonnull controller))configurationBlock{
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [self.tabBarViewController selectViewControllerAtIndex:3];
    }];
    MBStationNavigationViewController* nav = self.tabBarViewController.viewControllers[3];
    MBServiceListCollectionViewController *listController
    = (MBServiceListCollectionViewController*)nav.visibleViewController;
    if(![listController isKindOfClass:MBServiceListCollectionViewController.class]){
        [nav popToRootViewControllerAnimated:NO];
    }
    listController = nav.viewControllers.firstObject;
    listController.tabBarViewController = self.tabBarViewController;
    configurationBlock(listController);
    [CATransaction commit];
}

-(void)openStationFeatures{
    if(self.ausstattungKachel.requestFailed){
        return;
    }
    MBStationInfrastructureViewController * vc = [[MBStationInfrastructureViewController alloc] init];
    vc.station = self.station;
    [MBRootContainerViewController presentViewControllerAsOverlay:vc allowNavigation:YES];
}
-(void)openOPNV{
    MBOPNVInStationOverlayViewController* vc = [[MBOPNVInStationOverlayViewController alloc] init];
    vc.nearestStations = self.nearestStationsForOPNV;
    vc.station = self.station;
    [MBRootContainerViewController presentViewControllerAsOverlay:vc allowNavigation:YES];
}


# pragma mark MBRootContainerViewControllerDelegate

-(void)willStartLoadingData{
    NSLog(@"willStartLoadingData");
    /*
    if (self.station.stationEvaIds.count > 0) {
        if([[MBRootContainerViewController currentlyVisibleInstance].preloadedDepartures isEqualToArray: self.station.stationEvaIds]){
            NSLog(@"skip timetable reload in station, was preloaded in station search");
            [MBRootContainerViewController currentlyVisibleInstance].preloadedDepartures = nil;
        } else {
            NSLog(@"timetable started from willStartLoadingData...");
            [[TimetableManager sharedManager] reloadTimetableWithEvaIds:self.station.stationEvaIds];
        }
    }*/
    
    [self hafasNearbyStationsRequest];
}

-(void)didLoadStationData:(BOOL)success{
    NSLog(@"didLoadStationData: %d",success);
    
    if(!success && self.stationDataAvailable.boolValue){
        //special case: user reloaded and the station data failed, just ignore this as we already have data!
        return;
    }
    self.stationDataAvailable = @(success);
    
    if([self infoTabHasServices]){
        [self.tabBarViewController enableTabAtIndex:3];
    }
}

-(void)hafasNearbyStationsRequest{
    [[HafasRequestManager sharedManager] requestNearbyStopsForCoordinate:self.station.positionAsLatLng filterOutDBStation:NO withCompletion:^(NSArray<MBOPNVStation*> *nearbyStations) {
        MBOPNVStation *nearestStopLocation = nearbyStations.firstObject;
        NSLog(@"nearestStopLocation: %@",nearestStopLocation.name);
        //Filter out stations for OPNV-display by distance
        NSMutableArray<MBOPNVStation*>* nearestStationsForOPNV = [NSMutableArray arrayWithCapacity:10];
        for(MBOPNVStation* station in nearbyStations){
            if(station.distanceInM <= NEAREST_STATIONS_LIMIT_IN_M){
                [nearestStationsForOPNV addObject:station];
            }
        }
        /*NSLog(@"nearby stations:");
        for(NSDictionary* station in nearestStationsForOPNV){
            NSLog(@"got station %@, %@",station[@"name"],station[@"dist"]);
        }*/
        self.nearestStationsForOPNV = nearestStationsForOPNV;
        self.station.nearestStationsForOPNV = nearestStationsForOPNV;
        
        BOOL hadStatus = self.opnvDataAvailable != nil;
        BOOL oldStatus = self.opnvDataAvailable.boolValue;
        if(self.nearestStationsForOPNV.count > 0){
            self.opnvDataAvailable = @(YES);
        } else {
            self.opnvDataAvailable = @(NO);
        }
        if((!hadStatus && self.opnvDataAvailable) || oldStatus != self.opnvDataAvailable.boolValue){
            [self reloadStationData];
        }

        
        // fill timetable with information from stops
        if (nil != nearestStopLocation) {
            MBTimetableViewController* vc = [[MBRootContainerViewController currentlyVisibleInstance] timetableVC];
            vc.hafasStation = nearestStopLocation;
        } else {
            // do something, when no stops with ÖPNV are found
        }

    }];
}

-(void)didLoadIndoorMapLevels:(BOOL)success{
    NSLog(@"didLoadIndoorMapLevels: %d",success);
}

-(void)didLoadMapPOIs:(BOOL)success{
    NSLog(@"didLoadMapPOIs: %d, shops %lu",success,(unsigned long)self.station.riPois.count);

    if(success && self.station.hasShops){
        [self.tabBarViewController enableTabAtIndex:4];
    }
}

- (void)didLoadNewsData{
    [self reloadStationData];
}

//async, called later
-(void)didLoadSEVData{
    [self refreshInfoView];
}
-(void)didLoadLockerData{
    [self refreshInfoView];
}
-(void)didLoadParkingData{
    [self refreshInfoView];
}

-(void)refreshInfoView{
    if([self infoViewIsVisible]){
        [MBRootContainerViewController.currentlyVisibleInstance.infoVC reloadData];
    }
}
-(BOOL)infoViewIsVisible{
    return MBRootContainerViewController.currentlyVisibleInstance.stationTabBarViewController.visibleViewController == MBRootContainerViewController.currentlyVisibleInstance.infoVC;
}



-(void)didLoadFacilityData:(BOOL)success{
    NSLog(@"didLoadFacilityData: %d",success);
    self.facilityDataAvailable = @(success);
    [self reloadStationData];
}


-(void)didFinishAllLoading{
    NSLog(@"didFinishAllLoading");
    
    if([self infoTabHasServices]){
        [self.tabBarViewController enableTabAtIndex:3];
    }

    [self reloadStationData];
    [self.refresher endRefreshing];
    if([MBRootContainerViewController currentlyVisibleInstance].startWithFacility){
        [MBRootContainerViewController currentlyVisibleInstance].startWithFacility = NO;
        [self showFacilityViewAndReload:false];
    }
}

-(BOOL)infoTabHasServices{
    MBStationNavigationViewController* nav = self.tabBarViewController.viewControllers[3];
    MBServiceListCollectionViewController *listController
    = (MBServiceListCollectionViewController*)nav.viewControllers.firstObject;
    if([listController isKindOfClass:MBServiceListCollectionViewController.class]){
        NSArray* services = listController.prepareServices;
        if(services.count > 0){
            return YES;
        }
    }
    return NO;
}

@end
