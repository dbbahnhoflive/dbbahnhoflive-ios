// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBServiceListCollectionViewController.h"
#import "MBServiceCollectionViewCell.h"
#import "MBStationKachel.h"
#import "MBService.h"
#import "MBMenuItem.h"
#import "MBAdContainer.h"
#import "MBCouponCategory.h"

#import "MBStationTabBarViewController.h"
#import "MBServiceListTableViewController.h"
#import "MBStationNavigationViewController.h"

#import "MBDetailViewController.h"

#import "MBFacilityStatusViewController.h"
#import "MBParkingTableViewController.h"
#import "MBPXRShopCategory.h"
#import "RIMapPoi.h"


#import "MBStaticStationInfo.h"
#import "MBEinkaufsbahnhofCategory.h"
#import "MBContentSearchResult.h"
#import "AppDelegate.h"

@interface MBServiceListCollectionViewController () <UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic) MBServiceCollectionType serviceType;
@property (nonatomic, strong) NSArray *services;

@property (nonatomic, strong) NSArray *pxrCategories;//MBPXRShopCategory
@property (nonatomic, assign) BOOL preserveBackButton;

@property (nonatomic) BOOL isPrepared;

@end

@implementation MBServiceListCollectionViewController

static NSString * const kServiceCollectionViewCellReuseIdentifier = @"Cell";

- (instancetype)initWithType:(MBServiceCollectionType)type {
    self = [super init];
    if(self){
        self.serviceType = type;
        switch (type) {
            case MBServiceCollectionTypeInfo:
                self.title = @"Bahnhofsinformationen";
                break;
            case MBServiceCollectionTypeShopping:
                self.title = @"Shoppen & Schlemmen";
                break;
            case MBServiceCollectionTypeFeedback:
                self.title = @"Feedback";
                break;
        }
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"dealloc MBServiceListCollectionViewController");
}

- (void)setServices:(NSArray *)services {
    if (services != nil && services != _services) {
        _services = services;
        [self.collectionView reloadData];
    }
}



- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:nil];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    
    layout.minimumLineSpacing = 8.0;
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumInteritemSpacing = 8.0;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = [UIColor db_f0f3f5];
    self.collectionView.contentInset = UIEdgeInsetsMake(8.0, 8.0, 80.0+8.0, 8.0);
    
    [self.view addSubview:self.collectionView];

    // Register cell classes
    [self.collectionView registerClass:[MBServiceCollectionViewCell class] forCellWithReuseIdentifier:kServiceCollectionViewCellReuseIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (nil != self.navigationController) {
        if ([self.navigationController isKindOfClass:[MBStationNavigationViewController class]]) {
            [(MBStationNavigationViewController *)self.navigationController hideNavbar:NO];
            [(MBStationNavigationViewController *)self.navigationController showBackgroundImage:NO];
            [(MBStationNavigationViewController *)self.navigationController setShowRedBar:YES];
        }
    }
    
    [self prepareForDisplay];
    
}

-(void)handleSearchResult{
    if(self.searchResult){
        if(self.searchResult.isShopSearch){
            if(self.searchResult.isPickpackSearch){
                MBService* service = [MBStaticStationInfo serviceForType:@"pickpack" withStation:_station];
                MBDetailViewController* vc = [[MBDetailViewController alloc] initWithStation:self.station];
                [vc setItem:service];
                [self.navigationController pushViewController:vc animated:NO];
                self.searchResult = nil;
                return;
            }
            
            if(self.searchResult.poiCat
               || self.searchResult.storeCat
               || self.searchResult.couponItem){
                id cat = (self.searchResult.poiCat ? self.searchResult.poiCat : self.searchResult.storeCat);
                if(self.searchResult.couponItem){
                    MBCouponCategory* cCat = [MBCouponCategory new];
                    cCat.items = self.station.couponsList;
                    cat = cCat;
                }
                MBServiceListTableViewController* vc = [[MBServiceListTableViewController alloc] initWithItem:cat];
                vc.searchResult = self.searchResult;
                [self.navigationController pushViewController:vc animated:NO];
            }
        } else if(self.searchResult.isStationInfoSearch){
            if(self.searchResult.isStationInfoLocalServicesSearch){
                if(self.searchResult.isLocalServiceDBInfo){
                    self.searchResult.service = [self findServiceWithType:@"db_information"];
                } else if(self.searchResult.isLocalServiceMobileService){
                    self.searchResult.service = [self findServiceWithType:@"mobiler_service"];
                } else if(self.searchResult.isLocalMission){
                    self.searchResult.service = [self findServiceWithType:@"bahnhofsmission"];
                } else if(self.searchResult.isLocalTravelCenter){
                    self.searchResult.service = [self findServiceWithType:@"local_travelcenter"];
                } else if(self.searchResult.isLocalLounge){
                    self.searchResult.service = [self findServiceWithType:@"local_db_lounge"];
                }
                [self collectionView:self.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            } else if(self.searchResult.isStationInfoPhoneSearch){
                if(self.searchResult.isStationInfoPhoneMobility){
                    self.searchResult.service = [self findServiceWithType:@"mobilitaetsservice"];
                } else if(self.searchResult.isStationInfoPhone3S){
                    self.searchResult.service = [self findServiceWithType:@"3-s-zentrale"];
                } if(self.searchResult.isStationInfoPhoneLostservice){
                    self.searchResult.service = [self findServiceWithType:@"local_lostfound"];
                } if(self.searchResult.isChatBotSearch){
                    self.searchResult.service = [self findServiceWithType:@"chatbot"];
                }
                //find the index of the "rufnummern & services" tile
                NSIndexPath* servicePath = [self indexPathForServiceCategoryType:@"rufnummern"];
                if(servicePath){
                    [self collectionView:self.collectionView didSelectItemAtIndexPath:servicePath];
                }
            } else if(self.searchResult.isParkingSearch){
                MBParkingTableViewController* vc = [MBParkingTableViewController new];
                [vc setParkingList:self.station.parkingInfoItems];
                [self.navigationController pushViewController:vc animated:NO];
            } else if(self.searchResult.isSteplessAccessSearch){
                MBService* service = [self findServiceWithType:@"stufenfreier_zugang"];
                MBDetailViewController* vc = [[MBDetailViewController alloc] initWithStation:self.station];
                [vc setItem:service];
                [self.navigationController pushViewController:vc animated:NO];
            } else if(self.searchResult.isWifiSearch){
                MBService* service = [self findServiceWithType:@"wlan"];
                MBDetailViewController* vc = [[MBDetailViewController alloc] initWithStation:self.station];
                [vc setItem:service];
                [self.navigationController pushViewController:vc animated:NO];
            } else if(self.searchResult.isElevatorSearch){
                MBFacilityStatusViewController *facilityVC = [[MBFacilityStatusViewController alloc] init];
                facilityVC.title = @"Aufzüge";
                facilityVC.station = self.station;
                [self.navigationController pushViewController:facilityVC animated:NO];
            }
        }
        self.searchResult = nil;
    }
}

-(NSIndexPath*)indexPathForServiceCategoryType:(NSString*)type{
    NSInteger section = 0;
    NSInteger row = 0;
    for(MBMenuItem* item in self.services){
        if([item.type isEqualToString:type]){
            return [NSIndexPath indexPathForRow:row inSection:section];
        }
        row++;
    }
    return nil;
}

-(void)prepareForDisplay{
    if(self.isPrepared){
        //return;
    }
    
    self.pxrCategories = _station.riPoiCategories;
    switch(_serviceType){
        case MBServiceCollectionTypeInfo:
            self.services = [self prepareServices];
            break;
        case MBServiceCollectionTypeShopping:
            self.services = _station.einkaufsbahnhofCategories;
            break;
        case MBServiceCollectionTypeFeedback:
            self.services = [self prepareFeedback];
            break;
    }
    
    //add additional items in shop list
    if (_serviceType == MBServiceCollectionTypeShopping){
        BOOL isPxrSource = YES;
        NSArray* source = self.pxrCategories;
        if(self.pxrCategories.count == 0){
            isPxrSource = NO;
            source = self.services;
        }
        if(!source){
            //special case: we have a station without shops, BUT probably a pickpack
            source = @[];
        }
        NSMutableArray* sourceMutable = [source mutableCopy];

        if (self.station.couponsList.count > 0) {
            //add coupon kachel
            MBCouponCategory* couponContainer = [MBCouponCategory new];
            couponContainer.items = self.station.couponsList;
            [sourceMutable addObject:couponContainer];
        }
        
        
        if (self.station.hasPickPack) {
            //add adverting pickpack kachel
            MBAdContainer* adContainer = [MBAdContainer new];
            adContainer.type = MBAdContainerTypePickPack;
            adContainer.voiceOverText = @"pick pack";
            adContainer.imageName = @"pickpack";
            adContainer.trackingAction = @[@"h3",@"shops",@"tap",@"pickpack"];
            adContainer.isSquare = YES;
            [sourceMutable addObject:adContainer];
        }

        if (self.station.isEinkaufsbahnhof) {
            //add adverting MEK kachel
            MBAdContainer* adContainer = [MBAdContainer new];
            adContainer.voiceOverText = @"Von früh bis spät an 365 Tagen im Jahr einkaufen. Mein Einkaufsbahnhof.";
            adContainer.type = MBAdContainerTypeEinkaufsbahnhof;
            adContainer.url = [NSURL URLWithString:@"https://www.einkaufsbahnhof.de/"];
            adContainer.trackingAction = @[@"h3",@"shops",@"tap",@"mek-teaser"];
            adContainer.isSquare = YES;
            [sourceMutable addObject:adContainer];
        }
        
        //do we need a larger last kachel?
        MBAdContainer* lastOne = sourceMutable.lastObject;
        if([lastOne isKindOfClass:MBAdContainer.class] && (sourceMutable.count % 2) != 0){
            lastOne.isSquare = NO;
        }
        
        if(isPxrSource){
            self.pxrCategories = sourceMutable;
        } else {
            self.services = sourceMutable;
        }
    }
    
    [self.collectionView reloadData];

    self.isPrepared = YES;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    switch(_serviceType){
        case MBServiceCollectionTypeInfo:
            [MBTrackingManager trackStatesWithStationInfo:@[@"h3", @"info"]];
            break;
        case MBServiceCollectionTypeShopping:
            [MBTrackingManager trackStatesWithStationInfo:@[@"h3", @"shops"]];
            break;
        case MBServiceCollectionTypeFeedback:
            [MBTrackingManager trackStatesWithStationInfo:@[@"d2", @"feedback"]];
            break;
    }
    
    if (self.tabBarViewController) {
        [MBUIViewController addBackButtonToViewController:self andActionBlockOrNil:^{
            [self.tabBarViewController selectViewControllerAtIndex:1];
        }];
    }
    
    if(self.openChatBotScreen || self.openPickPackScreen){
        BOOL isChat = self.openChatBotScreen;
        NSString* serviceName = @"chatbot";
        if(!isChat){
            //pickpack
            serviceName = @"pickpack";
        }
        self.openChatBotScreen = NO;
        self.openPickPackScreen = NO;
        BOOL displayAsSingleScreen = NO;
        if(displayAsSingleScreen){
            MBService* service = [MBStaticStationInfo serviceForType:serviceName withStation:_station];
            UIViewController* vc = [[MBDetailViewController alloc] initWithStation:self.station];
            [(MBDetailViewController *)vc setItem:service];
            [self.navigationController pushViewController:vc animated:NO];
        } else {
            //we simulate a search to reuse the exiting code for displaying a service item
            if(isChat){
                self.searchResult = [MBContentSearchResult searchResultForChatbot];
            } else {
                self.searchResult = [MBContentSearchResult searchResultForPickpack];
            }
        }
    }
    [self handleSearchResult];
}

-(MBService*)findServiceWithType:(NSString*)type{
    for(id something in _services){
        if([something isKindOfClass:MBMenuItem.class]){
            MBMenuItem* menu = something;
            for(MBService* service in menu.services){
                if([service.type isEqualToString:type]){
                    return service;
                }
            }
        }
    }
    return nil;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Hacky way to hide the back button only when the user leaves the screen
    if (self.tabBarViewController && !self.preserveBackButton) {
        [MBUIViewController removeBackButton:self];
        self.tabBarViewController = nil;
    }
    self.preserveBackButton = NO;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.collectionView.frame = self.view.bounds;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addService:(NSString*)title type:(NSString*)type index:(NSInteger)index to:(NSMutableArray *)infoServices {
    NSMutableDictionary* newItemDict = [NSMutableDictionary new];
    [newItemDict setObject:title forKey:@"title"];
    [newItemDict setObject:type forKey:@"type"];
    MBService* service = [MBStaticStationInfo serviceForType:type withStation:_station];
    [newItemDict setObject:@[service] forKey:@"services"];
    [newItemDict setObject:@(index) forKey:@"position"];
    MBMenuItem *menuItem = [[MBMenuItem alloc] initWithDictionary:newItemDict error:nil];
    [infoServices addObject:menuItem];
}

-(NSArray*)prepareFeedback{
    NSMutableArray *infoServices = [NSMutableArray new];

    int stations[] = {
    22,
    23,
    28,
    80,
    85,
    87,
    108,
    116,
    7719,
    169,
    177,
    187,
    192,
    202,
    7966,
    203,
    207,
    220,
    237,
    251,
    264,
    2886,
    315,
    316,
    332,
    6129,
    334,
    392,
    393,
    430,
    4361,
    450,
    475,
    503,
    504,
    520,
    525,
    6340,
    526,
    2035,
    1071,
    530,
    4809,
    5016,
    4859,
    533,
    534,
    53,
    535,
    536,
    537,
    538,
    527,
    539,
    528,
    540,
    541,
    542,
    543,
    544,
    595,
    545,
    546,
    547,
    548,
    549,
    7720,
    550,
    551,
    552,
    553,
    554,
    532,
    555,
    556,
    557,
    559,
    561,
    563,
    7721,
    565,
    566,
    6723,
    567,
    568,
    571,
    7910,
    591,
    592,
    7726,
    7958,
    622,
    623,
    811,
    8281,
    6792,
    628,
    631,
    639,
    643,
    652,
    655,
    660,
    661,
    688,
    723,
    724,
    763,
    4568,
    767,
    779,
    780,
    782,
    783,
    785,
    791,
    801,
    803,
    814,
    816,
    835,
    840,
    855,
    8251,
    888,
    951,
    963,
    968,
    970,
    972,
    1028,
    1040,
    1056,
    1062,
    8248,
    1077,
    1104,
    1108,
    1126,
    1141,
    1146,
    1180,
    1289,
    1341,
    1343,
    1352,
    1374,
    1390,
    1401,
    1484,
    1491,
    7722,
    1501,
    1507,
    1537,
    1590,
    1610,
    1634,
    1641,
    1645,
    1659,
    1683,
    1690,
    1782,
    1787,
    1793,
    8192,
    1821,
    1866,
    7982,
    1889,
    1893,
    1901,
    1932,
    1944,
    1967,
    1969,
    1973,
    2008,
    2109,
    2120,
    2218,
    529,
    2262,
    2268,
    2288,
    2391,
    2438,
    2447,
    2498,
    2500,
    7772,
    2513,
    2514,
    2517,
    2519,
    2528,
    733,
    2621,
    2545,
    2610,
    7728,
    2622,
    2623,
    2628,
    2632,
    7729,
    2678,
    2681,
    2689,
    2691,
    2708,
    2716,
    2743,
    2747,
    5817,
    2760,
    2767,
    2790,
    2832,
    2866,
    2884,
    2890,
    2900,
    2901,
    2912,
    2923,
    2924,
    2927,
    2928,
    2930,
    2162,
    3821,
    4820,
    2944,
    2961,
    1670,
    3493,
    2998,
    3006,
    3008,
    3012,
    3032,
    7759,
    3067,
    3094,
    3095,
    3096,
    7723,
    3107,
    3127,
    3135,
    3200,
    6660,
    3201,
    3299,
    3318,
    3320,
    3329,
    3343,
    3394,
    3402,
    3420,
    1496,
    3750,
    3463,
    3464,
    3487,
    3491,
    3511,
    7144,
    3611,
    3617,
    3631,
    3658,
    3662,
    104,
    2264,
    4024,
    3668,
    3670,
    3671,
    3673,
    3703,
    7730,
    3746,
    3749,
    3768,
    3801,
    3828,
    915,
    3832,
    3847,
    3856,
    5032,
    3857,
    3871,
    3872,
    3881,
    3891,
    3898,
    3925,
    3942,
    3947,
    3987,
    3997,
    4027,
    4032,
    4053,
    4054,
    4066,
    4076,
    6840,
    7727,
    4079,
    4081,
    4092,
    4120,
    4204,
    4234,
    4241,
    4266,
    4280,
    7655,
    39,
    135,
    4546,
    2771,
    7813,
    8247,
    5928,
    4329,
    7908,
    4382,
    4385,
    4425,
    4492,
    4522,
    4557,
    4566,
    4582,
    167,
    4593,
    4692,
    4722,
    4731,
    4735,
    4739,
    7774,
    4767,
    4768,
    7731,
    4777,
    4778,
    7762,
    890,
    4846,
    4847,
    4848,
    4880,
    5824,
    4854,
    8356,
    4905,
    7662,
    7732,
    4950,
    4965,
    4976,
    4998,
    5012,
    5026,
    5036,
    5070,
    4914,
    5099,
    5100,
    5122,
    5129,
    5145,
    5159,
    5169,
    5213,
    5247,
    5251,
    4080,
    5287,
    5340,
    2879,
    5365,
    5484,
    5496,
    5507,
    5523,
    5537,
    5545,
    5559,
    5563,
    5564,
    5598,
    558,
    5659,
    5665,
    560,
    5684,
    7734,
    5755,
    5763,
    5818,
    5819,
    800,
    5825,
    5839,
    5842,
    2957,
    5844,
    5854,
    5876,
    5896,
    7736,
    5934,
    781,
    997,
    3369,
    5996,
    3030,
    5999,
    6028,
    6042,
    6058,
    6059,
    6060,
    7761,
    6066,
    6071,
    7146,
    6123,
    6164,
    2871,
    6217,
    6251,
    6298,
    6323,
    6335,
    6337,
    6336,
    6428,
    6447,
    6453,
    6454,
    6466,
    6472,
    6537,
    6539,
    8249,
    6550,
    6551,
    8214,
    7756,
    6617,
    6664,
    6683,
    6686,
    6689,
    6706,
    6707,
    6708,
    7760,
    6720,
    6724,
    6731,
    6744,
    6763,
    6771,
    7590,
    5415,
    6807,
    6824,
    6871,
    6898,
    6899,
    6939,
    6940,
    6945,
    6967,
    7755,
    6998,
    7010
    };

    NSInteger currentId = self.station.mbId.integerValue;
    BOOL stationHasDirtyService = false;
    for(NSInteger i=0; i<(sizeof stations) / (sizeof stations[0]); i++){
        int stationid = stations[i];
        if(currentId == stationid){
            stationHasDirtyService = true;
            break;
        }
    }
    if(stationHasDirtyService){
        AppDelegate* app = (AppDelegate*) [UIApplication sharedApplication].delegate;
        BOOL hasWhatsApp = [app canOpenURL:[NSURL URLWithString:@"whatsapp://send?text=Hallo"]];
        [self addService:@"Verschmutzungen und Defekte melden" type: hasWhatsApp ? @"verschmutzung_mitwhatsapp" : @"verschmutzung_ohnewhatsapp" index:1 to:infoServices];
    }
    [self addService:@"App bewerten" type:@"bewertung" index:2 to:infoServices];
    [self addService:@"Problem mit der App melden" type:@"problemmelden" index:3 to:infoServices];

    return infoServices;
}

- (NSArray *)prepareServices {
    NSLog(@"prepareServices");
    NSMutableArray *infoServices = [NSMutableArray new];
    // fill in services according to plan set out here

    NSMutableArray* filteredInfoServices = [NSMutableArray arrayWithCapacity:3];
    
    NSMutableArray *rufnummernServices = [NSMutableArray arrayWithCapacity:3];
    
    MBPTSStationResponse* details = _station.stationDetails;
    if(details.hasDBInfo){
        MBService* service = [MBStaticStationInfo serviceForType:@"db_information" withStation:_station];
        [filteredInfoServices addObject:service];
    }
    
    if(details.hasLocalServiceStaff){
        MBService* service = [MBStaticStationInfo serviceForType:@"mobiler_service" withStation:_station];
        [filteredInfoServices addObject:service];
    }
    
    if(details.hasRailwayMission){
        [filteredInfoServices addObject:[MBStaticStationInfo serviceForType:@"bahnhofsmission" withStation:_station]];
    }
    
    if(details.hasTravelCenter || _station.travelCenter != nil){
        MBService* service = [MBStaticStationInfo serviceForType:@"local_travelcenter" withStation:_station];
        [filteredInfoServices addObject:service];
    }
    if(details.hasDBLounge){
        MBService* service = [MBStaticStationInfo serviceForType:@"local_db_lounge" withStation:_station];
        [filteredInfoServices addObject:service];
    }
    
    
    if(details.hasMobilityService){
        MBService* service = [MBStaticStationInfo serviceForType:@"mobilitaetsservice" withStation:_station];
        [rufnummernServices addObject:service];
    }
    
    if(details.has3SZentrale){
        MBService* service = [MBStaticStationInfo serviceForType:@"3-s-zentrale" withStation:_station];
        [rufnummernServices addObject:service];
    }
    
    if(details.hasLostAndFound){
        MBService* service = [MBStaticStationInfo serviceForType:@"local_lostfound" withStation:_station];
        [rufnummernServices addObject:service];
    }
    
    if(_station.hasChatbot){
        MBService* service = [MBStaticStationInfo serviceForType:@"chatbot" withStation:_station];
        [rufnummernServices addObject:service];
    }

    
    if(details.hasWiFi){
        NSDictionary* wlanData = [MBStaticStationInfo infoForType:@"wlan"];
        MBService *wlanService = [[MBService alloc] initWithDictionary:wlanData error:nil];
        MBMenuItem *wlanItem = [[MBMenuItem alloc] initWithDictionary:@{ @"position":@(2),
                                                                         @"services":@[wlanService],
                                                                         @"title":@"WLAN",
                                                                         @"type":@"wlan",
                                                                         } error:nil];
        [infoServices addObject:wlanItem];
    }
    
    if(details.hasSteplessAccess){
        MBService* service = [MBStaticStationInfo serviceForType:@"stufenfreier_zugang" withStation:_station];
        NSMutableDictionary *newItemDict = [NSMutableDictionary new];
        [newItemDict setValue:@"Zugang & Wege" forKey:@"title"];
        [newItemDict setObject:@[service] forKey:@"services"];
        [newItemDict setObject:@"zugang" forKey:@"type"];
        [newItemDict setObject:@(3) forKey:@"position"];
        MBMenuItem *infoItem = [[MBMenuItem alloc] initWithDictionary:newItemDict error:nil];
        [infoServices addObject:infoItem];
    }
    
    if(self.station.parkingInfoItems.count > 0){
        NSMutableDictionary *newItemDict = [NSMutableDictionary new];
        [newItemDict setValue:@"Parkplätze" forKey:@"title"];
        [newItemDict setObject:@"parkplaetze" forKey:@"type"];
        [newItemDict setObject:@(4) forKey:@"position"];
        MBMenuItem *infoItem = [[MBMenuItem alloc] initWithDictionary:newItemDict error:nil];
        [infoServices addObject:infoItem];
    }
    
    if(self.station.facilityStatusPOIs.count > 0){
        MBMenuItem *aufzuegeItem = [[MBMenuItem alloc] initWithDictionary:@{@"type": @"aufzuegeundfahrtreppen",
                                                                            @"title": @"Aufzüge",
                                                                            @"services": @[],
                                                                            @"position": @"8"} error:nil];
        [infoServices addObject:aufzuegeItem];
    }
    
    if(filteredInfoServices.count > 0){
        NSMutableDictionary *newItemDict = [NSMutableDictionary new];
        [newItemDict setValue:@"Info & Services vor Ort" forKey:@"title"];
        NSMutableArray *newServices = [NSMutableArray new];
        if(filteredInfoServices.count > 0){
            [newServices addObjectsFromArray:filteredInfoServices];
        }
        [newItemDict setObject:newServices forKey:@"services"];
        [newItemDict setObject:@"infoservices" forKey:@"type"];
        [newItemDict setObject:@(0) forKey:@"position"];
        MBMenuItem *infoItem = [[MBMenuItem alloc] initWithDictionary:newItemDict error:nil];
        [infoServices addObject:infoItem];
    }
    
    if(rufnummernServices.count > 0){
        NSMutableDictionary* newItemDict = [NSMutableDictionary new];
        [newItemDict setObject:@"Rufnummern & Services" forKey:@"title"];
        [newItemDict setObject:@"rufnummern" forKey:@"type"];
        
        [newItemDict setObject:rufnummernServices forKey:@"services"];
        [newItemDict setObject:@(1) forKey:@"position"];
        MBMenuItem *rufnummernItem = [[MBMenuItem alloc] initWithDictionary:newItemDict error:nil];
        [infoServices addObject:rufnummernItem];
    }

    return [infoServices sortedArrayUsingComparator:^NSComparisonResult(MBMenuItem *obj1, MBMenuItem *obj2) {
        NSComparisonResult result = NSOrderedSame;
        if (obj1.position > obj2.position) {
            result = NSOrderedDescending;
        } else {
            result = NSOrderedAscending;
        }
        return result;
    }];
}

#pragma mark MBMapViewControllerDelegate

-(NSArray<NSString *> *)mapFilterPresets{
    switch(_serviceType){
        case MBServiceCollectionTypeInfo:
            return @[ PRESET_STATION_INFO ];
        case MBServiceCollectionTypeShopping:
            return @[ PRESET_SHOPPING ];
        case MBServiceCollectionTypeFeedback:
            return nil;
    }
}


#pragma mark UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat itemWidth = floor((collectionView.frame.size.width - collectionView.contentInset.left - collectionView.contentInset.right - 8.0) / 2.0);
    CGFloat itemHeight = floor(itemWidth * 1.14);
    CGSize itemSize = CGSizeMake(itemWidth, itemHeight);
    
    id service = [self serviceForIndexPath:indexPath];
    if([service isKindOfClass:MBAdContainer.class]){
        if(((MBAdContainer*)service).isSquare){
            return itemSize;
        }
        return CGSizeMake(floor(collectionView.frame.size.width - collectionView.contentInset.left - collectionView.contentInset.right), 126);
    }
    return itemSize;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeZero;
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(NSArray*)usedServicesList{
    switch(_serviceType){
        case MBServiceCollectionTypeInfo:
            return self.services;
        case MBServiceCollectionTypeShopping:
            //could be einkaufsbahnhof or pxr
            if(self.pxrCategories.count > 0){
                //pxr is prefered
                return self.pxrCategories;
            } else {
                return self.services;
            }
        case MBServiceCollectionTypeFeedback:
            return self.services;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self usedServicesList].count;
}
-(id)serviceForIndexPath:(NSIndexPath*)indexPath{
    return [self usedServicesList][indexPath.item];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MBServiceCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kServiceCollectionViewCellReuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    MBStationKachel *kachel = [MBStationKachel new];
    kachel.needsLineAboveText = YES;

    id service = [self serviceForIndexPath:indexPath];
    if([service isKindOfClass:[MBEinkaufsbahnhofCategory class]]) {
        kachel.title = [(MBEinkaufsbahnhofCategory *)service name];
        cell.icon = [(MBEinkaufsbahnhofCategory *)service icon];
    } else if([service isKindOfClass:[MBMenuItem class]]) {
        kachel.title = [(MBMenuItem *)service title];
        cell.icon = [(MBMenuItem *)service iconForType];
    } else if([service isKindOfClass:[MBPXRShopCategory class]]){
        kachel.title = [(MBPXRShopCategory *)service title];
        cell.icon = [MBEinkaufsbahnhofCategory menuIconForCategoryTitle:kachel.title];
    } else if([service isKindOfClass:MBAdContainer.class]){
        MBAdContainer* adContainer = (MBAdContainer*)service;
        kachel.title = @"";
        kachel.titleForVoiceOver = adContainer.voiceOverText;
        kachel.needsLineAboveText = NO;
        kachel.showOnlyImage = YES;
        if(adContainer.type == MBAdContainerTypeEinkaufsbahnhof){
            if(adContainer.isSquare){
                if(self.collectionView.frame.size.width > 400){
                    adContainer.imageName = @"einkaufsbahnhof_banner_size_square_large";
                } else {
                    adContainer.imageName = @"einkaufsbahnhof_banner_size_square";
                }
            } else {
                adContainer.imageName = @"einkaufsbahnhof_banner_size_oblong";
            }
        } else {
            //don't change imageName, is preconfigured
        }
        cell.icon = [UIImage db_imageNamed:adContainer.imageName];
    } else if([service isKindOfClass:MBCouponCategory.class]){
        MBCouponCategory* couponCat = (MBCouponCategory*)service;
        kachel.title = couponCat.title;
        cell.icon = [MBCouponCategory image];
    }
    cell.kachel = kachel;
    
    return cell;
}


#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    id service = [self serviceForIndexPath:indexPath];
    UIViewController *vc = nil;
    // Tell this VC to keep the back button because the user proceeds on this VC
    self.preserveBackButton = YES;
    
    if([service isKindOfClass:MBMenuItem.class]){
        MBMenuItem* menuItem = (MBMenuItem*)service;
        NSArray* services = menuItem.services;
        
        if ([menuItem.type isEqualToString:@"aufzuegeundfahrtreppen"]) {
            MBFacilityStatusViewController *facilityVC = [[MBFacilityStatusViewController alloc] init];
            facilityVC.title = menuItem.title;
            facilityVC.station = self.station;
            vc = facilityVC;
        } else if ([menuItem.type isEqualToString:@"parkplaetze"]) {
            vc = [MBParkingTableViewController new];
            [(MBParkingTableViewController *)vc setParkingList:self.station.parkingInfoItems];
        } else {
            if (services.count > 1) {
                MBServiceListTableViewController* vclist = [[MBServiceListTableViewController alloc] initWithItem:menuItem];
                vclist.searchResult = self.searchResult;
                vc = vclist;
            } else {
                id service = services.firstObject;
                if([service isKindOfClass:MBService.class]){
                    vc = [[MBDetailViewController alloc] initWithStation:self.station];
                    [(MBDetailViewController *)vc setItem:service];
                }
            }
        }
    } else if([service isKindOfClass:[MBEinkaufsbahnhofCategory class]]){
        MBEinkaufsbahnhofCategory* category = (MBEinkaufsbahnhofCategory*)service;
        vc = [[MBServiceListTableViewController alloc] initWithItem:category];
    } else if([service isKindOfClass:[MBPXRShopCategory class]]){
        vc = [[MBServiceListTableViewController alloc] initWithItem:service];
    } else if([service isKindOfClass:MBAdContainer.class]){
        MBAdContainer* adContainer = (MBAdContainer*)service;
        if(adContainer.trackingAction){
            [MBTrackingManager trackActionsWithStationInfo:adContainer.trackingAction];
        }
        if(adContainer.type == MBAdContainerTypePickPack){
            MBService* service = [MBStaticStationInfo serviceForType:@"pickpack" withStation:_station];
            UIViewController* vc = [[MBDetailViewController alloc] initWithStation:self.station];
            [(MBDetailViewController *)vc setItem:service];
            [self.navigationController pushViewController:vc animated:YES];
        } else {
            [[AppDelegate appDelegate] openURL:adContainer.url];
        }
        return;
    } else if([service isKindOfClass:MBCouponCategory.class]){
        MBCouponCategory* couponCat = (MBCouponCategory*)service;
        vc = [[MBServiceListTableViewController alloc] initWithItem:couponCat];
    }
    if(vc){
        
        //get the title for tracking
        NSString* title = nil;
        if([service isKindOfClass:[MBEinkaufsbahnhofCategory class]]){
            title = [(MBEinkaufsbahnhofCategory*)service name];
        } else if([service isKindOfClass:[MBPXRShopCategory class]]){
            title = [(MBPXRShopCategory *)service title];
        } else if([service isKindOfClass:[MBMenuItem class]]) {
            MBMenuItem* menuItem = (MBMenuItem*)service;
            //NSLog(@"tap MBMenuItem %@",service);
            if([menuItem.type isEqualToString:@"aufzuegeundfahrtreppen"]){
                title = @"aufzuege";
            } else if([menuItem.type isEqualToString:@"rufnummern"]){
                title = @"service_und_rufnummern";
            } else if([menuItem.type isEqualToString:@"parkplaetze"]){
                title = @"parkplaetze";
            } else if([menuItem.type isEqualToString:@"infoservices"]){
                title = @"infos_und_services";
            } else if([menuItem.type isEqualToString:@"zugang"]){
                title = @"zugang_wege";
            } else if([menuItem.type isEqualToString:@"wlan"]){
                title = @"wlan";
            } else if([menuItem.type isEqualToString:@"bewertung"]){
                title = nil;
                [MBTrackingManager trackStatesWithStationInfo:@[@"d2", @"feedback", @"bewerten"]];
            } else if([menuItem.type isEqualToString:@"problemmelden"]){
                title = nil;
                [MBTrackingManager trackStatesWithStationInfo:@[@"d2", @"feedback", @"kontakt"]];
            } else if([menuItem.type hasPrefix:@"verschmutzung"]){
                title = nil;
                [MBTrackingManager trackStatesWithStationInfo:@[@"d2", @"feedback", @"verschmutzung"]];
            } else {
                NSLog(@"no tracking key defined for %@",service);
            }
        } else if([service isKindOfClass:MBCouponCategory.class]) {
            title = [(MBCouponCategory *)service title];
        }
        title = [title lowercaseString];
        title = [title stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        title = [title stringByReplacingOccurrencesOfString:@"ä" withString:@"ae"];
        title = [title stringByReplacingOccurrencesOfString:@"&" withString:@"und"];
        if(title.length > 0){
            switch(_serviceType){
                case MBServiceCollectionTypeInfo:
                    [MBTrackingManager trackActionsWithStationInfo:@[@"h3", @"info", @"tap", title]];
                    break;
                case MBServiceCollectionTypeShopping:
                    [MBTrackingManager trackActionsWithStationInfo:@[@"h3", @"shops", @"tap", title]];
                    break;
                case MBServiceCollectionTypeFeedback:
                    break;
            }
            
            if([vc isKindOfClass:MBServiceListTableViewController.class]){
                MBServiceListTableViewController* sl = (MBServiceListTableViewController*)vc;
                sl.trackingTitle = title;
            } else if([vc isKindOfClass:MBUITrackableViewController.class]){
                MBUITrackableViewController* tv = (MBUITrackableViewController*)vc;
                tv.trackingTitle = title;
            }
        }
        BOOL animated = YES;
        if(self.searchResult){
            animated = NO;
        }
        [self.navigationController pushViewController:vc animated:animated];
    }
}

@end
