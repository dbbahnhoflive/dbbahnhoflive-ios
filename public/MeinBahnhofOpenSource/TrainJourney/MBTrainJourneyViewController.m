// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBTrainJourneyViewController.h"
#import "MBStationNavigationViewController.h"
#import "MBLargeButton.h"
#import "MBTrainOrderDisplayHelper.h"
#import "MBUIHelper.h"
#import "MBTrainJourneyStopTableViewCell.h"

#import "MBStaticStationInfo.h"
#import "MBDetailViewController.h"
#import "MBPlatformAccessibilityView.h"
#import "MBLinkButton.h"
#import "MBTrainJourneyRequestManager.h"
#import "AppDelegate.h"
#import "MBStationSearchViewController.h"
#import "MBRootContainerViewController.h"
#import "MBRISStationsRequestManager.h"
#import "MBTrackingManager.h"
#import "MBProgressHUD.h"
#import "HafasStopLocation.h"
#import "MBLinkButton.h"
#import "MBContentSearchResult.h"
#import "MBTutorialManager.h"
#import "MBBackNavigationState.h"
#import "MBUrlOpening.h"
#import "MBAccompanimentTeaserView.h"

@interface MBTrainJourneyViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic, strong) UIImageView *messageIcon;
@property (nonatomic, strong) UILabel *messageTextLabel;
@property (nonatomic, strong) MBLinkButton *showFullJourneyButton;
@property (nonatomic, strong) MBLinkButton *sevButton;
@property (nonatomic, strong) MBLinkButton *accompanimentButton;

@property(nonatomic,strong) MBLargeButton* trainOrderButton;

@property(nonatomic,strong) UITableView* segmentTableView;
@property(nonatomic,strong) NSArray<MBTrainJourneyStop *> * journeyStops;

@property(nonatomic) BOOL layoutForIRIS;
@property(nonatomic,strong) NSString* currentEva;
@property(nonatomic) NSInteger firstIndexWithCurrentStation;
@property(nonatomic) BOOL journeyHasPreviousStations;

@property(nonatomic,strong) NSDate* dateForTrainPosition;
@property(nonatomic,strong) UIRefreshControl* refreshControl;

@end

@implementation MBTrainJourneyViewController

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [(MBStationNavigationViewController *)self.navigationController hideNavbar:NO];
    [(MBStationNavigationViewController *)self.navigationController showBackgroundImage:NO];
    [(MBStationNavigationViewController *)self.navigationController setShowRedBar:YES];
    
    [[MBTutorialManager singleton] displayTutorialIfNecessary:MBTutorialViewType_Zuglauf_StationLink withOffset:60];

}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
//    if(!self.layoutForIRIS && self.firstIndexWithCurrentStation != -1){
//        NSLog(@"scroll to index %ld in %@",(long)self.firstIndexWithCurrentStation,self.segmentTableView);
//        if(self.firstIndexWithCurrentStation < self.journeyStops.count){
//            [self.segmentTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.firstIndexWithCurrentStation inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:animated];
//        }
//    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.currentEva = self.event.stop.evaNumber;
    
    self.messageIcon = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_warndreieck"]];
    [self.view addSubview:self.messageIcon];
    self.messageTextLabel = [UILabel new];
    [self.messageTextLabel setFont:[UIFont db_RegularTwelve]];
    [self.messageTextLabel setTextColor:[UIColor db_mainColor]];
    self.messageTextLabel.numberOfLines = 0;
    self.messageTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.view addSubview:self.messageTextLabel];

    BOOL isSEV = false;
    if(self.hafasDeparture){
        NSString* train = self.hafasDeparture.name;
        isSEV = [train.uppercaseString containsString:@"SEV"];
        self.title = [NSString stringWithFormat:@"Haltestellen %@ nach %@", train,self.hafasDeparture.stopLocationTitles.lastObject];
    } else {
        NSString* train = [self.event.stop formattedTransportType:self.event.lineIdentifier];
        isSEV = [train.uppercaseString containsString:@"SEV"] || self.journey.isSEVJourney;
        if(self.event.departure){
            self.title = [NSString stringWithFormat:@"Zuglauf %@ nach %@", train,self.event.actualStation];
        } else {
            self.title = [NSString stringWithFormat:@"Zuglauf %@ von %@", train,self.event.actualStation];
        }
    }
    
    if(self.showJourneyMessageAndTrainLinks && isSEV){
        self.sevButton = [MBLinkButton buttonWithRedLink];
        self.sevButton.labelFont = [UIFont db_BoldFourteen];
        [self.sevButton addTarget:self action:@selector(openSEV) forControlEvents:UIControlEventTouchUpInside];
        [self.sevButton setLabelText:@"Übersicht Ersatzverkehr"];
        [self.view addSubview:self.sevButton];
        if(self.station.hasAccompanimentService){
            self.accompanimentButton = [MBLinkButton boldButtonWithSmallRedExternalLink];
            [self.accompanimentButton addTarget:self action:@selector(openAccompaniment) forControlEvents:UIControlEventTouchUpInside];
            [self.accompanimentButton setLabelText:@"DB Wegbegleitung"];
            [self.view addSubview:self.accompanimentButton];
        }
    }

    if(self.showJourneyMessageAndTrainLinks && [Stop stopShouldHaveTrainRecord:self.event.stop]){
        self.trainOrderButton = [[MBLargeButton alloc] initWithFrame:CGRectZero];
        [self.trainOrderButton setImage:[UIImage db_imageNamed:@"app_wagenreihung_weiss"] forState:UIControlStateNormal];
        [self.trainOrderButton setTitle:@"Zur Wagenreihung" forState:UIControlStateNormal];
        
        [self.trainOrderButton addTarget:self action:@selector(showTrainOrder) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.trainOrderButton];
    }
    
    self.segmentTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    [self.segmentTableView registerClass:MBTrainJourneyStopTableViewCell.class forCellReuseIdentifier:@"Cell"];
    self.segmentTableView.dataSource = self;
    self.segmentTableView.delegate = self;
    self.segmentTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.segmentTableView.backgroundColor = UIColor.db_f3f5f7;
    self.segmentTableView.contentInset = UIEdgeInsetsMake(0, 0.0, 90.0, 0.0);
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshData) forControlEvents:UIControlEventValueChanged];
    self.segmentTableView.refreshControl = self.refreshControl;
    
    [self processData];
    
    [self.view addSubview:self.segmentTableView];
}

-(void)openSEV{
    MBContentSearchResult* res = [MBContentSearchResult searchResultWithKeywords:@"Bahnhofsinformation Ersatzverkehr"];
    MBRootContainerViewController* root = [MBRootContainerViewController currentlyVisibleInstance];
    [root handleSearchResult:res];
}
-(void)openAccompaniment{
    [MBUrlOpening openURL:[NSURL URLWithString:WEGBEGLEITUNG_LINK]];
}

-(void)processData{
    [self configureMessage];
    
    if(self.journey){
        self.journeyStops = self.journey.journeyStops;
    }
    self.firstIndexWithCurrentStation = -1;
    self.journeyHasPreviousStations = false;
    NSInteger index = 0;
    if(!self.journeyStops){
        //create segments from IRIS station list
        self.layoutForIRIS = true;
        
        NSArray *stations = nil;
        NSString* stationsTitle = self.station.title;
        if(self.hafasDeparture){
            stations = self.hafasDeparture.stopLocationTitles;
            stationsTitle = self.hafasStationThatOpenedThisJourney.title;
        } else {
            stations = [self.event stationListWithCurrentStation:self.station.title];
        }
        NSMutableArray* res = [NSMutableArray arrayWithCapacity:stations.count];
        for(NSString* station in stations){
            MBTrainJourneyStop* s = [MBTrainJourneyStop new];
            s.stationName = station;
            if(self.hafasDeparture){
                //do we have an extId?
                if(index < self.hafasDeparture.stopLocations.count){
                    HafasStopLocation* stop = self.hafasDeparture.stopLocations[index];
                    s.evaNumber = stop.extId;
                }
            }
            if(self.firstIndexWithCurrentStation == -1 && [station isEqualToString:stationsTitle]){
                self.firstIndexWithCurrentStation = index;
            }
            [res addObject:s];
            index++;
        }
        self.journeyStops = res;
    } else {
        NSLog(@"stations:");
        for(MBTrainJourneyStop* s  in self.journeyStops){
            NSLog(@"%@",s.stationName);
            if(self.firstIndexWithCurrentStation == -1 && [s.evaNumber isEqualToString:self.currentEva]){
                self.firstIndexWithCurrentStation = index;
            }
            index++;
        }
        if(self.firstIndexWithCurrentStation == -1){
            NSLog(@"did not find eva %@ in list of stops %@",self.currentEva,self.journeyStops);
        }
        [self updateJourneyProgress];
    }
    
    if(self.firstIndexWithCurrentStation > 0){
        self.journeyHasPreviousStations = true;
    }
    
    if(self.journey && self.showJourneyFromCurrentStation && self.journeyHasPreviousStations){
        NSLog(@"showing only stations from current station...");
        self.journeyStops = [self.journeyStops subarrayWithRange:NSMakeRange(self.firstIndexWithCurrentStation, self.journeyStops.count-self.firstIndexWithCurrentStation)];
        self.firstIndexWithCurrentStation = 0;
        self.showFullJourneyButton = [MBLinkButton boldButtonWithRedLink];
        [self.showFullJourneyButton addTarget:self action:@selector(showFullJourney) forControlEvents:UIControlEventTouchUpInside];
        [self.showFullJourneyButton setLabelText:@"Gesamten Fahrtverlauf anzeigen"];
        UIView* footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
        footerView.backgroundColor = UIColor.db_f3f5f7;
        [footerView addSubview:self.showFullJourneyButton];
        self.segmentTableView.tableFooterView = footerView;
    } else {
        self.showFullJourneyButton = nil;
        self.segmentTableView.tableFooterView = nil;
    }
    
    if(self.layoutForIRIS && !self.hafasDeparture){
        UIView* header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 40)];
        header.backgroundColor = [UIColor clearColor];
        UILabel* headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, self.view.frame.size.width-30, 20)];
        [header addSubview:headerLabel];
        headerLabel.font = [UIFont db_RegularTwelve];
        headerLabel.textColor = UIColor.db_333333;
        headerLabel.text = @"Es konnten nicht alle Daten geladen werden";
        [headerLabel sizeToFit];
        UIImageView* messageIcon = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_warndreieck_dunkelgrau"]];
        messageIcon.isAccessibilityElement = NO;
        [header addSubview:messageIcon];
        NSInteger totalSize = messageIcon.frame.size.width+5+headerLabel.frame.size.width;
        NSInteger x = (header.frame.size.width-totalSize)/2;
        [messageIcon setGravityTop:10];
        [messageIcon setGravityLeft:x];
        [headerLabel setRight:messageIcon withPadding:5];
        self.segmentTableView.tableHeaderView = header;
    } else {
        self.segmentTableView.tableHeaderView = nil;
    }
}


-(void)refreshData{
    [self.refreshControl beginRefreshing];
    NSLog(@"refreshing data for event %@",self.event);
    [[MBTrainJourneyRequestManager sharedManager] loadJourneyForEvent:self.event completionBlock:^(MBTrainJourney * _Nullable journey) {
        if(journey){
            self.journey = journey;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self processData];
            [self.segmentTableView reloadData];
            [self.refreshControl endRefreshing];
            [self.view setNeedsLayout];
        });
    }];
}

-(void)updateJourneyProgress{
    if(!self.journey){
        return;//no journey progress for IRIS data
    }
    self.dateForTrainPosition = NSDate.date;
    NSTimeInterval now = self.dateForTrainPosition.timeIntervalSinceReferenceDate;
    NSInteger index = 0;
    NSLog(@"calculated progress: %f",now);
    BOOL containsScheduleTime = false;
    for(MBTrainJourneyStop* s  in self.journeyStops){
        //Default is -1, meaning the station was not yet reached
        s.journeyProgress = -1;
        if(s.isTimeScheduleStop){
            containsScheduleTime = true;
        }
    }
    if(containsScheduleTime){
        NSLog(@"don't show journey progress when there are SCHEDULEd events");
        return;
    }
    for(MBTrainJourneyStop* s  in self.journeyStops){
        MBTrainJourneyStop* nextStop = (index+1 < self.journeyStops.count ? self.journeyStops[index+1] : nil);
        
        NSTimeInterval arrival = s.arrivalTime.timeIntervalSinceReferenceDate;
        NSTimeInterval departure = s.departureTime.timeIntervalSinceReferenceDate;
        NSTimeInterval arrivalNextStation = nextStop.arrivalTime.timeIntervalSinceReferenceDate;
        NSLog(@"%@: %f, %f, %f",s.stationName,arrival,departure,arrivalNextStation);

        if(now >= departure && now < arrivalNextStation){
            NSLog(@"train is between %@ and %@",s.stationName,nextStop.stationName);
            s.journeyProgress = (now-departure)*100 / (arrivalNextStation-departure);
            if(s.journeyProgress > 50){
                //store the value in the next station and mark this station as 100%
                nextStop.journeyProgress = s.journeyProgress;
                s.journeyProgress = 100;
            }
            break;
        } else if(arrivalNextStation != 0 && now > arrivalNextStation) {
            NSLog(@"train is past %@",s.stationName);
            s.journeyProgress = 100;
        } else if(arrival != 0 && now >= arrival && now <= departure){
            NSLog(@"train is at %@",s.stationName);
            s.journeyProgress = 0;
        } else if(arrival != 0 && now >= arrival){
            s.journeyProgress = 100;
        }
        index++;
    }
    NSLog(@"result:");
    for(MBTrainJourneyStop* s  in self.journeyStops){
        NSLog(@"%@: %ld",s.stationName,(long)s.journeyProgress);
    }
}

-(void)selectCurrentStation{
    //find current station
    NSInteger indexRow = 0;
    for(MBTrainJourneyStop* j in self.journeyStops){
        if([j.evaNumber isEqualToString:self.currentEva]){
            break;
        }
        indexRow++;
    }
    if(indexRow < [self tableView:self.segmentTableView numberOfRowsInSection:0]){
        UIView* cell = [self.segmentTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0]];
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, cell);
    }
}
-(void)openPlatformAccessibility{
    if(self.firstIndexWithCurrentStation == -1 || !self.journeyStops){
        return;
    }
    MBService* service = [MBStaticStationInfo serviceForType:kServiceType_Barrierefreiheit withStation:self.station];
    MBTrainJourneyStop* stop = self.journeyStops[self.firstIndexWithCurrentStation];
    NSString* platform = [MBStation platformNumberFromPlatform:stop.platform];
    service.serviceConfiguration = @{ MB_SERVICE_ACCESSIBILITY_CONFIG_KEY_PLATFORM: platform};
    MBDetailViewController* vc = [[MBDetailViewController alloc] initWithStation:self.station service:service];
    [self.navigationController pushViewController:vc animated:NO];
}

-(void)showTrainOrder{
    MBTrainOrderDisplayHelper* helper = [MBTrainOrderDisplayHelper new];
    [helper showWagenstandForStop:self.event.stop station:self.station departure:self.departure inViewController:self];
}

-(void)showFullJourney{
    MBTrainJourneyViewController* detailViewController = [MBTrainJourneyViewController new];
    detailViewController.departure = self.departure;
    detailViewController.station = self.station;
    detailViewController.hafasStationThatOpenedThisJourney = self.hafasStationThatOpenedThisJourney;
    detailViewController.hafasDeparture = self.hafasDeparture;
    detailViewController.event = self.event;
    detailViewController.stop = self.stop;
    detailViewController.journey = self.journey;
    [self.navigationController pushViewController:detailViewController animated:YES];
}

-(void)configureMessage{    
    if(self.showJourneyMessageAndTrainLinks && self.hasMessageForThisStation){
        self.messageIcon.hidden = NO;
        self.messageTextLabel.hidden = NO;
        if(self.event.hasOnlySplitMessage){
            self.messageIcon.image = [UIImage db_imageNamed:@"app_warndreieck_dunkelgrau"];
            [self.messageTextLabel setTextColor:[UIColor db_333333]];
        } else {
            self.messageIcon.image = [UIImage db_imageNamed:@"app_warndreieck"];
            [self.messageTextLabel setTextColor:[UIColor db_mainColor]];
        }
        self.messageTextLabel.text = self.messageForThisStation;
        
    } else {
        self.messageIcon.hidden = YES;
        self.messageTextLabel.hidden = YES;
    }
}


-(BOOL)hasMessageForThisStation{
    return self.messageForThisStation.length > 0;
}
-(NSString*)messageForThisStation{
    return self.event.composedIrisMessage;
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    [self layoutMessage];
    NSInteger y = [self layoutTrainOrderButton];
    self.segmentTableView.frame = CGRectMake(0, y, self.view.frame.size.width, self.view.frame.size.height-y);
    [self.showFullJourneyButton setSize:CGSizeMake(self.view.frame.size.width, 50)];
    [self.showFullJourneyButton setGravityLeft:15];
}

-(void)layoutMessage{
    if(!self.messageIcon.hidden){
        CGSize size = [self.messageTextLabel sizeThatFits:CGSizeMake(self.view.frame.size.width-2*24-24, 1000)];
        [self.messageTextLabel setSize:size];
        NSInteger totalWidth = 24 + size.width;
        [self.messageTextLabel setGravityTop:15+5];
        [self.messageIcon setGravityTop:15];
        [self.messageIcon setGravityLeft:(self.view.frame.size.width-totalWidth)/2];
        [self.messageTextLabel setGravityLeft:(self.view.frame.size.width-totalWidth)/2+24];
    }
}

-(NSInteger)layoutTrainOrderButton{
    NSInteger topSpace = 0;
    if(self.messageTextLabel.text.length > 0 && !self.messageIcon.hidden){
        topSpace = CGRectGetMaxY(self.messageTextLabel.frame)+15;
    } else if(self.trainOrderButton){
        topSpace = 15;
    }
    
    if(self.sevButton){
        if(topSpace == 0){
            topSpace = 15;
        }
        [self.sevButton setGravityTop:topSpace];
        [self.sevButton setGravityLeft:24];
        topSpace = CGRectGetMaxY(self.sevButton.frame)+15;
    }
    if(self.accompanimentButton){
        [self.accompanimentButton setGravityTop:topSpace];
        [self.accompanimentButton setGravityLeft:24+2];
        topSpace = CGRectGetMaxY(self.accompanimentButton.frame)+15;
    }
    
    if(self.trainOrderButton){
        [self.trainOrderButton setSize:CGSizeMake(self.view.frame.size.width-2*24, 60)];
        [self.trainOrderButton setGravityTop:topSpace];
        [self.trainOrderButton centerViewHorizontalInSuperView];
        self.trainOrderButton.titleEdgeInsets = UIEdgeInsetsMake(0,
                                                                 -2.0 * (self.trainOrderButton.imageView.frame.size.width + 10.0),
                                                                 0,
                                                                 0);
        self.trainOrderButton.imageEdgeInsets = UIEdgeInsetsMake(0, self.trainOrderButton.titleLabel.frame.origin.x+self.trainOrderButton.titleLabel.frame.size.width+10.0, 0, 0);
        return CGRectGetMaxY(self.trainOrderButton.frame)+15;
    }
    return topSpace;
}

- (id)mapSelectedPOI
{
    if(self.hafasDeparture){
        return nil;
    }
    RIMapPoi* res = [self.station poiForPlatform:self.event.actualPlatformNumberOnly];
    return res;
}
-(BOOL)mapShouldCenterOnUser{
    return NO;
}
-(NSArray<NSString *> *)mapFilterPresets{
    if(self.hafasDeparture){
        return @[ PRESET_LOCAL_TIMETABLE ];
    }
    return @[ PRESET_DB_TIMETABLE ];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 72;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    MBTrainJourneyStopTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    MBTrainJourneyStop* j = self.journeyStops[indexPath.row];
    if(_layoutForIRIS){
        [cell setStopWithString:j.stationName isFirst:(j==self.journeyStops.firstObject) isLast:((j==self.journeyStops.lastObject)) isCurrentStation:[j.evaNumber isEqualToString:self.currentEva]];
    } else {
        BOOL isFirst = (j==self.journeyStops.firstObject && ((self.showJourneyFromCurrentStation && !self.journeyHasPreviousStations) || (!self.showJourneyFromCurrentStation)));
        [cell setStop:j isFirst:isFirst isLast:((j==self.journeyStops.lastObject)) isCurrentStation:[j.evaNumber isEqualToString:self.currentEva]];
    }
    return cell;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.journeyStops.count;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MBTrainJourneyStop* stop = self.journeyStops[indexPath.row];
    if(self.hafasStationThatOpenedThisJourney && stop.evaNumber && [self.hafasStationThatOpenedThisJourney.stationEvaIds containsObject:stop.evaNumber]){
        NSLog(@"trying to select this station from journey, ignore");
        return;
    }
    if(stop.evaNumber && ![self.station.stationEvaIds containsObject:stop.evaNumber]){
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:[@"Öffne " stringByAppendingString:stop.stationName] message:@"Sie werden zur ausgewählten Station weitergeleitet." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Abbrechen" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Öffnen" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[MBTutorialManager singleton] markTutorialAsObsolete:MBTutorialViewType_Zuglauf_StationLink];
            [MBTrackingManager trackActionsWithStationInfo:@[@"h2",@"journey",@"openstation"]];
            UIView* progressView = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, progressView);
            
            NSString* evaIdToLoad = stop.evaNumber;
            //BAHNHOFLIVE-2395
            if(self.station.hasStaticAdHocBox && self.journey.isSEVJourney){
                NSString* evaReplace = [self.station isAdditionalEvaId_MappedToMainEva:stop.evaNumber];
                if(evaReplace){
                    NSLog(@"replacing %@ with %@ to load the DB-Station instead of the OPNV",evaIdToLoad,evaReplace);
                    evaIdToLoad = evaReplace;
                }
            }
            
            [[MBRISStationsRequestManager sharedInstance] searchStationByEva:evaIdToLoad success:^(MBStationFromSearch *station) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                if(station){
                    station.isInternalLink = true;
                    MBBackNavigationState* state = [MBBackNavigationState new];
                    if(!self.station && self.hafasStationThatOpenedThisJourney){
                        state.isOPNVStation = true;
                        state.mbId = self.hafasStationThatOpenedThisJourney.mbId;
                        state.title = self.hafasStationThatOpenedThisJourney.title;
                        state.evaIds = self.hafasStationThatOpenedThisJourney.stationEvaIds;
                        state.position = self.hafasStationThatOpenedThisJourney.positionAsLatLng;
                    } else {
                        state.mbId = self.station.mbId;
                        state.title = self.station.title;
                        state.evaIds = self.station.stationEvaIds;
                        state.position = self.station.positionAsLatLng;
                    }
                    state.isFromDeparture = self.departure;
                    state.stop = self.stop;
                    state.hafasDeparture = self.hafasDeparture;
                    state.hafasStation = self.originalHafasStation;

                    AppDelegate* app = (AppDelegate*) UIApplication.sharedApplication.delegate;
                    MBStationSearchViewController* vc = (MBStationSearchViewController*) app.viewController;
                    [vc openStationFromInternalLink:station withBackState:state];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
                    });
                } else {
                    [self stationLoadError];
                }
            } failureBlock:^(NSError * error) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [self stationLoadError];
            }];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}
-(void)stationLoadError{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Fehler" message:@"Die Station konnte nicht geladen werden." preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Abbrechen" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];

}

@end
