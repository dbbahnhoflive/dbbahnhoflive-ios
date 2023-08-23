// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBContentSearchViewController.h"
#import "MBContentSearchInputField.h"
#import "MBContentSearchTableViewCell.h"

#import "MBContentSearchResult.h"

#import "TimetableManager.h"
#import "RIMapPoi.h"
#import "MBPXRShopCategory.h"
#import "MBRootContainerViewController.h"
#import "MBTimetableViewController.h"
#import "MBOPNVInStationOverlayViewController.h"
#import "MBStationInfrastructureViewController.h"
#import "MBStationNavigationViewController.h"
#import "MBTutorialManager.h"
#import "MBUIHelper.h"
#import "MBTrackingManager.h"

@interface MBContentSearchViewController ()<UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate>

//UI
@property(nonatomic,strong) UIButton* closeButton;
@property(nonatomic,strong) UILabel* stationLabel;
@property(nonatomic,strong) UIButton* inputAccessoryButton;
@property(nonatomic,strong) UITextField* searchField;
@property(nonatomic,strong) UITableView* tableView;
@property(nonatomic,strong) UILabel* searchHeaderLabel;
@property(nonatomic,strong) UIButton* searchResultDeleteButton;

//static configuration data
@property(nonatomic,strong) NSMutableDictionary* searchTags;

@property(nonatomic,strong) NSMutableArray* previousSearches;
@property(nonatomic) BOOL stationChanged;

//Search results
@property(nonatomic,strong) NSMutableArray<MBContentSearchResult*>* searchResults;

@property(nonatomic,strong) NSMutableArray<MBContentSearchResult*>* poiResults;
@property(nonatomic,strong) NSMutableArray<MBContentSearchResult*>* searchTagResults;
@property(nonatomic,strong) NSMutableArray<MBContentSearchResult*>* searchTagOPNVResults;

@property(nonatomic,strong) NSMutableArray<MBContentSearchResult*>* trainSearchResults;
@property(nonatomic,strong) NSMutableArray<MBContentSearchResult*>* opnvSearchResults;
@property(nonatomic,strong) NSMutableArray<MBContentSearchResult*>* platformSearchResults;

#define SETTINGS_CONTENT_SEARCH_LAST_SEARCH_WORDS @"CONTENT_SEARCH_LAST_SEARCH_WORDS"
#define SETTINGS_CONTENT_SEARCH_LAST_STATIONID @"CONTENT_SEARCH_LAST_STATIONID"

@end

@implementation MBContentSearchViewController

-(instancetype)init{
    self = [super init];
    if(self){
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}


-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait|UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor db_f0f3f5];
    
    self.searchTags = [[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"poi_search" ofType:@"json"]] options:0 error:nil] mutableCopy];
    //NSLog(@"searchtags %@",self.searchTags);
    [self prepareSearchTagsForStation];
    
    self.searchResults = [NSMutableArray arrayWithCapacity:200];
    self.trainSearchResults = [NSMutableArray arrayWithCapacity:200];
    self.opnvSearchResults = [NSMutableArray arrayWithCapacity:50];
    self.platformSearchResults = [NSMutableArray arrayWithCapacity:5];
    self.poiResults = [NSMutableArray arrayWithCapacity:200];
    self.searchTagResults = [NSMutableArray arrayWithCapacity:55];
    self.searchTagOPNVResults = [NSMutableArray arrayWithCapacity:10];
    
    NSUserDefaults* def = NSUserDefaults.standardUserDefaults;
    self.previousSearches = [[def objectForKey:SETTINGS_CONTENT_SEARCH_LAST_SEARCH_WORDS] mutableCopy];
    if(!self.previousSearches){
        self.previousSearches = [NSMutableArray arrayWithCapacity:20];
    }
    self.stationChanged = YES;
    NSNumber* lastStationId = [def objectForKey:SETTINGS_CONTENT_SEARCH_LAST_STATIONID];
    if(lastStationId && [lastStationId isEqualToNumber:self.station.mbId]){
        self.stationChanged = NO;
    }
    [def setObject:self.station.mbId forKey:SETTINGS_CONTENT_SEARCH_LAST_STATIONID];
    
    self.closeButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 0, 32, 32)];
    [self.closeButton setImage:[UIImage db_imageNamed:@"ChevronBlackLeft"] forState:UIControlStateNormal];
    self.closeButton.accessibilityLabel = @"Suche schließen";
    [self.closeButton addTarget:self action:@selector(closeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.closeButton];
    
    self.stationLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.stationLabel.text = self.station.title;
    self.stationLabel.textAlignment = NSTextAlignmentCenter;
    self.stationLabel.font = [UIFont db_BoldTwentyTwo];
    self.stationLabel.textColor = [UIColor db_333333];
    self.stationLabel.accessibilityTraits = UIAccessibilityTraitHeader;
    [self.view addSubview:self.stationLabel];

    self.inputAccessoryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.inputAccessoryButton.accessibilityLabel = @"Eingabe löschen";
    [self.inputAccessoryButton setFrame:CGRectMake(0, 0, 25, 25)];
    [self.inputAccessoryButton addTarget:self action:@selector(accessoryButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self updateInputAccessoryForString:@""];

    self.searchField = [[MBContentSearchInputField alloc] initWithFrame:CGRectZero];
    self.searchField.layer.shadowOffset = CGSizeMake(1.0, 1.0);
    self.searchField.layer.shadowColor = [[UIColor db_dadada] CGColor];
    self.searchField.layer.shadowRadius = 4;
    self.searchField.layer.shadowOpacity = 1.0;
    self.searchField.placeholder = STATION_SEARCH_PLACEHOLDER;
    self.searchField.rightViewMode = UITextFieldViewModeAlways;
    self.searchField.delegate = self;
    [self.searchField setRightView:self.inputAccessoryButton];
    [self.view addSubview:self.searchField];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:MBContentSearchTableViewCell.class forCellReuseIdentifier:@"Cell"];
    
    UIView* searchHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 26+10)];
    searchHeader.backgroundColor = [UIColor clearColor];
    UILabel* searchHeaderLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 10, self.view.frame.size.width-30, 20)];
    [searchHeader addSubview:searchHeaderLabel];
    searchHeaderLabel.font = [UIFont db_RegularTwelve];
    self.searchHeaderLabel = searchHeaderLabel;
    
    self.searchResultDeleteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 42,42)];
    self.searchResultDeleteButton.accessibilityLabel = @"Suchverlauf löschen";
    [self.searchResultDeleteButton setImage:[UIImage db_imageNamed:@"app_loeschen"] forState:UIControlStateNormal];
    [self.searchResultDeleteButton addTarget:self action:@selector(searchResultDelete:) forControlEvents:UIControlEventTouchUpInside];
    //self.searchResultDeleteButton.backgroundColor = [UIColor redColor];
    [searchHeader addSubview:self.searchResultDeleteButton];
    searchHeader.clipsToBounds = NO;
    
    self.tableView.tableHeaderView = searchHeader;
    
    [self.view addSubview:self.tableView];
}

-(void)searchResultDelete:(id)sender{    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Suchhistorie" message:@"Möchten Sie die Suchhistorie löschen?" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Abbrechen" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Löschen" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.previousSearches removeAllObjects];
        [self storePreviousSearches];
        [self triggerSearchWithQuery:self.searchField.text];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)prepareSearchTagsForStation{
    if(self.station.riPoiCategories.count == 0){
        //no shops
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_SHOP_AND_EAT];
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_SHOP_OPEN];
    }
    if(!self.station.stationDetails){
        //remove all "Bahnhofsausstattung"
        NSArray* keys = [[self.searchTags allKeys] mutableCopy];
        for(NSString* key in keys){
            if([key hasPrefix:CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE]){
                [self.searchTags removeObjectForKey:key];
            }
        }
    }
    BOOL displaySomeEntriesOnlyWhenAvailable = [MBStationInfrastructureViewController displaySomeEntriesOnlyWhenAvailable:self.station];
    
    //NOTE: some strings Bahnhofsausstattung are *not* removed but in // comments. These
    //      keys are always available and may display "not available" in the interface.
    if(self.station.facilityStatusPOIs.count == 0){
        //no elevators
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_ELEVATOR];
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATIONINFO_ELEVATOR];
    }
    if(!self.station.stationDetails.hasDBInfo){
        if(displaySomeEntriesOnlyWhenAvailable){
            [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_DBINFO];
        }
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_DBINFO];
    }
    if(!self.station.stationDetails.hasDBLounge){
        if(displaySomeEntriesOnlyWhenAvailable){
            [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_LOUNGE];
        }
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_LOUNGE];
    }
    if(!self.station.stationDetails.hasTravelCenter){
        //[self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_TRAVELCENTER];
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_TRAVELCENTER];
    }
    if(!self.station.stationDetails.hasBicycleParking){
        if(displaySomeEntriesOnlyWhenAvailable){
            [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_BIKEPARK];
        }
    }
    if(!self.station.stationDetails.hasCarRental){
        if(displaySomeEntriesOnlyWhenAvailable){
            [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_CARRENTAL];
        }
    }
    if(!self.station.stationDetails.hasParking){
        if(displaySomeEntriesOnlyWhenAvailable){
            [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_PARKING];
        }
    }
    if(!self.station.stationDetails.hasTravelNecessities){
        //[self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_TRAVELNECESSITIES];
    }
    if(!self.station.stationDetails.hasTaxiRank){
        if(displaySomeEntriesOnlyWhenAvailable){
            [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_TAXI];
        }
    }
    if(!self.station.stationDetails.hasPublicFacilities){
        //[self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_WC];
    }
    if(!self.station.stationDetails.hasWiFi){
        if(displaySomeEntriesOnlyWhenAvailable){
            [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_WIFI];
        }
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATIONINFO_WIFI];
    }
    if(!self.station.hasSEVStations){
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATIONINFO_SEV];
    }
    if(self.station.lockerList.count == 0){
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATIONINFO_LOCKER];
    } else {
        //we have lockers, show only the Bahnhofsinformation link and remove the Ausstattung
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_LOCKER];
    }
    if(!self.station.stationDetails.hasDBInfo
       && !self.station.stationDetails.hasLocalServiceStaff
       && !self.station.stationDetails.hasRailwayMission
       && !self.station.stationDetails.hasTravelCenter
       && !self.station.stationDetails.hasDBLounge){
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATIONINFO_SERVICES];
    }
    if(!self.station.stationDetails.has3SZentrale){
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_3S];
    }
    if(!self.station.stationDetails.hasRailwayMission){
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_MISSION];
    }
    if(!self.station.stationDetails.hasLostAndFound){
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_LOSTANDFOUND];
    }
    if(!self.station.stationDetails.hasLocalServiceStaff){
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_MOBILE_SERVICE];
    }
    if(!self.station.stationDetails.hasMobilityService){
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_MOBILITY_SERVICE];
    }
    if(self.station.parkingInfoItems.count == 0){
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_STATIONINFO_PARKING];
    }
    if(self.station.nearestStationsForOPNV.count == 0){
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_OPNV];
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_TRAVELPRODUCT_U_TRAIN];
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_TRAVELPRODUCT_S_TRAIN];
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_TRAVELPRODUCT_TRAM];
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_TRAVELPRODUCT_BUS];
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_TRAVELPRODUCT_FERRY];
    } else {
        //remove only some?
        
    }
    if(!MBMapViewController.canDisplayMap){
        [self.searchTags removeObjectForKey:CONTENT_SEARCH_KEY_MAP];
    }

    //finally, remove all with placeholders [...]
    NSArray* keys = [[self.searchTags allKeys] mutableCopy];
    for(NSString* key in keys){
        NSArray* keywords = [self.searchTags objectForKey:key];
        for(NSString* word in keywords){
            if([word containsString:@"["]){
                [self.searchTags removeObjectForKey:key];
                break;
            }
        }
    }

    //NSLog(@"cleaned up search tags: %@",self.searchTags);
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if(!self.stationChanged && self.previousSearches.count > 0){
        self.searchField.text = self.previousSearches.firstObject;
    }
    [self didEndEditing:self.searchField];//this will load the last search or our search suggestions
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardDidChange:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardDidChange:)
                                                 name:UIKeyboardDidHideNotification object:nil];

    [self.searchField becomeFirstResponder];
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    UIEdgeInsets safeArea = self.view.safeAreaInsets;
    NSInteger x = CGRectGetMaxX(self.closeButton.frame)+5;
    self.stationLabel.frame = CGRectMake(x, 25+safeArea.top, self.view.frame.size.width-10-x, 30);
    [self.closeButton setGravityTop:self.stationLabel.frame.origin.y];

    self.searchField.frame = CGRectMake(0, 0, self.view.frame.size.width-2*24, 60);
    self.searchField.layer.cornerRadius = 30;
    [self.searchField centerViewHorizontalInSuperView];
    [self.searchField setGravityTop:CGRectGetMaxY(self.stationLabel.frame)+30-3];
    
    [self.tableView setBelow:self.searchField withPadding:30-3-10];
    [self.tableView setWidth:self.view.frame.size.width];
    //[self.tableView setHeight:self.view.frame.size.height-self.tableView.frame.origin.y];
    [self.searchResultDeleteButton setGravityRight:24+10];
}

-(void)closeButtonTapped{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL)accessibilityPerformEscape{
    [self closeButtonTapped];
    return YES;
}


-(void)accessoryButtonTapped:(id)sender{
    self.searchField.text = @"";
    [self didEndEditing:self.searchField];
}

-(void)updateInputAccessoryForString:(NSString*)string{
    if(string.length > 0){
        //we have some input
        [self.inputAccessoryButton setImage:[UIImage db_imageNamed:@"app_schliessen"] forState:UIControlStateNormal];
        self.inputAccessoryButton.userInteractionEnabled = YES;
        self.inputAccessoryButton.isAccessibilityElement = YES;
    } else {
        [self.inputAccessoryButton setImage:[UIImage db_imageNamed:@"app_lupe"] forState:UIControlStateNormal];
        self.inputAccessoryButton.userInteractionEnabled = NO;
        self.inputAccessoryButton.isAccessibilityElement = NO;
    }
}

#pragma -
#pragma UITextfieldInputDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString* newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self updateInputAccessoryForString:newString];
    
    // manually delay search to make sure user stopped typing
    // otherwise we send a request on every character
    [NSRunLoop cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(didEndEditing:) withObject:textField afterDelay:0.25];
    return YES;
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    
    if(self.searchResults.count == 0){
        [MBTrackingManager trackActions:@[@"h1",@"poi-suche",@"such-aktion"] withStationInfo:YES additionalVariables:@{@"Search":self.searchField.text, @"Result":@"false"}];
    }
    
    return YES;
}

- (void) didEndEditing:(UITextField*)textField //this called with a delay (see above)
{
    [self updateInputAccessoryForString:textField.text];
    [self triggerSearchWithQuery:textField.text];
}

-(void)triggerSearchWithQuery:(NSString*)query{
    query = [query stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    //search for platform
    NSString* platformNumberString = [self searchPlatformInQuery:query];
    
    NSArray* words = [query componentsSeparatedByString:@" "];
    NSMutableArray<NSString*>* finalWords = [NSMutableArray arrayWithCapacity:words.count];
    for(NSString* word in words){
        if(word.length > 0){
            [finalWords addObject:word];
        }
    }
    
    NSString* previousHeaderText = self.searchHeaderLabel.text;
    self.searchHeaderLabel.text = @"";
    
    [self.searchResults removeAllObjects];
    [self.poiResults removeAllObjects];
    [self.searchTagResults removeAllObjects];
    [self.searchTagOPNVResults removeAllObjects];
    [self.trainSearchResults removeAllObjects];
    [self.opnvSearchResults removeAllObjects];
    [self.platformSearchResults removeAllObjects];
    
    BOOL displaysPreviousSearches = NO;
    if(finalWords.count == 0){
        //no search, fill with previous searches
        displaysPreviousSearches = [self loadPreviousSearches];
    } else if(finalWords.count == 1 && finalWords.firstObject.length == 1){
        //single char, search only in trains
        [self searchTrains:finalWords stations:NO platform:platformNumberString];
        [self searchOPNV:finalWords];
    } else {
        [self searchInTags:finalWords];
        [self searchTrains:finalWords stations:YES platform:platformNumberString];
        [self searchOPNV:finalWords];
        [self searchInPOIs:finalWords];
    }
    
//    [self.trainSearchResults addObjectsFromArray:self.opnvSearchResults];
    [self.poiResults addObjectsFromArray:self.platformSearchResults];
    [self.poiResults addObjectsFromArray:self.searchTagResults];
    
    if(self.poiResults.count == 1 && self.poiResults.firstObject.isShopOpenSearch){
        //special case: add all shops that are open
        [self.poiResults removeAllObjects];
        for(MBPXRShopCategory* cat in self.station.riPoiCategories){
            for(RIMapPoi* poi in cat.items){
                if(poi.isOpen){
                    [self.poiResults addObject:[MBContentSearchResult searchResultWithPOI:poi inCat:cat]];
                }
            }
        }
    }
    
    
    //sort
    // sort train results
    [self.trainSearchResults sortUsingComparator:^NSComparisonResult(MBContentSearchResult* obj1, MBContentSearchResult* obj2) {
        return [obj1 compare:obj2];
    }];
    // sort ÖPNV
    [self.opnvSearchResults sortUsingComparator:^NSComparisonResult(MBContentSearchResult* obj1, MBContentSearchResult* obj2) {
        return [obj1 compare:obj2];
    }];

    // sort poi results
    [self.poiResults sortUsingComparator:^NSComparisonResult(MBContentSearchResult* obj1, MBContentSearchResult* obj2) {
        return [obj1 compare:obj2];
    }];
    
    [self.searchResults addObjectsFromArray:self.poiResults];
    [self.searchResults addObjectsFromArray:self.opnvSearchResults];
    [self.searchResults addObjectsFromArray:self.trainSearchResults];
    
    if(query.length > 0){
        self.searchHeaderLabel.text = @"Suchergebnisse";
        if(self.searchResults.count == 0){
            if([previousHeaderText isEqualToString:@"Suchergebnisse"]){
                //switching from search results to no results, track this once
                [MBTrackingManager trackActions:@[@"h1",@"poi-suche",@"such-aktion"] withStationInfo:YES additionalVariables:@{@"Search":self.searchField.text, @"Result":@"false"}];
            }
            self.searchHeaderLabel.text = @"Kein Suchtreffer";
        }
    }
    self.searchResultDeleteButton.hidden = !displaysPreviousSearches;

    [self.tableView reloadData];
}

-(BOOL)loadPreviousSearches{
    if(self.previousSearches.count > 0){
        self.searchHeaderLabel.text = @"Suchverlauf";
        for(NSString* str in self.previousSearches){
            [self.searchResults addObject:[MBContentSearchResult searchResultWithSearchText:str]];
        }
        return YES;
    } else {
        self.searchHeaderLabel.text = @"Suchvorschläge";
        NSArray* searchSuggestions = nil;
        if(self.station.hasShops){
            searchSuggestions = @[@"Kaffee", @"Schließfach", @"WC"];
        } else {
            searchSuggestions = @[@"ÖPNV", @"Gleis 2", @"WC"];
        }
        for(NSString* str in searchSuggestions){
            [self.searchResults addObject:[MBContentSearchResult searchResultWithSearchText:str]];
        }
        return NO;
    }
}
-(void)storePreviousSearches{
    NSUserDefaults* def = NSUserDefaults.standardUserDefaults;
    [def setObject:self.previousSearches forKey:SETTINGS_CONTENT_SEARCH_LAST_SEARCH_WORDS];
}


-(NSString*)searchPlatformInQuery:(NSString*)query{
    NSRange   searchedRange = NSMakeRange(0, [query length]);
    NSString *pattern = @"Gleis\\s*(\\d+)\\w*";
    NSError  *error = nil;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern: pattern options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray* matches = [regex matchesInString:query options:0 range: searchedRange];
    //NSLog(@"gleis matches: %@",matches);
    NSString* platformNumberString = nil;
    for (NSTextCheckingResult* match in matches) {
        //NSString* matchText = [query substringWithRange:[match range]];
        //NSLog(@"match: %@", matchText);
        NSRange group1 = [match rangeAtIndex:1];
        //NSLog(@"group1: %@", [query substringWithRange:group1]);
        platformNumberString = [query substringWithRange:group1];
    }
    if(!platformNumberString && query.length > 0){
        //did the user enter a single number?
        NSCharacterSet* notDigits = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
        if ([query rangeOfCharacterFromSet:notDigits].location == NSNotFound)
        {
            // newString consists only of the digits 0 through 9
            platformNumberString = query;
        }
    }
    return platformNumberString;
}

-(void)searchInTags:(NSArray<NSString*>*)words{
    NSMutableArray* tags = [NSMutableArray arrayWithCapacity:20];
    for(NSString* key in [self.searchTags allKeys]){
        NSArray* keywords = [self.searchTags objectForKey:key];
        if([self keywords:keywords containSearchWords:words]){
            [tags addObject:key];
        }
    }
    //don't link to Bahnhofsausstattung when the content is available in Bahnhofsinformation
    if([tags containsObject:CONTENT_SEARCH_KEY_STATIONINFO_ELEVATOR]){
        [tags removeObject:CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_ELEVATOR];
    }
    if([tags containsObject:CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_LOUNGE]){
        [tags removeObject:CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_LOUNGE];
    }
    if([tags containsObject:CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_DBINFO]){
        [tags removeObject:CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_DBINFO];
    }
    if([tags containsObject:CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_TRAVELCENTER]){
        [tags removeObject:CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_TRAVELCENTER];
    }
    if([tags containsObject:CONTENT_SEARCH_KEY_STATIONINFO_PARKING]){
        [tags removeObject:CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_PARKING];
    }
    //link only to the details page if it exists:
    if([tags containsObject:CONTENT_SEARCH_KEY_STATIONINFO_WIFI]){
        [tags removeObject:CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_WIFI];
    }


    for(NSString* key in tags){
        if([key isEqualToString:CONTENT_SEARCH_KEY_TRAINORDER]){
            //do we have a departing train with train order?
            Timetable* timetable = [[TimetableManager sharedManager] timetable];
            BOOL found = NO;
            for (Stop *stop in [timetable departureStops]) {
                if ([Stop stopShouldHaveTrainRecord:stop]){
                    found = YES;
                    break;
                }
            }
            if(!found){
                continue;//don't add wagenreihung in search results
            }
        }
        MBContentSearchResult* searchResult = [MBContentSearchResult searchResultWithKeywords:key];
        //special handling for OPNV search tags
        if(searchResult.hafasProductForKeyword != HAFASProductCategoryNONE){
            [self.searchTagOPNVResults addObject:searchResult];
        } else {
            [self.searchTagResults addObject:searchResult];
        }
    }
}
-(BOOL)keywords:(NSArray<NSString*>*)words containSearchWords:(NSArray<NSString*>*)searchWords{
    //the list of keywords must contain all words
    for(NSString* searchWord in searchWords){
        BOOL found = NO;
        for(NSString* word in words){
            if([word localizedCaseInsensitiveContainsString:searchWord]){
                found = YES;
                break;
            }
        }
        if(!found){
            return NO;
        }
    }
    return YES;
}

-(void)searchInPOIs:(NSArray<NSString*>*)words{
    for(MBPXRShopCategory* cat in self.station.riPoiCategories){
        
        BOOL foundCat = YES;
        for(NSString* searchWord in words){
            if(![cat.title localizedCaseInsensitiveContainsString:searchWord]){
                foundCat = NO;
                break;
            }
        }
        if(foundCat){
            //NSLog(@"found all words in %@",stringForSearch);
            [self.poiResults addObject:[MBContentSearchResult searchResultWithPOI:nil inCat:cat]];
        }
        
        for(RIMapPoi* poi in cat.items){
            
            //does this POI contain all search words?, search in combination of displayname and category lables
            NSMutableString* stringForSearch = [NSMutableString stringWithString:poi.title];
            if(poi.category.length > 0){
                [stringForSearch appendString:@" "];
                [stringForSearch appendString:poi.category];
            }
            if(poi.menucat.length > 0){
                [stringForSearch appendString:@" "];
                [stringForSearch appendString:poi.menucat];
            }
            if(poi.menusubcat.length > 0){
                [stringForSearch appendString:@" "];
                [stringForSearch appendString:poi.menusubcat];
            }
            if(poi.name.length > 0){
                [stringForSearch appendString:@" "];
                [stringForSearch appendString:poi.name];
            }
            if(poi.tags.length > 0){
                [stringForSearch appendString:@" "];
                //we remove all spaces from the tags, "curry wurst" will be "currywurst"
                [stringForSearch appendString:[poi.tags stringByReplacingOccurrencesOfString:@" " withString:@""]];
            }
            if([poi.name isEqualToString:@"everyworks"]){
                [stringForSearch appendString:@"everyworks, every, work, Arbeit, office, Büro, Buero, coworking, working, smart, city, Arbeitsplatz, Platz, Meeting, Room, Meetingraum, Raum"];
            }
            BOOL found = YES;
            for(NSString* searchWord in words){
                if(![stringForSearch localizedCaseInsensitiveContainsString:searchWord]){
                    found = NO;
                    break;
                }
            }
            if(found){
                //NSLog(@"found all words in %@",stringForSearch);
                [self.poiResults addObject:[MBContentSearchResult searchResultWithPOI:poi inCat:cat]];
            }
        }
    }

}

-(void)searchTrains:(NSArray<NSString*>*)words stations:(BOOL)searchStations platform:(NSString*)platformNumberString{
    [self searchTrains:words departure:YES stations:searchStations platform:platformNumberString];
    [self searchTrains:words departure:NO stations:searchStations platform:platformNumberString];
}
-(void)searchTrains:(NSArray<NSString*>*)words departure:(BOOL)departure stations:(BOOL)searchStations platform:(NSString*)platformNumberString{
    Timetable* timetable = [[TimetableManager sharedManager] timetable];
    NSArray *stops = departure ? [timetable departureStops] : [timetable arrivalStops];
    
    BOOL listAllSSTrains = departure && ([self hafasProductsInSearchTags] & HAFASProductCategoryS) > 0;
    
    for (Stop *stop in stops) {
        Event *event = [stop eventForDeparture:departure];
        NSString* lineStringForSearch = @"";
        if(event.lineIdentifier.length > 0){
            lineStringForSearch = [NSString stringWithFormat:@"%@%@%@",event.lineIdentifier, stop.transportCategory.transportCategoryType, event.lineIdentifier];
        } else {
            if(stop.transportCategory.transportCategoryNumber.length > 0){
                lineStringForSearch = [NSString stringWithFormat:@"%@%@%@",stop.transportCategory.transportCategoryNumber, stop.transportCategory.transportCategoryType, stop.transportCategory.transportCategoryNumber];
            } else {
                lineStringForSearch = stop.transportCategory.transportCategoryType;
            }
        }
        if(searchStations){
            //append the stations in the string
            NSMutableString* searchString = [NSMutableString stringWithString:lineStringForSearch];
            NSArray *stations = [event stationListWithCurrentStation:self.station.title];
            for(NSString* s in stations){
                [searchString appendString:@" "];
                [searchString appendString:s];
            }
            lineStringForSearch = searchString;
        }
        
        //search the words
        BOOL found = YES;
        for(NSString* s in words){
            if(![lineStringForSearch localizedCaseInsensitiveContainsString:s]){
                found = NO;
                break;
            }
        }
        
        if(listAllSSTrains && [stop.transportCategory.transportCategoryType isEqualToString:@"S"]){
            found = YES;
        }
        
        if(found){
            [self.trainSearchResults addObject:[MBContentSearchResult searchResultWithStop:stop departure:departure]];
        }
        
        if(departure && platformNumberString.length > 0){
            //check if the platform matches and add it when it does not exist to platformSearchResults
            if([event.actualPlatform containsString:platformNumberString]){
                [self addPlatform:event.actualPlatformNumberOnly];//number only, search result for 5a and 5c is the same
            }
        }
    }
}

-(HAFASProductCategory)hafasProductsInSearchTags{
    HAFASProductCategory cat = HAFASProductCategoryNONE;
    for(MBContentSearchResult* res in self.searchTagOPNVResults){
        HAFASProductCategory catForKeyword = res.hafasProductForKeyword;
        if(catForKeyword != HAFASProductCategoryNONE){
            cat |= catForKeyword;
        }
    }
    return cat;
}

-(void)searchOPNV:(NSArray*)words{
    //for(NSDictionary* station in self.station.nearestStationsForOPNV){
    {
        //search for ÖPNV lines only in the nearest station!
        MBOPNVStation* station = self.station.nearestStationsForOPNV.firstObject;
        for(NSUInteger product = HAFASProductCategoryS; product < HAFASProductCategoryCAL; product = product<<1){
            //we iterate over S, Bus, Ship, U, Tram
            //NSLog(@"iterate over products %lu",(unsigned long)product);
            NSArray* lineCodes = [station lineCodesForProduct:product]; 
            NSString* productString = @" ";
            switch (product) {
                case HAFASProductCategoryS:
                    productString = @"S";
                    break;
                case HAFASProductCategoryBUS:
                    productString = @"Bus";
                    break;
                case HAFASProductCategorySHIP:
                    productString = @"Fähre";
                    break;
                case HAFASProductCategoryU:
                    productString = @"U";
                    break;
                case HAFASProductCategoryTRAM:
                    productString = @"Tram";
                    break;
                default:
                    break;
            }
            BOOL productFoundViaTags = ([self hafasProductsInSearchTags] & product) > 0;
            for(NSString* line in lineCodes){
                NSString* lineStringForSearch = [NSString stringWithFormat:@"%@%@%@",line,productString,line];
                //search the words
                BOOL found = YES;
                for(NSString* s in words){
                    if(![lineStringForSearch localizedCaseInsensitiveContainsString:s]){
                        found = NO;
                        break;
                    }
                }
                if(found || productFoundViaTags){
                    NSString* lineString = line;//[NSString stringWithFormat:@"%@ %@",productString,line];
                    //check if we already added this line
                    BOOL found = NO;
                    for(MBContentSearchResult* s in self.opnvSearchResults){
                        if(s.opnvCat == product && [lineString isEqualToString:s.opnvLineIdentifier]){
                            found = YES;
                            break;
                        }
                    }
                    if(!found){
                        [self.opnvSearchResults addObject:[MBContentSearchResult searchResultWithOPNV:lineString category:product line:line]];
                    }
                }
            }
        }
    }
}

-(void)addPlatform:(NSString*)platform{
    for(MBContentSearchResult* res in self.platformSearchResults){
        if([res.platformSearch isEqualToString:platform]){
            return;
        }
    }
    [self.platformSearchResults addObject:[MBContentSearchResult searchResultWithPlatform:platform]];
}

- (void)keyBoardDidChange:(NSNotification*)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    CGFloat yTable = self.tableView.frame.origin.y;
    UIView* parent = self.tableView.superview;
    while(parent != nil){
        yTable += parent.frame.origin.y;
        parent = parent.superview;
    }
    
    self.tableView.height = keyboardFrameBeginRect.origin.y-yTable;
}



-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.searchResults.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    MBContentSearchTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    MBContentSearchResult* res = self.searchResults[indexPath.row];
    cell.titleLabel.text = res.title;
    if([cell.titleLabel.text containsString:@" ICE "]){
        cell.titleLabel.accessibilityLabel = [res.title stringByReplacingOccurrencesOfString:@" ICE " withString:@" I C E "];
    } else {
        cell.titleLabel.accessibilityLabel = res.title;
    }
    NSString* icon = res.iconName;
    cell.iconView.image = [UIImage db_imageNamed:icon];
    return cell;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 40;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    cell.backgroundColor = [UIColor clearColor];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MBContentSearchResult* res = self.searchResults[indexPath.row];
    if(res.isTextSearch){
        self.searchField.text = res.searchText;
        [self didEndEditing:self.searchField];
    } else {
        //process search text
        [self.previousSearches removeObject:self.searchField.text];
        [self.previousSearches insertObject:self.searchField.text atIndex:0];
        while(self.previousSearches.count > 10){
            [self.previousSearches removeLastObject];
        }
        [self storePreviousSearches];
        
        //track actions
        NSString* trackingTitle = res.title;
        if(res.isTimetableSearch){
            //use a general title
            NSMutableString* trackingTitleForDepartures = [[NSMutableString alloc] init];
            if(res.isOPNVSearch){
                [trackingTitleForDepartures appendString:@"ÖPNV"];
            } else {
                [trackingTitleForDepartures appendString:@"DB"];
            }
            [trackingTitleForDepartures appendString:@"-Tafel-"];
            if(res.departure){
                [trackingTitleForDepartures appendString:@"Abfahrt"];
            } else {
                [trackingTitleForDepartures appendString:@"Ankunft"];
            }
            trackingTitle = trackingTitleForDepartures;
        }
        [MBTrackingManager trackActions:@[@"h1",@"poi-suche",@"tap-result"] withStationInfo:YES additionalVariables:@{@"Search":self.searchField.text, @"FollowedPOI":trackingTitle}];
        [MBTrackingManager trackActions:@[@"h1",@"poi-suche",@"such-aktion"] withStationInfo:YES additionalVariables:@{@"Search":self.searchField.text, @"Result":@"true"}];

        
        //hide and show result
        [[MBTutorialManager singleton] markTutorialAsObsolete:MBTutorialViewType_H1_Search];
        
        [self.searchField resignFirstResponder];
        [self dismissViewControllerAnimated:YES completion:^{
            MBRootContainerViewController* root = [MBRootContainerViewController currentlyVisibleInstance];
            [root handleSearchResult:res];
        }];
    }
}

@end
