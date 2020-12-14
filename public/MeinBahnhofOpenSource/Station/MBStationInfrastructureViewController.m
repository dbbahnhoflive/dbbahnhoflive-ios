// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBStationInfrastructureViewController.h"
#import "MBService.h"
#import "MBButtonWithAction.h"
#import "MBDetailViewController.h"
#import "MBStationNavigationViewController.h"
#import "MBRootContainerViewController.h"
#import "MBStationViewController.h"
#import "FacilityStatus.h"
#import "MBPTSStationResponse.h"

#import "MBStaticStationInfo.h"
#import "RIMapPoi.h"
#import "RIMapConfigItem.h"
#import "MBParkingTableViewController.h"

@interface MBStationInfrastructureViewController ()<MBMapViewControllerDelegate>

@property(nonatomic,strong) UIScrollView* contentScrollView;
@property(nonatomic,strong) NSArray<NSString*>* order;

@property(nonatomic,strong) NSArray<NSString*>* keysDisplayedOnlyWhenAvailableForSomeCat;

@property(nonatomic,strong) NSDictionary* entries;
@property(nonatomic,strong) NSDictionary* iconForEntries;

@property(nonatomic,strong) NSArray<NSString *> * activeMapFilter;
@property(nonatomic,strong) id mapPoi;
@end

@implementation MBStationInfrastructureViewController

#define MIN_CATEGORY_FOR_FEATURES_THAT_MUST_BE_AVAILABLE 4

#define KEY_STUFENFREI @"Stufenfreier Zugang"
#define KEY_WC @"WC"
#define KEY_WLAN @"WLAN"
#define KEY_AUFZUG @"Aufzüge"
#define KEY_SCHLIESSFACH @"Schließfächer"
#define KEY_DBINFO @"DB Info"
#define KEY_REISEZENTRUM @"DB Reisezentrum"
#define KEY_LOUNGE @"DB Lounge"
#define KEY_REISEBEDARF @"Reisebedarf"
#define KEY_PARK @"Parkplätze"
#define KEY_FAHRRADSTELLPLATZ @"Fahrradstellplatz"
#define KEY_TAXI @"Taxistand"
#define KEY_MIETWAGEN @"Mietwagen"
#define KEY_FUNDSERVICE @"Fundservice"

-(instancetype)init{
    self = [super init];
    if(self){
        self.order = @[KEY_STUFENFREI, KEY_WC, KEY_WLAN, KEY_AUFZUG, KEY_SCHLIESSFACH, KEY_DBINFO, KEY_REISEZENTRUM, KEY_LOUNGE, KEY_REISEBEDARF, KEY_PARK,  KEY_FAHRRADSTELLPLATZ, KEY_TAXI, KEY_MIETWAGEN, KEY_FUNDSERVICE ];
        self.keysDisplayedOnlyWhenAvailableForSomeCat = @[ KEY_WLAN, KEY_FUNDSERVICE, KEY_DBINFO, KEY_LOUNGE, KEY_PARK,  KEY_FAHRRADSTELLPLATZ, KEY_TAXI, KEY_MIETWAGEN, ];
        self.iconForEntries = @{
                                KEY_TAXI: @"bahnhofsausstattung_taxi",
                                KEY_MIETWAGEN: @"bahnhofsausstattung_mietwagen",
                                KEY_FAHRRADSTELLPLATZ: @"bahnhofsausstattung_fahrradstellplatz",
                                KEY_WC: @"bahnhofsausstattung_wc",
                                KEY_WLAN: @"rimap_wlan_grau",
                                KEY_DBINFO: @"bahnhofsausstattung_db_info",
                                KEY_REISEZENTRUM: @"bahnhofsausstattung_db_reisezentrum",
                                KEY_LOUNGE: @"bahnhofsausstattung_lounge",
                                KEY_SCHLIESSFACH: @"bahnhofsausstattung_schließfaecher",
                                KEY_REISEBEDARF: @"bahnhofsausstattung_reisebedarf",
                                KEY_PARK: @"bahnhofsausstattung_parkplatz",
                                KEY_AUFZUG: @"app_aufzug",
                                KEY_STUFENFREI: @"bahnhofsausstattung_stufenfreier_zugang",
                                KEY_FUNDSERVICE: @"bahnhofsausstattung_fundservice",
                                };
    }
    return self;
}

-(void)calculateStatus{
    NSMutableDictionary* ausstattungEntries = [NSMutableDictionary dictionaryWithCapacity:20];
    
    //NOTE values if this array must be used as a key in ausstattungEntries!
    
    MBPTSStationResponse* details = _station.stationDetails;
    
    if(details.hasSteplessAccess){
        [ausstattungEntries setObject:[MBStaticStationInfo serviceForType:@"stufenfreier_zugang" withStation:_station] forKey:KEY_STUFENFREI];
    }
    if(details.hasPublicFacilities){
        [ausstattungEntries setObject:[NSNumber numberWithBool:YES] forKey:KEY_WC];
    }
    if(details.hasWiFi){
        [ausstattungEntries setObject:[MBStaticStationInfo serviceForType:@"wlan" withStation:_station] forKey:KEY_WLAN];
    }
    if(details.hasLockerSystem){
        [ausstattungEntries setObject:[NSNumber numberWithBool:YES] forKey:KEY_SCHLIESSFACH];
    }
    if(details.hasLostAndFound){
        [ausstattungEntries setObject:[NSNumber numberWithBool:YES] forKey:KEY_FUNDSERVICE];
    }
    if(details.hasDBInfo){
        [ausstattungEntries setObject:[NSNumber numberWithBool:YES] forKey:KEY_DBINFO];
    }
    if(details.hasTravelCenter){
        [ausstattungEntries setObject:[NSNumber numberWithBool:YES] forKey:KEY_REISEZENTRUM];
    }
    if(details.hasDBLounge){
        [ausstattungEntries setObject:[NSNumber numberWithBool:YES] forKey:KEY_LOUNGE];
    }
    if(details.hasTravelNecessities){
        [ausstattungEntries setObject:[NSNumber numberWithBool:YES] forKey:KEY_REISEBEDARF];
    }
    
    if(details.hasParking){
        [ausstattungEntries setObject:[NSNumber numberWithBool:YES] forKey:KEY_PARK];
    }
    if(details.hasBicycleParking){
        [ausstattungEntries setObject:[NSNumber numberWithBool:YES] forKey:KEY_FAHRRADSTELLPLATZ];
    }
    if(details.hasTaxiRank){
        [ausstattungEntries setObject:[NSNumber numberWithBool:YES] forKey:KEY_TAXI];
    }
    if(details.hasCarRental){
        [ausstattungEntries setObject:[NSNumber numberWithBool:YES] forKey:KEY_MIETWAGEN];
    }
    
    if(_station.facilityStatusPOIs.count > 0){
        [ausstattungEntries setObject:_station.facilityStatusPOIs forKey:KEY_AUFZUG];
    }
    
    self.entries = ausstattungEntries;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.titleLabel.text = @"Bahnhofsausstattung";
    
    [self calculateStatus];
    
    self.contentScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.headerView.sizeHeight, self.contentView.sizeWidth, self.contentView.sizeHeight-self.headerView.sizeHeight)];
    
    int y = [self addStatusViewsForStateActive:YES y:0];//the active items are displayed first
    y = [self addStatusViewsForStateActive:NO y:y];
    
    self.contentScrollView.contentSize = CGSizeMake(self.contentScrollView.sizeWidth, y);
    [self.contentView addSubview:self.contentScrollView];
}

+(BOOL)displaySomeEntriesOnlyWhenAvailable:(MBStation*)station{
    NSNumber* category = station.category;
    NSLog(@"station cat %@",category);
    BOOL displaySomeEntriesOnlyWhenAvailable = category.integerValue >= MIN_CATEGORY_FOR_FEATURES_THAT_MUST_BE_AVAILABLE;
    return displaySomeEntriesOnlyWhenAvailable;
}

-(int)addStatusViewsForStateActive:(BOOL)active y:(int)y{
    BOOL displaySomeEntriesOnlyWhenAvailable = [MBStationInfrastructureViewController displaySomeEntriesOnlyWhenAvailable:_station];
    for(NSString* key in self.order){
        id typeEntry = [self.entries objectForKey:key];
        
        if (typeEntry != nil) {
            //vorhanden
            if(!active){
                continue;
            }
        } else {
            //nicht vorhanden
            if(active){
                continue;
            }
        }
        
        if(displaySomeEntriesOnlyWhenAvailable && !active && typeEntry == nil){
            if([self.keysDisplayedOnlyWhenAvailableForSomeCat containsObject:key]){
                continue;//skip some features that are not available
            }
        }
        
        if([key isEqualToString:KEY_AUFZUG] && !active && _station.facilityStatusPOIs.count == 0){
            continue;//don't show elevators "not available" when we have no elevator information
        }
        
        UIView* entryView = [[UIView alloc] initWithFrame:CGRectMake(0, y, self.contentView.sizeWidth, 72)];
        
        UIImageView* icon = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:self.iconForEntries[key]]];
        [icon setSize:CGSizeMake(40, 40)];
        [entryView addSubview:icon];
        [icon setGravityLeft:18];
        [icon centerViewVerticalInSuperView];
        
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(80, 16, self.contentView.sizeWidth-80-16, 20)];
        label.text = key;
        label.font = [UIFont db_RegularSixteen];
        label.textColor = [UIColor db_333333];
        [entryView addSubview:label];
        label.isAccessibilityElement = NO;
        
        UIImageView* statusIcon = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_check"]];
        [entryView addSubview:statusIcon];
        [statusIcon setBelow:label withPadding:0];
        [statusIcon setGravityLeft:label.originX];
        
        UILabel* statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(statusIcon.frame)+3, 40-3, self.contentView.sizeWidth, 20)];
        statusLabel.font = [UIFont db_RegularFourteen];
        [entryView addSubview:statusLabel];
        statusLabel.isAccessibilityElement = NO;
        
        BOOL isAvailable = typeEntry != nil;
        if(typeEntry != nil && [key isEqualToString:KEY_AUFZUG]){
            isAvailable = _station.facilityStatusPOIs.count > 0;
        }
        
        if (isAvailable) {
            statusLabel.text = @"vorhanden";
            statusLabel.textColor = [UIColor db_76c030];
            statusIcon.image = [UIImage db_imageNamed:@"app_check"];
        } else {
            statusLabel.text = @"nicht vorhanden";
            statusLabel.textColor = [UIColor db_mainColor];
            statusIcon.image = [UIImage db_imageNamed:@"app_kreuz"];
        }
        
        UIView* line = [[UIView alloc] initWithFrame:CGRectMake(16, entryView.sizeHeight-1, entryView.sizeWidth, 1)];
        line.backgroundColor = [UIColor db_light_lineColor];
        [entryView addSubview:line];
        
        if(isAvailable){
            id poi = nil;
            if([key isEqualToString:KEY_WLAN]){
                NSArray* mapFilter = @[PRESET_WIFI];
                if((poi = [self poiForFilter:mapFilter])){
                    [self addLinkButtonToEntryView:entryView withMapFilter:mapFilter poi:poi];
                } else {
                    [self addLinkButtonToEntryView:entryView withMBService:(MBService*)typeEntry];
                }
            } else if([key isEqualToString:KEY_STUFENFREI]){
                [self addLinkButtonToEntryView:entryView withMBService:(MBService*)typeEntry];
            } else if([key isEqualToString:KEY_WC]){
                NSArray* mapFilter = @[PRESET_TOILET];
                if((poi = [self poiForFilter:mapFilter])){
                    [self addLinkButtonToEntryView:entryView withMapFilter:mapFilter poi:poi];
                }
            } else if([key isEqualToString:KEY_AUFZUG]){
                if(_station.facilityStatusPOIs.count > 0){
                    //we know that elevators are always available on the map:
                    poi = _station.facilityStatusPOIs.firstObject;
                    [self addLinkButtonToEntryView:entryView withMapFilter:@[PRESET_ELEVATORS] poi:poi];
                }
            } else if([key isEqualToString:KEY_PARK]){
                if(self.station.parkingInfoItems.count > 0){
                    //we add these to the map, so we know they are available
                    NSArray* mapFilter = @[ PRESET_PARKING ];
                    id Ppoi = self.station.parkingInfoItems.firstObject;
                    [self addLinkButtonToEntryView:entryView withMapFilter:mapFilter poi:Ppoi];
                }
            } else if([key isEqualToString:KEY_FAHRRADSTELLPLATZ]){
                NSArray* mapFilter = @[ PRESET_BIKE_PARKING ];
                if((poi = [self poiForFilter:mapFilter])){
                    [self addLinkButtonToEntryView:entryView withMapFilter:mapFilter poi:poi];
                }
            } else if([key isEqualToString:KEY_TAXI]){
                NSArray* mapFilter = @[PRESET_TAXI];
                if((poi = [self poiForFilter:mapFilter])){
                    [self addLinkButtonToEntryView:entryView withMapFilter:mapFilter poi:poi];
                }
            } else if([key isEqualToString:KEY_MIETWAGEN]){
                NSArray* mapFilter = @[PRESET_CAR_RENTAL];
                if((poi = [self poiForFilter:mapFilter])){
                    [self addLinkButtonToEntryView:entryView withMapFilter:mapFilter poi:poi];
                }
            } else if([key isEqualToString:KEY_DBINFO]){
                NSArray* mapFilter = @[PRESET_DB_INFO];
                if((poi = [self poiForFilter:mapFilter])){
                    [self addLinkButtonToEntryView:entryView withMapFilter:mapFilter poi:poi];
                } else {
                    MBService* service = [MBStaticStationInfo serviceForType:@"db_information"  withStation:_station];
                    [self addLinkButtonToEntryView:entryView withMBService:service];
                }
            } else if([key isEqualToString:KEY_REISEZENTRUM]){
                NSArray* mapFilter = @[PRESET_TRIPCENTER];
                if((poi = [self poiForFilter:mapFilter])){
                    [self addLinkButtonToEntryView:entryView withMapFilter:mapFilter poi:poi];
                } else {
                    MBService* service = [MBStaticStationInfo serviceForType:@"local_travelcenter" withStation:_station];
                    [self addLinkButtonToEntryView:entryView withMBService:service];
                }
            } else if([key isEqualToString:KEY_LOUNGE]){
                NSArray* mapFilter = @[PRESET_DB_LOUNGE];
                if((poi = [self poiForFilter:mapFilter])){
                    [self addLinkButtonToEntryView:entryView withMapFilter:mapFilter poi:poi];
                } else {
                    MBService* service = [MBStaticStationInfo serviceForType:@"local_db_lounge" withStation:_station];
                    [self addLinkButtonToEntryView:entryView withMBService:service];
                }
            } else if([key isEqualToString:KEY_SCHLIESSFACH]){
                NSArray* mapFilter = @[PRESET_LOCKER];
                if((poi = [self poiForFilter:mapFilter])){
                    [self addLinkButtonToEntryView:entryView withMapFilter:mapFilter poi:poi];
                }
            } else if([key isEqualToString:KEY_FUNDSERVICE]){
                NSArray* mapFilter = @[PRESET_LOSTFOUND];
                if((poi = [self poiForFilter:mapFilter])){
                    [self addLinkButtonToEntryView:entryView withMapFilter:mapFilter poi:poi];
                } else {
                    MBService* service = [MBStaticStationInfo serviceForType:@"local_lostfound" withStation:_station];
                    [self addLinkButtonToEntryView:entryView withMBService:service];
                }
            }
        }
        entryView.isAccessibilityElement = YES;
        entryView.accessibilityLabel = [NSString stringWithFormat:@"%@: %@",label.text,statusLabel.text];
        
        [self.contentScrollView addSubview:entryView];
        y += entryView.sizeHeight;
    }
    return y;
}

-(RIMapPoi*)poiForFilter:(NSArray*)mapFilterPresets{
    for(RIMapPoi* poi in self.station.riPois){
        NSString* filterTitle = nil;
        NSString* filterSubTitle = nil;
        [poi getFilterTitle:&filterTitle andSubTitle:&filterSubTitle];
        
        NSArray* filterItems = [MBMapViewController filterForFilterPresets:mapFilterPresets];
        if([filterItems containsObject:filterTitle] || [filterItems containsObject:filterSubTitle]){
            //NSLog(@"found");
            return poi;
        }
    }
    //NSLog(@"not found %@",mapFilter);
    return nil;
}

-(void)addLinkButtonToEntryView:(UIView*)entryView withMapFilter:(NSArray*)mapFilter poi:(id)poi{
    __weak MBStationInfrastructureViewController* weakSelf = self;
    [self addLinkButtonToEntryView:entryView withBlock:^{
        weakSelf.activeMapFilter = mapFilter;
        weakSelf.mapPoi = poi;
        MBMapViewController* vc = [MBMapViewController new];
        vc.delegate = weakSelf;
        [vc configureWithStation:weakSelf.station];
        [weakSelf presentViewController:vc animated:YES completion:nil];
    }];
}

-(void)addLinkButtonToEntryView:(UIView*)entryView withMBService:(MBService*)service{
    __weak MBStationInfrastructureViewController* weakSelf = self;
    [self addLinkButtonToEntryView:entryView withBlock:^{
        MBDetailViewController* vc = [[MBDetailViewController alloc] initWithService:service];
        [vc setItem:service];
        
        [MBTrackingManager trackStatesWithStationInfo:@[@"d1", service.trackingKey ]];
        
        [weakSelf.navigationController pushViewController:vc animated:YES];
    }];
}

-(void)addLinkButtonToEntryView:(UIView*)entryView withBlock:(void(^)(void))actionBlock{
    MBButtonWithAction* linkBtn = [[MBButtonWithAction alloc] initWithFrame:CGRectMake(0, 0, entryView.sizeHeight, entryView.sizeHeight)];
    linkBtn.actionBlock = actionBlock;
    [linkBtn setBackgroundColor:[UIColor clearColor]];
    [linkBtn setImage:[UIImage db_imageNamed:@"MapInternalLinkButton"] forState:UIControlStateNormal];
    linkBtn.accessibilityLabel = @"Details aufrufen";
    [entryView addSubview:linkBtn];
    [linkBtn setGravityRight:10];
}

-(NSArray<NSString *> *)mapFilterPresets{
    return self.activeMapFilter;
}
-(id)mapSelectedPOI{
    return self.mapPoi;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (nil != self.navigationController) {
        if ([self.navigationController isKindOfClass:[MBStationNavigationViewController class]]) {
            MBStationNavigationViewController* nav = (MBStationNavigationViewController*) self.navigationController;
            [nav setShowRedBar:NO];
            [nav hideNavbar:YES];
        }
    }

}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    //resize view for content
    int totalHeight = MIN(self.view.sizeHeight-40, self.contentScrollView.contentSize.height+self.headerView.sizeHeight);
    [self.contentView setHeight:totalHeight];
    [self.contentView setGravityBottom:0];
    self.contentScrollView.frame = CGRectMake(0, self.headerView.sizeHeight, self.contentView.sizeWidth, self.contentView.sizeHeight-self.headerView.sizeHeight);

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
