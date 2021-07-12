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
                MBServiceListTableViewController* vc = [[MBServiceListTableViewController alloc] initWithItem:cat station:self.station];
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
                MBService* service = [self findServiceWithType:@"barrierefreiheit"];
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
        
    }
    
    if (self.tabBarViewController) {
        [MBUIViewController addBackButtonToViewController:self andActionBlockOrNil:^{
            [self.tabBarViewController selectViewControllerAtIndex:1];
        }];
    }
    
    if(self.openChatBotScreen || self.openServiceNumberScreen){
        BOOL isChat = self.openChatBotScreen;
        NSString* serviceName = @"chatbot";
        if(!isChat){
            //pickpack
            serviceName = @"pickpack";
        }
        BOOL displayAsSingleScreen = NO;
        if(displayAsSingleScreen){
            MBService* service = [MBStaticStationInfo serviceForType:serviceName withStation:_station];
            UIViewController* vc = [[MBDetailViewController alloc] initWithStation:self.station];
            [(MBDetailViewController *)vc setItem:service];
            [self.navigationController pushViewController:vc animated:NO];
        } else {
            //we simulate a search to reuse the exiting code for displaying a service item
            if(self.openChatBotScreen){
                self.searchResult = [MBContentSearchResult searchResultForChatbot];
            } else if(self.openPickPackScreen){
                self.searchResult = [MBContentSearchResult searchResultForPickpack];
            } else if(self.openServiceNumberScreen) {
                self.searchResult = [MBContentSearchResult searchResultForServiceNumbers];
            }
        }
        self.openServiceNumberScreen = NO;
        self.openChatBotScreen = NO;
        self.openPickPackScreen = NO;
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
    
    if(_station.hasChatbot){
        MBService* service = [MBStaticStationInfo serviceForType:@"chatbot" withStation:_station];
        [rufnummernServices addObject:service];
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
    
    if(self.station.hasDirtService){
        AppDelegate* app = (AppDelegate*) [UIApplication sharedApplication].delegate;
        BOOL hasWhatsApp = [app canOpenURL:[NSURL URLWithString:@"whatsapp://send?text=Hallo"]];
        MBService* service = [MBStaticStationInfo serviceForType:hasWhatsApp ? @"verschmutzung_mitwhatsapp" : @"verschmutzung_ohnewhatsapp" withStation:_station];
        [rufnummernServices addObject:service];
    }
    if(true){
        MBService* service = [MBStaticStationInfo serviceForType:@"problemmelden" withStation:_station];
        [rufnummernServices addObject:service];
    }
    if(true){
        MBService* service = [MBStaticStationInfo serviceForType:@"bewertung" withStation:_station];
        [rufnummernServices addObject:service];
    }

    
    if(details.hasWiFi){
        MBService* wlanService = [MBStaticStationInfo serviceForType:@"wlan" withStation:_station];
        MBMenuItem *wlanItem = [[MBMenuItem alloc] initWithDictionary:@{ @"position":@(2),
                                                                         @"services":@[wlanService],
                                                                         @"title":@"WLAN",
                                                                         @"type":@"wlan",
                                                                         } error:nil];
        [infoServices addObject:wlanItem];
    }
    
    if(true){
        MBService* service = [MBStaticStationInfo serviceForType:@"barrierefreiheit" withStation:_station];
        NSMutableDictionary *newItemDict = [NSMutableDictionary new];
        [newItemDict setValue:@"Barrierefreiheit" forKey:@"title"];
        [newItemDict setObject:@[service] forKey:@"services"];
        [newItemDict setObject:@"barrierefreiheit" forKey:@"type"];
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
                MBServiceListTableViewController* vclist = [[MBServiceListTableViewController alloc] initWithItem:menuItem station:self.station];
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
        vc = [[MBServiceListTableViewController alloc] initWithItem:category station:self.station];
    } else if([service isKindOfClass:[MBPXRShopCategory class]]){
        vc = [[MBServiceListTableViewController alloc] initWithItem:service station:self.station];
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
        vc = [[MBServiceListTableViewController alloc] initWithItem:couponCat station:self.station];
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
            } else if([menuItem.type isEqualToString:@"barrierefreiheit"]){
                title = @"barrierefreiheit";
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
