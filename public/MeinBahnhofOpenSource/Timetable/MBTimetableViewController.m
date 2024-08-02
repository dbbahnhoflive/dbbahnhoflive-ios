// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBTimetableViewController.h"
#import "MBTimeTableViewCell.h"
#import "MBTimeTableFilterViewCell.h"
#import "MBTimeTableOEPNVTableViewCell.h"

#import "MBStationNavigationViewController.h"

#import "MBLabel.h"
#import "MBSwitch.h"
#import "MBLargeButton.h"

#import "NSDateFormatter+MBDateFormatter.h"

#import "Stop.h"
#import "Timetable.h"
#import "WagenstandRequestManager.h"
#import "HafasTimetable.h"
#import "MBMapViewController.h"

#import "MBTrainPositionViewController.h"
#import "MBTrainJourneyViewController.h"
#import "MBTrainJourneyRequestManager.h"
#import "MBTrainOrderDisplayHelper.h"
#import "MBProgressHUD.h"

#import "MBTimetableFilterViewController.h"
#import "MBRootContainerViewController.h"

#import "MBHafasTimetableDataSource.h"
#import "MBTutorialManager.h"
#import "MBMapViewButton.h"
#import "MBContentSearchResult.h"
#import "MBUIHelper.h"
#import "MBTrackingManager.h"

#import "MBStationSearchViewController.h"
#import "AppDelegate.h"
#import "MBBackNavigationState.h"


#define kHeaderHeight 30.f
#define kNumberOfSections 1

#define kDefaultCellHeight 88.f
#define kVerticalSpacing 15.f
#define kTableViewOffset 0.f
#define kStationsLabelWidthReducer 90.f
#define kMessagesLabelHeight 25.f

#define kHeaderDestinationTo @"Nach"
#define kHeaderDestinationFrom @"Von"

@interface MBTimetableViewController () <MBTimeTableFilterViewCellDelegate,MBTimetableFilterViewControllerDelegate,MBMapViewDelegate,MBTimeTableViewCellDelegate>

@property (nonatomic, strong) UITableView *timetableView;

@property (nonatomic, strong) NSArray *timetableData;
@property (nonatomic, strong) NSArray *timetableDataByDays;

@property (nonatomic, strong) UIRefreshControl *refreshControl;

@property (nonatomic, strong) MBSwitch *toggleFernverkehrSwitch;

@property (nonatomic, strong) UIImageView* errorImageView;
@property (nonatomic, strong) MBLabel *tableViewMessageLabel;
@property (nonatomic, strong) NSString* availableDataUntilTime;
@property (nonatomic, strong) MBLargeButton *requestMoreButton;
@property (nonatomic, strong) UIActivityIndicatorView *requestMoreProgress;
@property (nonatomic, strong) UIView* tableFooterView;

@property (nonatomic, strong) UIActivityIndicatorView *progressIndicator;

@property(nonatomic,strong) NSString* currentlySelectedPlatform;
@property(nonatomic,strong) NSString* currentlySelectedTransportType;

@property (nonatomic, assign) BOOL makeSmallTableHeader;

@property (nonatomic, assign) CGFloat additionalHeightForExpandedCell;
@property (nonatomic, strong) MBHafasTimetableDataSource *hafasDataSource;

@property(nonatomic,assign) TimetableResponseStatus lastStatus;

@property(nonatomic,strong) MBContentSearchResult* searchresult;
@property (nonatomic,strong) UIButton* mapFloatingBtn;//optional, only active when mapMarkers are present

@property(nonatomic,strong) NSString* stopIdForSelectedVoiceOverCell;

@property(nonatomic) BOOL hasBackToPreviousStation;

@end

@implementation MBTimetableViewController

- (instancetype)initWithFernverkehr:(BOOL)showFernverkehr
{
    self = [super init];
    _showFernverkehr = showFernverkehr;
    self.oepnvOnly = NO;
    self.trackingTitle = TRACK_KEY_TIMETABLE;
    return self;
}
-(instancetype)initWithOPNVAndAllowBack:(BOOL)allowBack{
    self = [super init];
    if(self){
        _showFernverkehr = false;
        self.hasBackToPreviousStation = allowBack;
        self.oepnvOnly = NO;
        self.trackingTitle = TRACK_KEY_TIMETABLE;
    }
    return self;
}

-(instancetype)initWithBackButton:(BOOL)showBackButton fernverkehr:(BOOL)showFernverkehr{
    self = [super initWithBackButton:showBackButton];
    if(self){
        _showFernverkehr = showFernverkehr;
        self.trackingTitle = TRACK_KEY_TIMETABLE;
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    if(self.hafasStation.name && (self.displayHafasTitle || !self.station)){
        self.title = self.hafasStation.name;
    } else if(self.station){
        self.title = self.station.title;
    } else {
        self.title = @"Abfahrt und Ankunft";
    }
    // make sure back button in navigation bar shows only back icon (<)
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:nil];
    if(self.currentlySelectedPlatform == nil){
        self.currentlySelectedPlatform = @"Alle";
        self.currentlySelectedTransportType = @"Alle";
    }
    self.timetableView.alpha = 0; // set default to 0
    
    if (self.oepnvOnly || self.dbOnly) {
        self.timetableView.sectionHeaderHeight = 0.0;
    } else {
        self.timetableView.sectionHeaderHeight = 50.0;
        self.makeSmallTableHeader = NO;
    }
    
    if(self.hasBackToPreviousStation){
        UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        [backButton setBackgroundImage:[UIImage imageNamed:@"ChevronBlackLeft"] forState:UIControlStateNormal];
        backButton.accessibilityLabel = @"Zurück zur vorherigen Station";
        UIBarButtonItem *barBackButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
        [backButton addTarget:self action:@selector(popToPreviousStation) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.leftBarButtonItem = barBackButtonItem;
        self.navigationItem.hidesBackButton = YES;
    }
}

-(void)popToPreviousStation{
    AppDelegate* app = (AppDelegate*) [UIApplication sharedApplication].delegate;
    MBStationSearchViewController* vc = (MBStationSearchViewController*) app.viewController;
    [vc goBackToPreviousStation];
}

- (void) loadView
{
    [super loadView];
    
    //    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    
    self.timetableView = [[UITableView alloc] initWithFrame:CGRectZero];
    self.timetableView.accessibilityIdentifier = @"timetableView";
    [self.timetableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"TimeTableDateHeaderCell"];

    [self.timetableView registerClass:[MBTimeTableViewCell class] forCellReuseIdentifier:@"TimeTableCell"];
    [self.timetableView registerClass:[MBTimeTableFilterViewCell class] forCellReuseIdentifier:@"TimeTableFilterCell"];
    [self.timetableView registerClass:[MBTimeTableOEPNVTableViewCell class] forCellReuseIdentifier:@"TimeTableOEPNVCell"];
    [self.timetableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.timetableView.contentInset = UIEdgeInsetsMake(0, 0.0, 90.0, 0.0);//90 to keep space for map button and a message at the end of the table
    if (self.showFernverkehr) {
        self.timetableView.dataSource = self;
    } else {
        if (nil == self.hafasDataSource) {
            self.hafasDataSource = [MBHafasTimetableDataSource new];
            self.hafasDataSource.cellIdentifier = @"TimeTableOEPNVCell";
            self.hafasDataSource.cellIdentifierHeader = @"TimeTableDateHeaderCell";
            self.hafasDataSource.delegate = self;
            self.hafasDataSource.viewController = self;
            self.hafasDataSource.hafasDepartures = [self.hafasTimetable departureStops];
            self.hafasDataSource.lastRequestedDate = [self.hafasTimetable lastRequestedDate];
        }
        self.timetableView.dataSource = self.hafasDataSource;
    }

    self.timetableView.delegate = self;
    self.timetableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    
    //the UITableViewController just manages the refreshcontrol
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshData) forControlEvents:UIControlEventValueChanged];
    tableViewController.tableView = self.timetableView;
    tableViewController.refreshControl = self.refreshControl;
    
    [self.view addSubview:self.timetableView];
    
    
    if(self.mapMarkers.count > 0 && MBMapViewController.canDisplayMap){
        self.mapFloatingBtn = [[MBMapViewButton alloc] init];
        [self.mapFloatingBtn addTarget:self action:@selector(mapFloatingBtnPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.mapFloatingBtn setSize:CGSizeMake((int)(self.mapFloatingBtn.frame.size.width*AppDelegate.SCALEFACTORFORSCREEN), (int)(self.mapFloatingBtn.frame.size.height*AppDelegate.SCALEFACTORFORSCREEN))];
        [self.view addSubview:self.mapFloatingBtn];
    }
}

-(void)mapFloatingBtnPressed{
    [MBMapConsent.sharedInstance showConsentDialogInViewController:self completion:^{
        MBMapViewController* vc = [MBMapViewController new];
        vc.delegate = self;
        [vc configureWithDelegate];
        MBStationNavigationViewController* nav = [[MBStationNavigationViewController alloc] initWithRootViewController:vc];
        nav.hideEverything = YES;
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [nav setShowRedBar:NO];
        [self presentViewController:nav animated:YES completion:nil];
    }];
}
//map delegate
-(BOOL)mapShouldCenterOnUser{
    return NO;
}
-(BOOL)mapDisplayFilter{
    if(self.mapMarkers){
        return NO;
    }
    return YES;
}

-(MBMarker *)mapSelectedMarker{
    return self.mapMarkers.firstObject;
}

- (NSArray *)mapNearbyStations {
    return self.mapMarkers;
}



- (void)setMakeSmallTableHeader:(BOOL)makeSmallTableHeader
{
    if (makeSmallTableHeader != _makeSmallTableHeader) {
        _makeSmallTableHeader = makeSmallTableHeader;
        if (nil != self.navigationController) {
            if ([self.navigationController isKindOfClass:[MBStationNavigationViewController class]]) {
                [(MBStationNavigationViewController *)self.navigationController hideNavbar:makeSmallTableHeader];
            }
        }
        CGFloat statusHeight = AppDelegate.statusBarHeight;
        if (makeSmallTableHeader) {
            self.timetableView.contentInset = UIEdgeInsetsMake(statusHeight, 0, 0, 0);
        } else {
            self.timetableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        }

        CGFloat newHeight = makeSmallTableHeader ? 39.0 : 50.0;
        [self.timetableView setSectionHeaderHeight:newHeight];
        
        [self.timetableView setNeedsDisplay];
    }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    [scrollView setContentOffset:CGPointZero animated:YES];
    return NO;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    // needs a range to find out if table header needs to be big or small
    // do not change header in case of ÖPNV only
    if(self.oepnvOnly || self.dbOnly){
        //no change
    } else {
        // only handle small/large header if table view is a good deal bigger than the view
        if (scrollView.contentSize.height > self.view.frame.size.height + 2*kDefaultCellHeight) {
            CGFloat y = scrollView.contentOffset.y;
            CGFloat navHeight = self.navigationController.navigationBar.frame.size.height;
            if (self.makeSmallTableHeader == NO && scrollView.contentOffset.y > kDefaultCellHeight+30){
                self.makeSmallTableHeader = YES;
                [scrollView setContentOffset:CGPointMake(0, y-11-navHeight)];
            } else if (self.makeSmallTableHeader == YES && scrollView.contentOffset.y < -20) {
                self.makeSmallTableHeader = NO;
                [scrollView setContentOffset:CGPointMake(0, y+11+navHeight)];
            }
        }
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [MBTrackingManager trackActionsWithStationInfo:@[@"h2", @"list", @"departure", @"scroll"]];
}
-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if(!decelerate){
        [MBTrackingManager trackActionsWithStationInfo:@[@"h2", @"list", @"departure", @"scroll"]];
    }
}


- (void)setHafasStation:(MBOPNVStation *)hafasStation {
    _hafasStation = hafasStation;
    if(self.displayHafasTitle || !self.station){
        self.title = hafasStation.name;
    }
}

- (void) refreshData
{
    if (self.oepnvOnly) {
        [[HafasRequestManager sharedManager] manualRefresh:self.hafasTimetable withCompletion:^(HafasTimetable *timetable) {
            self.hafasTimetable = timetable;
            [self handleTimetableUpdate];
        }];
    } else {
        if (self.showFernverkehr) {
            TimetableManager *manager = [TimetableManager sharedManager];
            [manager manualRefresh];
        } else {
            [[HafasRequestManager sharedManager] manualRefresh:self.hafasTimetable withCompletion:^(HafasTimetable *timetable) {
                self.hafasTimetable = timetable;
                [self handleTimetableUpdate];
            }];
        }
    }
}

- (void) setLoading:(BOOL)loading
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.progressIndicator) {
            self.progressIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
            self.progressIndicator.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
            self.progressIndicator.center = self.view.center;
        }
        
        if (loading) {
            self.timetableView.alpha = 0;
            [self.view addSubview:self.progressIndicator];
            [self.progressIndicator startAnimating];
        } else {
            [self.progressIndicator removeFromSuperview];
            self.timetableView.alpha = 1;
        }
    });
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[MBTutorialManager singleton] hideTutorials];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIF_TIMETABLE_UPDATE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIF_TIMETABLE_REFRESHING object:nil];
    
}

-(void)dealloc{
    NSLog(@"dealloc MBTimetableViewController");
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void) didReceiveTimetableUpdate:(NSNotification*)notification
{
    NSLog(@"Handle update, %@",notification);
    id manager = notification.object;
    if (self.oepnvOnly || !self.showFernverkehr) {
        //this should never be called (old code)
        if(![manager isKindOfClass:[HafasRequestManager class]]){
            return;
        }
    } else {
        if(manager != [TimetableManager sharedManager]){
            return;//FIX for some other manager posting notifications that we don't want here
        }
    }
    [self performSelectorOnMainThread:@selector(handleTimetableUpdate) withObject:nil waitUntilDone:YES];
}

- (void) didReceiveRefreshingUpdate:(NSNotification*)notification
{
    TimetableManager *manager = (TimetableManager *)notification.object;
    if(manager != [TimetableManager sharedManager]){
        return;//FIX for some other manager posting notifications that we don't want here
    }
    [self setLoading:([manager timetableStatus] == TimetableStatusBusy)];
}

#pragma mark TimeTableFilterCellDelegate
- (void)filterCell:(MBTimeTableFilterViewCell *)cell setsAbfahrt:(BOOL)abfahrt
{
    [MBTrackingManager trackActionsWithStationInfo:@[@"h2", @"tap", abfahrt ? @"toggle_abfahrt" : @"toggle_ankunft"]];

    self.departure = abfahrt;
    [self handleTimetableUpdate];
}

- (void)filterCellWantsToFilter
{
    [self showFilterView];
}

- (void) handleTimetableUpdate
{
    NSLog(@"handleTimetableUpdate with %d,%d",self.oepnvOnly,!self.showFernverkehr);
    if (self.oepnvOnly || !self.showFernverkehr) {
        
        if(!self.hafasTimetable){
            self.hafasTimetable = [[HafasTimetable alloc] init];
            self.hafasTimetable.needsInitialRequest = YES;
        }
        self.hafasTimetable.includeLongDistanceTrains = self.includeLongDistanceTrains;
        if(self.hafasTimetable.needsInitialRequest){
            self.hafasTimetable.needsInitialRequest = NO;
            NSLog(@"load hafas %@",self.hafasStation.stationId);
            [[HafasRequestManager sharedManager] loadDeparturesForStopId:self.hafasStation.stationId
                                                                     timetable:self.hafasTimetable
                                                                withCompletion:^(HafasTimetable *timetable) {
                                                                    self.hafasTimetable = timetable;
                                                                    [self handleTimetableUpdate];
                                                                }];
        }
        
        MBHafasTimetableDataSource *dataSource = (MBHafasTimetableDataSource *)[self.timetableView dataSource];
        NSArray<HafasDeparture*> *departureStops = [self.hafasTimetable departureStops];
        // handle ÖPNV here
        dataSource.lastRequestedDate = [self.hafasTimetable lastRequestedDate];
        [dataSource setHafasDepartures:departureStops];

        if (departureStops.count == 0) {
            // [dataSource setHafasDepartures:@[]];
        
            BOOL isLoading = self.hafasTimetable.isBusy;
            [self setLoading:isLoading];
            if (!isLoading) {
                [self updateEmptyView: self.hafasTimetable.hasError ? TimetableResponseStatus_ERROR : TimetableResponseStatus_EMPTY];
            }

        } else {
            // [dataSource setHafasDepartures:departureStops];
            [self filterByPlatformAndTransportType];
            [self setLoading:NO];
            
            if(self.searchresult && self.searchresult.isOPNVSearch){
                [self runSearchResultStep2:self.searchresult];
                self.searchresult = nil;
            }
        }
    } else {
        Timetable *timetable = [[TimetableManager sharedManager] timetable];
        TimetableManager *manager = [TimetableManager sharedManager];

        if (![timetable hasTimetableData]) {
            // empty
            self.timetableData = @[];
            BOOL isTimetableStillLoading = [manager timetableStatus] == TimetableStatusBusy;
            if (isTimetableStillLoading) {
                [self setLoading:YES];
            } else {
                if(manager.hasLoadingError){
                    [self updateEmptyView:TimetableResponseStatus_ERROR];
                } else {
                    [self updateEmptyView:TimetableResponseStatus_EMPTY];
                }
                [self setLoading:NO];
            }
        } else {
            // async
            if (self.departure) {
                self.timetableData = timetable.departureStops;
            } else {
                self.timetableData = timetable.arrivalStops;
            }
            [self filterByPlatformAndTransportType];
            [self setLoading:NO];
        }
    }
    
    [self.refreshControl endRefreshing];
    if (!self.oepnvOnly && self.showFernverkehr) {
        NSString* voiceOverStop = self.stopIdForSelectedVoiceOverCell;
        if(voiceOverStop){
            //ensure that we keep the focus on this train after a refresh of the tableview
            NSLog(@"find stop in refreshed data: %@",voiceOverStop);
            NSInteger index = 1;//the first cell is the "filter cell"
            BOOL found = false;
            for(Stop* stop in self.timetableDataByDays){
                if([stop isKindOfClass:Stop.class] && [stop.stopId isEqualToString:voiceOverStop]){
                    found = true;
                    break;
                } else {
                    index++;
                }
            }
            if(!found){
                index = 0;
            }
            NSLog(@"found stop at index %ld",(long)index);
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            [CATransaction begin];
            //after reloadData execute the scrolling and refocusing of voiceover
            [CATransaction setCompletionBlock:^{
                //the index path might be outside of the visible area, scroll it into visible view
                [self.timetableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
                UITableViewCell* cell = [self.timetableView cellForRowAtIndexPath:indexPath];
                if(cell){
                    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, cell);
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UITableViewCell* cell = [self.timetableView cellForRowAtIndexPath:indexPath];
                        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, cell);
                    });
                }
            }];
            [self.timetableView reloadData];
            [CATransaction commit];
            return;
        }        
    }
    [self.timetableView reloadData];
}

-(void)cellWasSelectedViaVoiceOver:(MBTimeTableViewCell *)cell{
    self.stopIdForSelectedVoiceOverCell = cell.stopId;
    //NSLog(@"selected DB %@",self.stopIdForSelectedVoiceOverCell);
}
- (void)cellWasDeselectedViaVoiceOver:(MBTimeTableViewCell *)cell{
    if(self.stopIdForSelectedVoiceOverCell && [cell.stopId isEqualToString:self.stopIdForSelectedVoiceOverCell]){
        self.stopIdForSelectedVoiceOverCell = nil;
    }
}
-(MBStation *)stationForEvents{
    if(self.hafasStation){
        return nil;
    }
    return self.station;
}

-(void)setTimetableData:(NSArray *)timetableData{
    _timetableData = timetableData;
    if(timetableData.count > 0){
        //NOTE: timetableDataByDays is filled with Stop and NSString objects (header strings)
        NSMutableArray* entriesByDate = [NSMutableArray arrayWithCapacity:timetableData.count+2];
        NSInteger index = 0;
        for(Stop* stop in timetableData){
            if(entriesByDate.count == 0){
                //first one
                [entriesByDate addObject:stop];
            } else {
                Event *event = [stop eventForDeparture:self.departure];
                Stop* previousStop = timetableData[index-1];
                Event *previousEvent = [previousStop eventForDeparture:self.departure];
                if([event sameDayEvent:previousEvent]){
                    [entriesByDate addObject:stop];
                } else {
                    //day changed
                    NSDate* date = [NSDate dateWithTimeIntervalSince1970:event.timestamp];
                    NSDateFormatter* df = [[NSDateFormatter alloc] init];
                    [df setDateFormat:@"dd. MMMM"];
                    NSString* dateString = [df stringFromDate:date];
                    [entriesByDate addObject:dateString];
                    [entriesByDate addObject:stop];
                }
            }
            index++;
        }
        self.timetableDataByDays = entriesByDate;
        
    } else {
        self.timetableDataByDays = @[];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self.navigationController isKindOfClass:[MBStationNavigationViewController class]]) {
        [(MBStationNavigationViewController *)self.navigationController hideNavbar:self.makeSmallTableHeader];
        [(MBStationNavigationViewController *)self.navigationController setShowRedBar:(self.oepnvOnly || self.dbOnly)];
        [(MBStationNavigationViewController *)self.navigationController setHideEverything:NO];
    }
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveTimetableUpdate:)
                                                 name:NOTIF_TIMETABLE_UPDATE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveRefreshingUpdate:)
                                                 name:NOTIF_TIMETABLE_REFRESHING object:nil];
    
    
    [self handleTimetableUpdate];
    
    if(self.showFernverkehr){
        [[MBTutorialManager singleton] displayTutorialIfNecessary:MBTutorialViewType_H2_Departure withOffset:0];
        if(self.station.platformAccessibility.count > 0 && MBStation.displayPlaformInfo){
            [MBTutorialManager.singleton displayTutorialIfNecessary:MBTutorialViewType_H2_Platform_info withOffset:0];
        }
    }
    
}

-(void)restoreATrainJourney{
    AppDelegate* app = (AppDelegate*) [UIApplication sharedApplication].delegate;
    MBStationSearchViewController* vc = (MBStationSearchViewController*) app.viewController;
    if(vc.trainJourneyToRestore){
        NSLog(@"restore a train journey %@",vc.trainJourneyToRestore);
        self.departure = vc.trainJourneyToRestore.isFromDeparture;
        if(!self.departure){
            [self updateFilterCellWithDepatureState];
        }
        Stop* stop = vc.trainJourneyToRestore.stop;
        if(stop){
            [self showJourneyForStop:stop showIrisOnFailure:false animated:false];
        } else {
            if(!self.hafasStation.stationId){
                self.hafasStation = vc.trainJourneyToRestore.hafasStation;
            }
            self.showFernverkehr = false;
            HafasDeparture* h = vc.trainJourneyToRestore.hafasDeparture;
            if(h){
                NSLog(@"hafas departure from %@, %@",h.stopid,h.name);
                [self showJourneyForHafasDeparture:h animated:false];
            }
        }
        vc.trainJourneyToRestore = nil;
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.embeddedInController) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    } else {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }

    [MBTrackingManager trackStateWithStationInfo:@"h2"];
    
    if(self.trackToggleChange){
        if (self.showFernverkehr) {
            [MBTrackingManager trackActionsWithStationInfo:@[@"h2", @"tap", @"toggle_db"]];
        } else {
            [MBTrackingManager trackActionsWithStationInfo:@[@"h2", @"tap", @"toggle_oepnv"]];
        }
    }
    
    if(self.searchresult){
        [self runSearchResult:self.searchresult];
        if(self.searchresult.isOPNVSearch){
            //for opnv the searchresult is not niled, needed later to select the correct train
        } else {
            self.searchresult = nil;
        }
    }

    [self restoreATrainJourney];
}

- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.timetableView.frame = self.view.bounds;
    self.timetableView.backgroundColor = [UIColor db_f0f3f5];
    
    [self updateEmptyView:self.lastStatus];
    
    [self.mapFloatingBtn setGravityRight:10];
    CGFloat bottomSafeOffset = self.view.safeAreaInsets.bottom;
    [self.mapFloatingBtn setGravityBottom:15+bottomSafeOffset];

}

- (void) reloadTimetable
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
        [self.timetableView reloadData];
    });
}

-(void)requestMorePressed:(id)sender{
    if(![self canRequestAdditionalData]){
        return;
    }
    //Hafas or DB?
    if(self.timetableView.dataSource == self){
        TimetableManager *manager = [TimetableManager sharedManager];
        [manager requestAdditionalData];
    } else {
        [self hafasRequestAdditionalData];
    }
    self.requestMoreButton.hidden = YES;
    [self.requestMoreProgress startAnimating];
}
-(BOOL)canRequestAdditionalData{
    //Hafas or DB?
    if(self.timetableView.dataSource == self){
        TimetableManager *manager = [TimetableManager sharedManager];
        return manager.canRequestAdditionalData;
    } else {
        return self.hafasTimetable.requestDuration < 12*60;//allow no more than 12h in the future
    }
}
-(void)hafasRequestAdditionalData{
    if([self canRequestAdditionalData]){
        self.hafasTimetable.requestDuration += 60;
        [[HafasRequestManager sharedManager] manualRefresh:self.hafasTimetable withCompletion:^(HafasTimetable *timetable) {
            self.hafasTimetable = timetable;
            [self handleTimetableUpdate];
        }];
    }
}

- (void) updateEmptyView:(TimetableResponseStatus)reason
{
    self.lastStatus = reason;
    if (!self.tableViewMessageLabel) {
        self.tableViewMessageLabel = [[MBLabel alloc] initWithFrame:CGRectMake(0, 0,
                                                                               self.timetableView.bounds.size.width,
                                                                               self.timetableView.bounds.size.height)];
        self.tableViewMessageLabel.textAlignment = NSTextAlignmentCenter;
        self.tableViewMessageLabel.font = [UIFont db_RegularFourteen];
        self.tableViewMessageLabel.textColor = [UIColor db_646973];
        self.tableViewMessageLabel.numberOfLines = 0;
    }
    if(!self.errorImageView){
        self.errorImageView = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_error"]];
        self.errorImageView.isAccessibilityElement = false;
        self.errorImageView.hidden = true;
    }
    if(!self.requestMoreButton){
        self.requestMoreButton = [[MBLargeButton alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width-2*16, 60)];
        [self.requestMoreButton setTitle:@"Später" forState:UIControlStateNormal];
        [self.requestMoreButton addTarget:self action:@selector(requestMorePressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    if(!self.requestMoreProgress){
        self.requestMoreProgress = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        self.requestMoreProgress.hidesWhenStopped = YES;
        [self.requestMoreProgress stopAnimating];
    }
    if(!self.tableFooterView){
        self.tableFooterView = [[UIView alloc] init];
        self.tableFooterView.backgroundColor = [UIColor clearColor];
        [self.tableFooterView addSubview:self.tableViewMessageLabel];
        [self.tableFooterView addSubview:self.errorImageView];
        [self.tableFooterView addSubview:self.requestMoreButton];
        [self.tableFooterView addSubview:self.requestMoreProgress];
    }
    
    NSMutableString* message = [[NSMutableString alloc] initWithCapacity:100];
    [message appendString:@"Keine "];
    //do we have entries?
    BOOL hasEntry = [self.timetableView.dataSource tableView:self.timetableView numberOfRowsInSection:0] > 1;//>1 because the first cell is not a train, it's the filter-cell
    if(hasEntry){
        [message appendString:@"weitere "];
    }
    if(self.departure || !self.showFernverkehr){
        [message appendString:@"Abfahrt "];
    } else {
        [message appendString:@"Ankunft "];
    }
    if(self.currentlySelectedTransportType && ![self.currentlySelectedTransportType isEqualToString:@"Alle"]){
        [message appendString:@"des Verkehrsmittels "];
        [message appendString:self.currentlySelectedTransportType];
        [message appendString:@" "];
    }
    NSDate* date = nil;
    if(self.timetableView.dataSource == self){
        TimetableManager *manager = [TimetableManager sharedManager];
        date = manager.timetable.lastRequestedDate;
    } else {
        date = self.hafasDataSource.lastRequestedDate;
    }
    if(date){
        NSString* formatedTime = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
        self.availableDataUntilTime = [NSString stringWithFormat:@"bis %@ Uhr",formatedTime];
        [message appendString:self.availableDataUntilTime];
    } else {
        self.availableDataUntilTime = nil;
    }
    if(self.currentlySelectedPlatform && ![self.currentlySelectedPlatform isEqualToString:@"Alle"]){
        [message appendString:@" an Gleis "];
        [message appendString:self.currentlySelectedPlatform];
    }
    [message appendString:@"."];
    NSString *errorMessage = message;
    self.errorImageView.hidden = true;

    if(reason == TimetableResponseStatus_ERROR){
        errorMessage = @"Daten nicht verfügbar.";
        self.errorImageView.hidden = false;
    }
    self.tableViewMessageLabel.text = errorMessage;

    CGSize textSize = [self.tableViewMessageLabel sizeThatFits:CGSizeMake(self.timetableView.sizeWidth-2*16, 1024)];
    self.tableViewMessageLabel.size = textSize;
    //increase height to add some spacing around the label
    CGRect f = self.tableViewMessageLabel.frame;
    f.size.height += 20;
    self.tableViewMessageLabel.frame = f;
    
    [self.requestMoreProgress stopAnimating];
    BOOL canRequestAdditionalData = [self canRequestAdditionalData];
    if(canRequestAdditionalData && hasEntry){
        //show only request more button
        self.requestMoreButton.hidden = NO;
        /*
        self.tableViewMessageLabel.hidden = YES;
        [self.requestMoreButton setGravityTop:16];
        self.tableFooterView.frame = CGRectMake(0, 0, self.timetableView.sizeWidth, CGRectGetMaxY(self.requestMoreButton.frame)+16);
         */
        self.tableViewMessageLabel.hidden = NO;
        [self.requestMoreButton setBelow:self.tableViewMessageLabel withPadding:16];
        self.tableFooterView.frame = CGRectMake(0, 0, self.timetableView.sizeWidth, CGRectGetMaxY(self.requestMoreButton.frame)+16);

    } else if(canRequestAdditionalData && !hasEntry && reason != TimetableResponseStatus_ERROR) {
        //show both!
        self.requestMoreButton.hidden = NO;
        self.tableViewMessageLabel.hidden = NO;
        [self.requestMoreButton setBelow:self.tableViewMessageLabel withPadding:16];
        self.tableFooterView.frame = CGRectMake(0, 0, self.timetableView.sizeWidth, CGRectGetMaxY(self.requestMoreButton.frame)+16);
    } else {
        //no additional data, show only text
        self.requestMoreButton.hidden = YES;
        self.tableViewMessageLabel.hidden = NO;
        self.tableFooterView.frame = CGRectMake(0, 0, self.timetableView.sizeWidth, CGRectGetMaxY(self.tableViewMessageLabel.frame)+10);
    }
    [self.requestMoreProgress centerViewHorizontalInSuperView];
    [self.requestMoreProgress setGravityTop:self.requestMoreButton.frame.origin.y];
    [self.tableViewMessageLabel centerViewHorizontalInSuperView];
    [self.errorImageView setLeft:self.tableViewMessageLabel withPadding:10];
    [self.errorImageView centerViewVerticalWithView:self.tableViewMessageLabel];
    self.timetableView.tableFooterView = self.tableFooterView;
    //self.timetableView.tableFooterView = self.tableViewMessageLabel;
    /*
    if(hasEntry){
        self.timetableView.tableFooterView = self.tableViewMessageLabel;
    } else {
        self.timetableView.backgroundView = self.tableViewMessageLabel;
    }*/
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.timetableDataByDays.count +1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumberOfSections;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    return self.makeSmallTableHeader ? 39.0 : 50.0;
//}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if(self.oepnvOnly || self.dbOnly){
        return nil;
    } else {
        if(section == 0){
            CGFloat heigth = self.makeSmallTableHeader ? 39.0 : 50.0;
            MBSwitch *header = [[MBSwitch alloc] initWithFrame:CGRectMake(0, 0.0, tableView.frame.size.width, heigth) onTitle:@"Bahnhof" offTitle:@"ÖPNV" onState:self.showFernverkehr];
            [header addTarget:self action:@selector(toggleList:) forControlEvents:UIControlEventValueChanged];
            header.noShadow = YES;
            header.noRoundedCorners = YES;
            header.activeLabelFont = [UIFont db_BoldTwenty];
            header.inActiveLabelFont = [UIFont db_RegularTwenty];
            header.activeTextColor = [UIColor db_333333];
            header.inActiveTextColor = [UIColor db_dadada];
            header.backgroundColor = [UIColor whiteColor];
            //header.on = YES;
            self.toggleFernverkehrSwitch = header;
            return header;
        } else {
            return nil;
        }
    }
}

- (void) toggleList:(MBSwitch *)sender {
    self.showFernverkehr = sender.on;
    if (self.showFernverkehr) {
        [MBTrackingManager trackActionsWithStationInfo:@[@"h2", @"tap", @"toggle_db"]];
    } else {
        [MBTrackingManager trackActionsWithStationInfo:@[@"h2", @"tap", @"toggle_oepnv"]];
    }
}

- (void)setShowFernverkehr:(BOOL)showFernverkehr {
    if(_showFernverkehr != showFernverkehr){
        //on change reset filter
        self.currentlySelectedPlatform = @"Alle";
        self.currentlySelectedTransportType = @"Alle";
    }
    _showFernverkehr = showFernverkehr;
    if (self.toggleFernverkehrSwitch.on != showFernverkehr) {
        [self.toggleFernverkehrSwitch setOn:showFernverkehr];
    }
    if (showFernverkehr) {
        self.timetableView.dataSource = self;
    } else {
        if (nil == self.hafasDataSource) {
            self.hafasDataSource = [MBHafasTimetableDataSource new];
            self.hafasDataSource.cellIdentifier = @"TimeTableOEPNVCell";
            self.hafasDataSource.cellIdentifierHeader = @"TimeTableDateHeaderCell";
            self.hafasDataSource.delegate = self;
            self.hafasDataSource.viewController = self;
            self.hafasDataSource.hafasDepartures = [self.hafasTimetable departureStops];
            self.hafasDataSource.lastRequestedDate = [self.hafasTimetable lastRequestedDate];
        }
        self.timetableView.dataSource = self.hafasDataSource;
    }
    [self handleTimetableUpdate];
    
    if(showFernverkehr && self.departure){
        //ensure that switch has correct state
        MBTimeTableFilterViewCell *tableCell = [self.timetableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        [tableCell switchToDeparture];
    }

}

- (void) showFilterView
{
    [MBTrackingManager trackActionsWithStationInfo:@[@"h2", @"tap", @"filter_button"]];
    
    MBTimetableFilterViewController* filterView = [MBTimetableFilterViewController new];
    filterView.availableDataUntilTime = self.availableDataUntilTime;
    filterView.hafasTimetable = self.hafasTimetable;
    filterView.useHafas = !self.showFernverkehr || self.oepnvOnly;
    filterView.delegate = self;
    filterView.departure = self.departure;
    filterView.initialSelectedTransportType = self.currentlySelectedTransportType;
    filterView.initialSelectedPlatform = self.currentlySelectedPlatform;
    [MBRootContainerViewController presentViewControllerAsOverlay:filterView];
}

-(void)filterView:(MBTimetableFilterViewController *)filterView didSelectTrainType:(NSString *)type track:(NSString *)track{
    if(!track){
        track = @"Alle";//FIX for OEPNV
    }
    self.currentlySelectedPlatform = track;
    self.currentlySelectedTransportType = type;
    [self filterByPlatformAndTransportType];
}

-(void)showTrack:(NSString *)track trainOrder:(Stop *)trainStop{
    //we only show DB-trains and only depature!
    
    self.departure = YES;
    if(!self.showFernverkehr){
        self.showFernverkehr = YES;
    }
    self.currentlySelectedPlatform = track;
    self.currentlySelectedTransportType = @"Alle";
    MBTimeTableFilterViewCell *tableCell = [self.timetableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [tableCell switchToDeparture];
    [self handleTimetableUpdate];
    if(trainStop){
        //is this stop in our list?
        NSInteger index = [self.timetableData indexOfObject:trainStop];
        if(index != NSNotFound){
            [self showTrainOrderForStop:trainStop];
        }
    }
}

-(void)showTrainOrderForStop:(Stop*)stop{
    MBTrainOrderDisplayHelper* helper = [MBTrainOrderDisplayHelper new];
    [helper showWagenstandForStop:stop station:self.station departure:self.departure inViewController:self];
}

-(BOOL)filterIsActive{
    return ![self.currentlySelectedPlatform isEqualToString:@"Alle"]
    || ![self.currentlySelectedTransportType isEqualToString:@"Alle"];

}

-(void)filterByPlatformAndTransportType
{
    if (self.oepnvOnly || !self.showFernverkehr) {
        [self filterByTransportType:self.currentlySelectedTransportType];
    } else {
        [self filterByPlatform:[self currentlySelectedPlatform] andTransportType:[self currentlySelectedTransportType]];
    }
}

/// filter for ÖPNV
- (void)filterByTransportType:(NSString *)transport {
    NSArray *departuresToFilter = [self.hafasTimetable departureStops];
    if ([transport isEqualToString:@"Alle"]) {
        [(MBHafasTimetableDataSource *)[self.timetableView dataSource] setHafasDepartures:departuresToFilter];
        [self updateEmptyView:TimetableResponseStatus_SUCCESS];
    } else {
        // filter
        NSArray *filteredDeps = [departuresToFilter filteredArrayUsingPredicate:
                                 [NSPredicate predicateWithBlock:^BOOL(HafasDeparture *evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            NSString* trainCat = [HafasDeparture stringForCat:evaluatedObject.productCategory]; //[[evaluatedObject valueForKey:@"trainCategory"] uppercaseString];
            if ([trainCat isEqualToString:transport]) {
                return YES;
            }
            return NO;
        }]];
        [(MBHafasTimetableDataSource *)[self.timetableView dataSource] setHafasDepartures:filteredDeps];

        if(filteredDeps.count == 0){
            [self updateEmptyView:TimetableResponseStatus_FILTER_EMPTY];
        } else {
            [self updateEmptyView:TimetableResponseStatus_SUCCESS];
        }
    }
    [self.timetableView reloadData];
}

- (void) filterByPlatform:(NSString*)platform andTransportType:(NSString*)transport
{
    TimetableManager *manager = [TimetableManager sharedManager];
    if (self.oepnvOnly) {
        // no filter for ÖPNV
    }
    NSArray *dataToFilter;
    if (self.departure) {
        dataToFilter = [[manager timetable] departureStops];
    } else {
        dataToFilter = [[manager timetable] arrivalStops];
    }
    
    if ([platform isEqualToString:@"Alle"] && [transport isEqualToString:@"Alle"]) {
        self.timetableData = dataToFilter;
        [self updateEmptyView:TimetableResponseStatus_SUCCESS];
    } else {
        // filter
        self.timetableData = [dataToFilter filteredArrayUsingPredicate:
                              [NSPredicate predicateWithBlock:^BOOL(Stop *evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            Event *event = [evaluatedObject eventForDeparture:self.departure];
            
            if (([platform isEqualToString:@"Alle"] || [event.actualPlatformNumberOnly isEqualToString:platform] || [event.actualPlatform isEqualToString:platform]) && ([transport isEqualToString:@"Alle"] || [evaluatedObject.transportCategory.transportCategoryType isEqualToString:transport])) {
                return YES;
            }
            return NO;
            
        }]];
        if(self.timetableData.count == 0){
            [self updateEmptyView:TimetableResponseStatus_FILTER_EMPTY];
        } else {
            [self updateEmptyView:TimetableResponseStatus_SUCCESS];
        }
    }
    [self.timetableView reloadData];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger actualIndex = indexPath.row;
    if(indexPath.section == 0 && indexPath.row > 0){
        actualIndex--;
    }
    id item = nil;
    if(self.showFernverkehr){
        if(actualIndex >= 0 && actualIndex < self.timetableDataByDays.count){
            item = self.timetableDataByDays[actualIndex];
        }
    } else {
        if(actualIndex >= 0 && actualIndex < self.hafasDataSource.hafasDeparturesByDay.count){
            item = self.hafasDataSource.hafasDeparturesByDay[actualIndex];
        }
    }
    if([item isKindOfClass:NSString.class]){
        cell.backgroundColor = [UIColor clearColor];
    }}
-(BOOL)tableView:(UITableView *)tableView canFocusRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger actualIndex = indexPath.row;
    if(indexPath.section == 0 && indexPath.row > 0){
        actualIndex--;
    }
    id item = nil;
    if(self.showFernverkehr){
        if(actualIndex >= 0 && actualIndex < self.timetableDataByDays.count){
            item = self.timetableDataByDays[actualIndex];
        }
    } else {
        if(actualIndex >= 0 && actualIndex < self.hafasDataSource.hafasDeparturesByDay.count){
            item = self.hafasDataSource.hafasDeparturesByDay[actualIndex];
        }
    }
    if([item isKindOfClass:NSString.class]){
        return NO;
    }
    return YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (indexPath.section == 0 && indexPath.row == 0) {
        // filter cell
        MBTimeTableFilterViewCell *tableCell = [tableView dequeueReusableCellWithIdentifier:@"TimeTableFilterCell" forIndexPath:indexPath];
        tableCell.delegate = self;
        tableCell.filterOnly = self.oepnvOnly;
        tableCell.filterActive = [self filterIsActive];
        [tableCell setFilterHidden:NO];
        if(self.departure){
            [tableCell switchToDeparture];
        }
        return tableCell;
    } else {
        NSInteger actualIndex = indexPath.row;
        if(indexPath.section == 0){
            actualIndex--;
        }
        id item = self.timetableDataByDays[actualIndex];
        if([item isKindOfClass:NSString.class]){
            //this is a "header"
            UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"TimeTableDateHeaderCell" forIndexPath:indexPath];
            cell.textLabel.font = [UIFont db_BoldSixteen];
            cell.textLabel.textColor = [UIColor db_333333];
            cell.textLabel.text = item;
            return cell;
        }
        
        Stop *timetableStop = item;
        Event *event = [timetableStop eventForDeparture:self.departure];
        
        if (self.oepnvOnly) {
            
            //never used! The cell is provided by another data source!!!!!
            return [tableView dequeueReusableCellWithIdentifier:@"ThisIsNeverUsed" forIndexPath:indexPath];
            
        } else {
            // other cells
            MBTimeTableViewCell *tableCell = [tableView dequeueReusableCellWithIdentifier:@"TimeTableCell" forIndexPath:indexPath];
            tableCell.selectionStyle = UITableViewCellSelectionStyleNone;
            tableCell.autoresizingMask = UIViewAutoresizingFlexibleHeight;
            tableCell.clipsToBounds = YES;
            tableCell.delegate = self;
            tableCell.stopId = timetableStop.stopId;
            tableCell.currentStation = self.station.title;
            tableCell.event = event;
            tableCell.timeLabel.text = event.formattedTime;
            tableCell.stationLabel.text = event.actualStation;
            NSString* trainCat = [timetableStop formattedTransportType:event.lineIdentifier];
            tableCell.trainLabel.text = trainCat;
            tableCell.platformLabel.text = [NSString stringWithFormat:@"Gl. %@",event.actualPlatform];
            if(event.changedPlatform){
                tableCell.platformLabel.textColor = [UIColor db_mainColor];
            } else {
                tableCell.platformLabel.textColor = [UIColor db_787d87];
            }
            //tableCell.platformTrainLabel.accessibilityLabel = [tableCell.platformTrainLabel.text stringByReplacingOccurrencesOfString:@"Gl." withString:@"Gleis"];
                        
            tableCell.expectedTimeLabel.text = event.formattedExpectedTime;
            if([event roundedDelay] >= 5){
                tableCell.expectedTimeLabel.textColor = [UIColor db_mainColor];
            } else {
                tableCell.expectedTimeLabel.textColor = [UIColor db_green];
            }
            //hide time when train is canceled
            tableCell.expectedTimeLabel.hidden = event.eventIsCanceled;

            NSAttributedString *finalMessage = [self attributedIrisMessage:event.composedIrisMessage forTrain:trainCat];
            if (event.composedIrisMessage.length > 0) {
//                tableCell.messageTextLabel.attributedText = finalMessage;
            }
            
            event.composedIrisMessageAttributed = finalMessage;
            
            // show additional container if we composed a message
            tableCell.messageIcon.hidden = event.composedIrisMessage.length == 0;
            if(!tableCell.messageIcon.hidden){
                //what icon do we need?
                if(event.hasOnlySplitMessage){
                    tableCell.messageIcon.image = [UIImage db_imageNamed:@"app_warndreieck_dunkelgrau"];
                } else {
                    tableCell.messageIcon.image = [UIImage db_imageNamed:@"app_warndreieck"];
                    if(event.shouldShowRedWarnIcon){
                        tableCell.messageIcon.hidden = NO;
                    } else {
                        tableCell.messageIcon.hidden = YES;
                    }
                }
            }
            
            return tableCell;
        }
    }
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.showFernverkehr) {
        if ((indexPath.section == 0 && indexPath.row > 0) || indexPath.section > 0) {
            [[MBTutorialManager singleton] markTutorialAsObsolete:MBTutorialViewType_H2_Departure];
            
                [MBTrackingManager trackActionsWithStationInfo:@[@"h2", @"tap", @"verbindung_auswahl"]];
                NSInteger actualIndex = indexPath.row;
                if(indexPath.section == 0){
                    actualIndex--;
                }
                if(actualIndex < self.timetableDataByDays.count && actualIndex >= 0){
                    id item = self.timetableDataByDays[actualIndex];
                    if([item isKindOfClass:NSString.class]){
                        return;
                    }
                    Stop *stop = item;
                    [self showJourneyForStop:stop];
                }
            
        }
    } else {
        self.additionalHeightForExpandedCell = 92;//for OEPNV this is fix (thank god) we only need a fixed space for the stop locations
        //NSLog(@"hafas: %@", [[self.hafasDataSource.hafasDepartures objectAtIndex:indexPath.row] description]);
        if(indexPath.row > 0){
            if(indexPath.row-1 < self.hafasDataSource.hafasDeparturesByDay.count){
                [MBTrackingManager trackActionsWithStationInfo:@[@"h2", @"tap", @"verbindung_auswahl"]];
                NSInteger actualIndex = indexPath.row - 1;
                HafasDeparture* departure = self.hafasDataSource.hafasDeparturesByDay[actualIndex];
                if([departure isKindOfClass:NSString.class]){
                    [self.timetableView reloadData];
                    return;
                }
                [self showJourneyForHafasDeparture:departure];
            }
        }
    }
}

- (void) scrollCellIntoViewportAtIndexPath:(NSIndexPath* )indexPath dataSource:(id<UITableViewDataSource>)source
{
    //note: this method is not thread safe and sometimes crashes with "Attempted to scroll the table view to an out-of-bounds row"
    if(indexPath.row >= [source tableView:self.timetableView numberOfRowsInSection:0]){
        //this can happen when the table view is updated while a wagenstand is loaded
        return;
    }
    CGRect cellRect = [self.timetableView rectForRowAtIndexPath:indexPath];
    CGRect tableRect = self.timetableView.frame;
    CGFloat headerHeight = self.timetableView.sectionHeaderHeight + self.navigationController.navigationBar.frame.size.height + self.timetableView.contentOffset.y;
    tableRect.size.height -= headerHeight;
    tableRect.origin.y += headerHeight;
    BOOL completelyVisible = CGRectContainsRect(tableRect, cellRect);
    if (!completelyVisible) {
        [self.timetableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
    }
}
-(void)showJourneyForHafasDeparture:(HafasDeparture*)departure{
    [self showJourneyForHafasDeparture:departure animated:true];
}
-(void)showJourneyForHafasDeparture:(HafasDeparture*)departure animated:(BOOL)animated{
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    [[HafasRequestManager sharedManager] requestJourneyDetails:departure forceReload:false completion:^(HafasDeparture * dep, NSError * err) {
        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
        if(!dep){
            [self showJourneyAlert];
            return;
        }

        MBTrainJourneyViewController* detailViewController = [MBTrainJourneyViewController new];
        detailViewController.timetableOpenedFromOPNVOverlay = self.timetableOpenedFromOPNVOverlay;
        detailViewController.departure = true;
        NSString* stationEva = departure.stopExtId;
        if(!stationEva){
            stationEva = @"0";
        }
        MBStation* station = [[MBStation alloc] initWithId:@(stationEva.longLongValue) name:self.hafasStation.name evaIds:@[stationEva] location:nil];
        detailViewController.hafasStationThatOpenedThisJourney = station;
        detailViewController.originalHafasStation = self.hafasStation;
        detailViewController.station = self.station;
        detailViewController.hafasDeparture = departure;
        if(departure.cancelled){
            detailViewController.hafasEventText = CANCELLED_TEXT;
        } else if(departure.partCancelled){
            detailViewController.hafasEventText = STOP_MISSING_TEXT;
        }
        detailViewController.showJourneyFromCurrentStation = true;
        [self.navigationController pushViewController:detailViewController animated:animated];
    }];
}

-(void)showJourneyForStop:(Stop *)stop{
    [self showJourneyForStop:stop showIrisOnFailure:true animated:true];
}
-(void)showJourneyForStop:(Stop *)stop showIrisOnFailure:(BOOL)showIrisOnFailure animated:(BOOL)animated{
    Event *event = [stop eventForDeparture:self.departure];
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    [[MBTrainJourneyRequestManager sharedManager] loadJourneyForEvent:event completionBlock:^(MBTrainJourney * _Nullable journey) {
        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
        if(!showIrisOnFailure && journey == nil){
            [self showJourneyAlert];
            return;
        }
        MBTrainJourneyViewController* detailViewController = [MBTrainJourneyViewController new];
        detailViewController.timetableOpenedFromOPNVOverlay = self.timetableOpenedFromOPNVOverlay;
        detailViewController.departure = self.departure;
        detailViewController.station = self.station;
        detailViewController.event = event;
        detailViewController.stop = stop;
        detailViewController.journey = journey; //journey may be nil, then journey will display IRIS data
        if(self.departure){
            detailViewController.showJourneyFromCurrentStation = true;
        }
        detailViewController.showJourneyMessageAndTrainLinks = true;
        [self.navigationController pushViewController:detailViewController animated:animated];
    }];
}

-(void)showJourneyAlert{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Hinweis" message:@"Die Verbindung wurde nicht geladen. Bitte prüfen Sie ihre Netzverbindung und versuchen Sie es später erneut." preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Abbrechen" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:true completion:nil];
}

-(void)handleSearchResult:(MBContentSearchResult*)search{
    self.searchresult = search;
    //the object is processed in viewDidAppear because we can be in all kind of states here and it's the only safe area where we can work with the contents of the (then displayed) tableview
}

-(void)updateFilterCellWithDepatureState{
    MBTimeTableFilterViewCell *tableCell = [self.timetableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    if(self.departure){
        [tableCell switchToDeparture];
    } else {
        [tableCell switchToArrival];
    }
}

-(void)runSearchResult:(MBContentSearchResult*)search{
    //reset filter
    self.currentlySelectedPlatform = @"Alle";
    self.currentlySelectedTransportType = @"Alle";
    self.departure = search.departure;
    if(search.isOPNVSearch){
        self.showFernverkehr = NO;
    } else {
        self.showFernverkehr = YES;
    }
    if(search.isPlatformSearch){
        self.currentlySelectedPlatform = search.platformSearch;
        [self filterByPlatformAndTransportType];
    }
    if(self.showFernverkehr){
        [self updateFilterCellWithDepatureState];
        NSInteger index = 0;
        BOOL found = NO;
        BOOL wagenreihungSearch = search.isWagenreihung;
        for(id item in self.timetableDataByDays){
            if(wagenreihungSearch){
                if([item isKindOfClass:Stop.class]){
                    if([Stop stopShouldHaveTrainRecord:item]){
                        found = YES;
                        break;
                    }
                }
            } else {
                if(item == search.stop){
                    found = YES;
                    break;
                }
            }
            index++;
        }
        index++;//increase once more for the filter cell
        if(found){
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            [self.timetableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
            [self.timetableView.delegate tableView:self.timetableView didSelectRowAtIndexPath:indexPath];
            [self.timetableView reloadData];
            [self.timetableView layoutIfNeeded];
            if(indexPath.row < [self tableView:self.timetableView numberOfRowsInSection:0]){
                //tell voiceover to center on the selected cell
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIView* cell = [self tableView:self.timetableView cellForRowAtIndexPath:indexPath];
                    if(cell){
                        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, cell);
                    }
                });
            }
        } else {
            NSLog(@"stop not found");
            [self.timetableView reloadData];
        }
    } else {
        //OPNV
        [self filterOPNVForSearch:search];
        [self.timetableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}
-(void)filterOPNVForSearch:(MBContentSearchResult*)search{
    self.currentlySelectedTransportType = [HafasDeparture stringForCat:search.opnvCat];
    [self filterByPlatformAndTransportType];
}
-(void)runSearchResultStep2:(MBContentSearchResult*)search{
    [self filterOPNVForSearch:search];
    NSArray<HafasDeparture*> *departureStops = self.hafasDataSource.hafasDepartures;
    NSLog(@"search %@",search.opnvLineIdentifier);
    HafasDeparture* foundDeparture = nil;
    NSInteger index = 0;
    for(HafasDeparture* departure in departureStops){
        if(departure.productCategory == search.opnvCat){
            if([departure.productLine isEqualToString:search.opnvLine]){
                foundDeparture = departure;
                break;
            }
        }
        index++;
    }
    if(foundDeparture){
        index++;//increase once more for the filter cell
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.timetableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        [self.timetableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
        [self.timetableView.delegate tableView:self.timetableView didSelectRowAtIndexPath:indexPath];
        [self.timetableView reloadData];
    } else {
        [self.timetableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}


- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kDefaultCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0) {
        return kDefaultCellHeight;
    } else {
        NSInteger actualIndex = indexPath.row;
        if(indexPath.section == 0){
            actualIndex--;
        }
        if(_showFernverkehr){
            id item = self.timetableDataByDays[actualIndex];
            if([item isKindOfClass:NSString.class]){
                return 25;
            }
        } else {
            id item = self.hafasDataSource.hafasDeparturesByDay[actualIndex];
            if([item isKindOfClass:NSString.class]){
                return 25;
            }
        }
        return kDefaultCellHeight;
    }
}

- (NSAttributedString *)attributedIrisMessage:(NSString *)iris forTrain:(NSString *)train {
    if(!iris){
        iris = @"";
    }
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.maximumLineHeight = 14.0;
    paragraphStyle.hyphenationFactor = 0.0;
    
    NSMutableAttributedString *finalAttributed = [[NSMutableAttributedString alloc] initWithString:iris attributes:@{NSFontAttributeName:[UIFont db_RegularTwelve], NSForegroundColorAttributeName: [UIColor db_mainColor], NSParagraphStyleAttributeName:paragraphStyle}];
    NSMutableAttributedString *trainPrefix = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ",train] attributes:@{NSFontAttributeName:[UIFont db_BoldTwelve], NSForegroundColorAttributeName: [UIColor db_mainColor], NSParagraphStyleAttributeName:paragraphStyle}];
    [trainPrefix appendAttributedString:finalAttributed];
    NSAttributedString *finalMessageAttributed = [[NSAttributedString alloc] initWithAttributedString:trainPrefix];
    return finalMessageAttributed;
}

- (CGFloat) calculateCellHeightForStop:(Stop*)stop;
{
    Event *event = [stop eventForDeparture:self.departure];
    
    CGSize constraintSize = CGSizeMake(self.timetableView.frame.size.width-kStationsLabelWidthReducer, CGFLOAT_MAX);
    
    CGFloat viaStationsSize = 100.0;
    CGRect boundingRect = CGRectIntegral([event.composedIrisMessageAttributed boundingRectWithSize:constraintSize options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil]);
    
    CGSize messageLabelSize = boundingRect.size;
    
    CGFloat computedHeight = viaStationsSize;
    if (event.composedIrisMessage.length > 0) {
        computedHeight += messageLabelSize.height+16;
    }
    
    if ([Stop stopShouldHaveTrainRecord:event.stop]) {
        // add extra height for Wagenstand button if the cell could display a link
        computedHeight += 100;
    }
    
    return ceilf(computedHeight);
}


#pragma -
#pragma MBMapViewControllerDelegate

-(NSArray<NSString *> *)mapFilterPresets{
    if(self.mapMarkers.count > 0){
        return @[];
    }
    
    if(self.showFernverkehr){
        return @[ PRESET_DB_TIMETABLE ];
    } else {
        if(self.currentlySelectedTransportType){
            NSLog(@"open map with filter %@",self.currentlySelectedTransportType);
            //e.g. for S open map with filter preset "local_timetable S"
            if([@[@"BUS",@"S",@"U",@"SEV",@"STR"] containsObject:self.currentlySelectedTransportType]){
                return @[ [@"local_timetable " stringByAppendingString:self.currentlySelectedTransportType] ];
            }
        }
        return @[ PRESET_LOCAL_TIMETABLE ];
    }
}

- (id)mapSelectedPOI
{
    if(_showFernverkehr){
        //nothing selected, do we have a filter for track?
        if(![self.currentlySelectedPlatform isEqualToString:@"Alle"]){
            //do we have entries here?
            Stop* stop = self.timetableData.firstObject;
            if(stop){
                Event *event = [stop eventForDeparture:self.departure];
                return [self.station poiForPlatform:event.actualPlatformNumberOnly];
            }
        }
    }
    return nil;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
