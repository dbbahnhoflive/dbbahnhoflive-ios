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
#import "MBContentSearchResult.h"
#import "MBUrlOpening.h"
#import "MBUIHelper.h"
#import "MBTrackingManager.h"

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
            
            if(self.searchResult.poiCat
               || self.searchResult.couponItem){
                id cat = (self.searchResult.poiCat ? self.searchResult.poiCat : nil);
                if(self.searchResult.couponItem){
                    MBCouponCategory* cCat = [MBCouponCategory new];
                    cCat.items = self.station.couponsList;
                    cat = cCat;
                }
                MBServiceListTableViewController* vc = [[MBServiceListTableViewController alloc] initWithItem:cat station:self.station];
                vc.searchResult = self.searchResult;
                [self.navigationController pushViewController:vc animated:NO];
            }
        } else if(self.searchResult.isStationInfoSearch){
            if(self.searchResult.isStationInfoLocalServicesSearch){
                if(self.searchResult.isLocalServiceDBInfo){
                    self.searchResult.service = [self findServiceWithType:kServiceType_DBInfo];
                } else if(self.searchResult.isLocalServiceMobileService){
                    self.searchResult.service = [self findServiceWithType:kServiceType_MobilerService];
                } else if(self.searchResult.isLocalMission){
                    self.searchResult.service = [self findServiceWithType:kServiceType_Bahnhofsmission];
                } else if(self.searchResult.isLocalTravelCenter){
                    self.searchResult.service = [self findServiceWithType:kServiceType_LocalTravelCenter];
                } else if(self.searchResult.isLocalLounge){
                    self.searchResult.service = [self findServiceWithType:kServiceType_LocalDBLounge];
                }
                [self collectionView:self.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            } else if(self.searchResult.isStationInfoPhoneSearch){
                if(self.searchResult.isStationInfoPhoneMobility){
                    self.searchResult.service = [self findServiceWithType:kServiceType_MobilityService];
                } else if(self.searchResult.isStationInfoPhone3S){
                    self.searchResult.service = [self findServiceWithType:kServiceType_3SZentrale];
                } if(self.searchResult.isStationInfoPhoneLostservice){
                    self.searchResult.service = [self findServiceWithType:kServiceType_LocalLostFound];
                } if(self.searchResult.isChatBotSearch){
                    self.searchResult.service = [self findServiceWithType:kServiceType_Chatbot];
                }
                //find the index of the "rufnummern & services" tile
                NSIndexPath* servicePath = [self indexPathForServiceCategoryType:@"rufnummern"];
                if(servicePath){
                    [self collectionView:self.collectionView didSelectItemAtIndexPath:servicePath];
                }
            } else if(self.searchResult.isParkingSearch){
                MBParkingTableViewController* vc = [[MBParkingTableViewController alloc] initWithStation:self.station];
                [self.navigationController pushViewController:vc animated:NO];
            } else if(self.searchResult.isSteplessAccessSearch){
                MBService* service = [self findServiceWithType:kServiceType_Barrierefreiheit];
                service.serviceConfiguration = self.searchResult.metaData;
                [self pushService:service];
            } else if(self.searchResult.isWifiSearch){
                [self pushServiceViewForType:kServiceType_WLAN];
            } else if(self.searchResult.isElevatorSearch){
                MBFacilityStatusViewController *facilityVC = [[MBFacilityStatusViewController alloc] init];
                facilityVC.station = self.station;
                [self.navigationController pushViewController:facilityVC animated:NO];
            } else if(self.searchResult.isSEVSearch || self.searchResult.isSEVAccompanimentSearch){
                //[self pushServiceViewForType:kServiceType_SEV];
                NSIndexPath* servicePath = [self indexPathForServiceCategoryType:kServiceType_SEV];
                if(self.searchResult.isSEVSearch){
                    self.searchResult.service = [self findServiceWithType:kServiceType_SEV];
                } else {
                    self.searchResult.service = [self findServiceWithType:kServiceType_SEV_AccompanimentService];
                }
                if(servicePath){
                    [self collectionView:self.collectionView didSelectItemAtIndexPath:servicePath];
                }
            } else if(self.searchResult.isLockerSearch){
                [self pushServiceViewForType:kServiceType_Locker];
            }
        }
        self.searchResult = nil;
    }
}

-(void)pushServiceViewForType:(NSString*)serviceType{
    MBService* service = [self findServiceWithType:serviceType];
    [self pushService:service];
}
-(void)pushService:(MBService*)service{
    MBDetailViewController* vc = [[MBDetailViewController alloc] initWithStation:self.station service:service];
    [self.navigationController pushViewController:vc animated:NO];
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
    if(_serviceType == MBServiceCollectionTypeInfo){
        self.services = [self prepareServices];
    } else if (_serviceType == MBServiceCollectionTypeShopping){
        NSArray* source = self.pxrCategories;
        if(!source){
            //special case: we have a station without shops
            source = @[];
        }
        NSMutableArray* sourceMutable = [source mutableCopy];

        if (self.station.couponsList.count > 0) {
            //add coupon kachel
            MBCouponCategory* couponContainer = [MBCouponCategory new];
            couponContainer.items = self.station.couponsList;
            [sourceMutable addObject:couponContainer];
        }

        //do we need a larger last kachel?
        MBAdContainer* lastOne = sourceMutable.lastObject;
        if([lastOne isKindOfClass:MBAdContainer.class] && (sourceMutable.count % 2) != 0){
            lastOne.isSquare = NO;
        }
        
        self.pxrCategories = sourceMutable;
    }
    
    [self.collectionView reloadData];

    self.isPrepared = YES;
}

-(void)reloadData{
    self.isPrepared = false;
    [self prepareForDisplay];
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
        
    }
    
    if (self.tabBarViewController) {
        __weak MBServiceListCollectionViewController* vcWeak = self;
        [MBUIViewController addBackButtonToViewController:self andActionBlockOrNil:^{
            [vcWeak.tabBarViewController selectViewControllerAtIndex:1];
        }];
    }
    
    if(self.openChatBotScreen || self.openServiceNumberScreen || self.openWegbegleitungScreen){
        NSString* serviceName = kServiceType_Chatbot;
        if(self.openWegbegleitungScreen){
            serviceName = kServiceType_SEV_AccompanimentService;
        }
        
        BOOL displayAsSingleScreen = NO;
        if(displayAsSingleScreen){
            MBService* service = [MBStaticStationInfo serviceForType:serviceName withStation:_station];
            UIViewController* vc = [[MBDetailViewController alloc] initWithStation:self.station service:service];
            [self.navigationController pushViewController:vc animated:NO];
        } else {
            //we simulate a search to reuse the exiting code for displaying a service item
            if(self.openChatBotScreen){
                self.searchResult = [MBContentSearchResult searchResultForChatbot];
            } else if(self.openServiceNumberScreen) {
                self.searchResult = [MBContentSearchResult searchResultForServiceNumbers];
            } else if(self.openWegbegleitungScreen){
                MBContentSearchResult* res = [MBContentSearchResult searchResultWithKeywords:CONTENT_SEARCH_KEY_STATIONINFO_SEV_ACCOMPANIMENT];
                self.searchResult = res;
            }
        }
        self.openServiceNumberScreen = NO;
        self.openChatBotScreen = NO;
        self.openWegbegleitungScreen = NO;
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

- (NSArray *)prepareServices {
    NSLog(@"prepareServices");
    NSMutableArray *infoServices = [NSMutableArray new];
    // fill in services according to plan set out here

    NSMutableArray* filteredInfoServices = [NSMutableArray arrayWithCapacity:3];
    
    NSMutableArray *rufnummernServices = [NSMutableArray arrayWithCapacity:3];
    
    MBStationDetails* details = _station.stationDetails;
    
    if(details.hasDBInfo){
        MBService* service = [MBStaticStationInfo serviceForType:kServiceType_DBInfo withStation:_station];
        [filteredInfoServices addObject:service];
    }
    
    if(details.hasLocalServiceStaff){
        MBService* service = [MBStaticStationInfo serviceForType:kServiceType_MobilerService withStation:_station];
        [filteredInfoServices addObject:service];
    }
    
    if(details.hasRailwayMission){
        [filteredInfoServices addObject:[MBStaticStationInfo serviceForType:kServiceType_Bahnhofsmission withStation:_station]];
    }
    
    if(details.hasTravelCenter || _station.travelCenter != nil){
        MBService* service = [MBStaticStationInfo serviceForType:kServiceType_LocalTravelCenter withStation:_station];
        [filteredInfoServices addObject:service];
    }
    if(details.hasDBLounge){
        MBService* service = [MBStaticStationInfo serviceForType:kServiceType_LocalDBLounge withStation:_station];
        [filteredInfoServices addObject:service];
    }
    
    if(_station.hasChatbot){
        MBService* service = [MBStaticStationInfo serviceForType:kServiceType_Chatbot withStation:_station];
        [rufnummernServices addObject:service];
    }

    if(details.hasMobilityService){
        MBService* service = [MBStaticStationInfo serviceForType:kServiceType_MobilityService withStation:_station];
        [rufnummernServices addObject:service];
    }
    
    if(details.has3SZentrale){
        MBService* service = [MBStaticStationInfo serviceForType:kServiceType_3SZentrale withStation:_station];
        [rufnummernServices addObject:service];
    }
    
    if(details.hasLostAndFound){
        MBService* service = [MBStaticStationInfo serviceForType:kServiceType_LocalLostFound withStation:_station];
        [rufnummernServices addObject:service];
    }
    
    if(self.station.hasDirtService){
        BOOL hasWhatsApp = [MBUrlOpening canOpenURL:[NSURL URLWithString:@"whatsapp://send?text=Hallo"]];
        MBService* service = [MBStaticStationInfo serviceForType:hasWhatsApp ? kServiveType_Dirt_Whatsapp : kServiceType_Dirt_NoWhatsapp withStation:_station];
        [rufnummernServices addObject:service];
    }
    if(true){
        MBService* service = [MBStaticStationInfo serviceForType:kServiceType_Problems withStation:_station];
        [rufnummernServices addObject:service];
    }
    if(true){
        MBService* service = [MBStaticStationInfo serviceForType:kServiceType_Rating withStation:_station];
        [rufnummernServices addObject:service];
    }

    
    if(details.hasWiFi){
        MBService* wlanService = [MBStaticStationInfo serviceForType:kServiceType_WLAN withStation:_station];
        MBMenuItem *wlanItem = [[MBMenuItem alloc] initWithDictionary:@{ @"position":@(2),
                                                                         @"services":@[wlanService],
                                                                         @"title":@"WLAN",
                                                                         @"type":kServiceType_WLAN,
                                                                         } error:nil];
        [infoServices addObject:wlanItem];
    }
    
    if(true){
        MBService* service = [MBStaticStationInfo serviceForType:kServiceType_Barrierefreiheit withStation:_station];
        NSMutableDictionary *newItemDict = [NSMutableDictionary new];
        [newItemDict setValue:@"Barrierefreiheit" forKey:@"title"];
        [newItemDict setObject:@[service] forKey:@"services"];
        [newItemDict setObject:kServiceType_Barrierefreiheit forKey:@"type"];
        [newItemDict setObject:@(3) forKey:@"position"];
        MBMenuItem *infoItem = [[MBMenuItem alloc] initWithDictionary:newItemDict error:nil];
        [infoServices addObject:infoItem];
    }
    
    if(self.station.parkingInfoItems.count > 0){
        NSMutableDictionary *newItemDict = [NSMutableDictionary new];
        [newItemDict setValue:@"Parkplätze" forKey:@"title"];
        [newItemDict setObject:kServiceType_Parking forKey:@"type"];
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

    if(self.station.hasSEVStations || self.station.hasAccompanimentService){
        MBMenuItem* sevItem = [MBServiceListCollectionViewController createMenuItemErsatzverkehrWithStation:self.station];
        [infoServices addObject:sevItem];
    }
    if(self.station.lockerList.count > 0){
        MBService* lockerService = [MBStaticStationInfo serviceForType:kServiceType_Locker withStation:_station];
        MBMenuItem *lockerItem = [[MBMenuItem alloc] initWithDictionary:@{@"type": kServiceType_Locker,
                                                                            @"title": @"Schließfächer",
                                                                            @"services": @[lockerService],
                                                                            @"position": @"10"} error:nil];
        [infoServices addObject:lockerItem];
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

+(MBMenuItem*)createMenuItemErsatzverkehrWithStation:(MBStation*)station{
    if(station.hasSEVStations && station.hasAccompanimentService){
        MBService* sevService = [MBStaticStationInfo serviceForType:kServiceType_SEV withStation:station];
        sevService.title = @"Haltestelleninformation";
        MBService* accService = [MBStaticStationInfo serviceForType:kServiceType_SEV_AccompanimentService withStation:station];
        accService.title = @"DB Wegbegleitung";
        MBMenuItem *sevItem = [[MBMenuItem alloc] initWithDictionary:@{@"type": kServiceType_SEV,
                                                                            @"title": @"Ersatzverkehr",
                                                                            @"services": @[sevService,accService],
                                                                            @"position": @"9"} error:nil];
        return sevItem;
    } else {
        //single service
        NSString* type = kServiceType_SEV;
        if(station.hasAccompanimentService){
        //    type = kServiceType_SEV_AccompanimentService;
        }
        MBService* sevService = [MBStaticStationInfo serviceForType:type withStation:station];
        MBMenuItem *sevItem = [[MBMenuItem alloc] initWithDictionary:@{@"type": type,
                                                                            @"title": @"Ersatzverkehr",
                                                                            @"services": @[sevService],
                                                                            @"position": @"9"} error:nil];
        return sevItem;
    }
}

#pragma mark MBMapViewControllerDelegate

-(NSArray<NSString *> *)mapFilterPresets{
    switch(_serviceType){
        case MBServiceCollectionTypeInfo:
            return @[ PRESET_STATION_INFO ];
        case MBServiceCollectionTypeShopping:
            return @[ PRESET_SHOPPING ];
        
    }
}


#pragma mark UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat itemWidth = floor((collectionView.frame.size.width - collectionView.contentInset.left - collectionView.contentInset.right - 8.0) / (ISIPAD ? 3.0 : 2.0));
    if(ISIPAD){
        itemWidth -= 8;
    }
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
            if(self.pxrCategories.count > 0){
                //pxr is prefered
                return self.pxrCategories;
            } else {
                return self.services;
            }
        
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
    if([service isKindOfClass:[MBMenuItem class]]) {
        kachel.title = [(MBMenuItem *)service title];
        cell.icon = [(MBMenuItem *)service iconForType];
    } else if([service isKindOfClass:[MBPXRShopCategory class]]){
        kachel.title = [(MBPXRShopCategory *)service title];
        cell.icon = [MBPXRShopCategory menuIconForCategoryTitle:kachel.title];
    } else if([service isKindOfClass:MBAdContainer.class]){
        MBAdContainer* adContainer = (MBAdContainer*)service;
        kachel.title = @"";
        kachel.titleForVoiceOver = adContainer.voiceOverText;
        kachel.needsLineAboveText = NO;
        kachel.showOnlyImage = YES;
        
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
    
    NSString* trackingTitle = nil;
    
    if([service isKindOfClass:MBMenuItem.class]){
        MBMenuItem* menuItem = (MBMenuItem*)service;
        NSArray* services = menuItem.services;
        
        if ([menuItem.type isEqualToString:@"aufzuegeundfahrtreppen"]) {
            MBFacilityStatusViewController *facilityVC = [[MBFacilityStatusViewController alloc] init];
            facilityVC.title = menuItem.title;
            facilityVC.station = self.station;
            vc = facilityVC;
            trackingTitle = facilityVC.trackingTitle;
        } else if ([menuItem.type isEqualToString:kServiceType_Parking]) {
            MBParkingTableViewController* pc = [[MBParkingTableViewController alloc] initWithStation:self.station];
            vc = pc;
            trackingTitle = pc.trackingTitle;
        } else {
            if (services.count > 1) {
                MBServiceListTableViewController* vclist = [[MBServiceListTableViewController alloc] initWithItem:menuItem station:self.station];
                vclist.searchResult = self.searchResult;
                vc = vclist;
                trackingTitle = vclist.trackingTitle;
            } else {
                MBService* service = services.firstObject;
                if([service isKindOfClass:MBService.class]){
                    MBDetailViewController*dv = [[MBDetailViewController alloc] initWithStation:self.station service:service];
                    trackingTitle = dv.trackingTitle;
                    vc = dv;
                }
            }
        }
    } else if([service isKindOfClass:[MBPXRShopCategory class]]){
        MBServiceListTableViewController* serviceList = [[MBServiceListTableViewController alloc] initWithItem:service station:self.station];
        trackingTitle = serviceList.trackingTitle;
        vc = serviceList;
    } else if([service isKindOfClass:MBAdContainer.class]){
        MBAdContainer* adContainer = (MBAdContainer*)service;
        if(adContainer.trackingAction){
            [MBTrackingManager trackActionsWithStationInfo:adContainer.trackingAction];
        }
        [MBUrlOpening openURL:adContainer.url];
        return;
    } else if([service isKindOfClass:MBCouponCategory.class]){
        MBCouponCategory* couponCat = (MBCouponCategory*)service;
        MBServiceListTableViewController* serviceList = [[MBServiceListTableViewController alloc] initWithItem:couponCat station:self.station];
        trackingTitle = serviceList.trackingTitle;
        vc = serviceList;
    }
    if(vc){
        if(trackingTitle.length > 0){
            switch(_serviceType){
                case MBServiceCollectionTypeInfo:
                    [MBTrackingManager trackActionsWithStationInfo:@[@"h3", @"info", @"tap", trackingTitle]];
                    break;
                case MBServiceCollectionTypeShopping:
                    [MBTrackingManager trackActionsWithStationInfo:@[@"h3", @"shops", @"tap", trackingTitle]];
                    break;
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
