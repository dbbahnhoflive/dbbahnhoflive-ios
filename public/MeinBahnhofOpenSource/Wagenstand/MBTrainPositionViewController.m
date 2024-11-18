// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBTrainPositionViewController.h"
#import "WaggonCell.h"
#import "HeadCell.h"
#import "MBWagenstandHeaderRedesigned.h"
#import "WagenstandPushHeader.h"
#import "WagenstandRequestManager.h"
#import "AppDelegate.h"
#import "MBUrlOpening.h"
#import "MBStationNavigationViewController.h"
#import "MBMapViewController.h"
#import "RIMapPoi.h"
#import "MBUIHelper.h"
#import "NSDateFormatter+MBDateFormatter.h"
#import "MBTrackingManager.h"
#import "MBProgressHUD.h"
#import "MBRootContainerViewController.h"
#import "MBStationSearchViewController.h"

@import UserNotifications;

@interface MBTrainPositionViewController ()<MBMapViewControllerDelegate>

@property (nonatomic, strong) UITableView *wagenstandTable;
@property (nonatomic, strong) UIRefreshControl* refreshControl;

@property (nonatomic, strong) SectionIndicatorView *sectionIndicator;
@property (nonatomic, strong) NSArray *headerViews;
@property (nonatomic, strong) WagenstandPushHeader* pushHeader;

@property (nonatomic, strong) UIView* headerBackgroundView;//necessary for the shadow

@property (nonatomic, strong) UILabel* updateTimestampLabel;
@property (nonatomic, strong) UIView* updateTimestampView;

@end

@implementation MBTrainPositionViewController

static NSString *kWaggonCell = @"WaggonCell_Default";
static NSString *kHeadCell = @"HeadCell";

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.trackingTitle = @"d3";
    if(self.wagenstand){
        [MBTrackingManager trackStatesWithStationInfo:@[self.trackingTitle,
                                                        @"wagenreihung",
                                                        ]];
    }
    
    //NSLog(@"init controller with wagenstand %@",self.wagenstand);
    //NSLog(@"traintypes %@",self.wagenstand.traintypes);
    //NSLog(@"trainnumbers %@",self.wagenstand.trainNumbers);
    //NSLog(@"subtrains %@",self.wagenstand.subtrains);
    //NSLog(@"wagons %@",self.wagenstand.waggons);
    
    
    [self updateTitle];
    
    self.headerBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    self.headerBackgroundView.backgroundColor = [UIColor whiteColor];
    self.headerBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.headerBackgroundView.layer.shadowOffset = CGSizeMake(0,1);
    self.headerBackgroundView.layer.shadowOpacity = 0.3;
    self.headerBackgroundView.layer.shadowRadius = 2;

    [self.view addSubview:self.headerBackgroundView];
    
    self.wagenstandTable = [[UITableView alloc] init];
    self.wagenstandTable.backgroundColor = [UIColor whiteColor];
    [self.wagenstandTable registerClass:WaggonCell.class forCellReuseIdentifier:kWaggonCell];
    [self.wagenstandTable registerClass:HeadCell.class forCellReuseIdentifier:kHeadCell];
    self.wagenstandTable.delegate = self;
    self.wagenstandTable.dataSource = self;
    
    self.wagenstandTable.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    
    if(ISIPAD){
        //cells will generate their own separator
        self.wagenstandTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    }

    [self updateHeaderViews];
    
    UIView *updateTimestampView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.sizeWidth,40)];
    self.updateTimestampView = updateTimestampView;
    UILabel *updateTimestampLabel = [[UILabel alloc] init];
    
    self.updateTimestampLabel = updateTimestampLabel;
    self.updateTimestampLabel.isAccessibilityElement = NO;
    updateTimestampLabel.font = [UIFont db_RegularTwelve];
    updateTimestampLabel.textColor = [UIColor db_787d87];
    [self updateReloadTime];
    [updateTimestampView addSubview:updateTimestampLabel];
    
    UIImageView* reloadImg = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"ReloadBtn"]];
    [updateTimestampView addSubview:reloadImg];
    [reloadImg centerViewVerticalInSuperView];
    [reloadImg setGravityLeft:20-5];
    [updateTimestampLabel centerViewVerticalInSuperView];
    [updateTimestampLabel setRight:reloadImg withPadding:7];
    [self updateReloadTime];//update again to set correct text for accessibility!
    
    [self.view addSubview:self.updateTimestampView];
    
    self.pushHeader = [[WagenstandPushHeader alloc] initWithFrame:CGRectMake(0,0,self.view.sizeWidth,34)];

    self.sectionIndicator = [[SectionIndicatorView alloc] initWithWagenstand:self.wagenstand
                                                                    andFrame:CGRectMake(0, 0, self.view.sizeWidth, 70)];
    self.sectionIndicator.backgroundColor = [UIColor whiteColor];
    self.sectionIndicator.delegate = self;
    
    //[self.view addSubview:self.sectionIndicator];
    [self.view insertSubview:self.sectionIndicator belowSubview:self.headerBackgroundView];
    [self.view addSubview:self.pushHeader];
//    [self.view addSubview:self.wagenstandTable];
    [self.view insertSubview:self.wagenstandTable belowSubview:self.sectionIndicator];

    
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshData) forControlEvents:UIControlEventValueChanged];
    tableViewController.tableView = self.wagenstandTable;
    tableViewController.refreshControl = self.refreshControl;
    self.wagenstandTable.allowsSelection = NO;
    
    [self.wagenstandTable reloadData];
    
    self.pushHeader.pushSwitch.userInteractionEnabled = NO;
    [self findPendingNotificationWithCompletion:^(UNNotificationRequest * nr) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(nr){
                self.pushHeader.pushSwitch.on = YES;
            } else {
                self.pushHeader.pushSwitch.on = NO;
            }
            self.pushHeader.pushSwitch.userInteractionEnabled = YES;
        });
    }];

    [self.pushHeader.pushSwitch addTarget:self action:@selector(pushSwitchChanged:) forControlEvents:UIControlEventValueChanged];
}

-(void)updateHeaderViews{
    NSMutableArray* headers = [NSMutableArray arrayWithCapacity:self.wagenstand.subtrains.count];
    for(Train* subtrain in self.wagenstand.subtrains){
        MBWagenstandHeaderRedesigned* header = [[MBWagenstandHeaderRedesigned alloc] initWithWagenstand:self.wagenstand train:subtrain andFrame:CGRectZero];
        [headers addObject:header];
        [self.view addSubview:header];
    }
    self.headerViews = headers;
}

-(void)setTitle:(NSString *)atitle{
    if(UIAccessibilityIsVoiceOverRunning()){
        atitle = [atitle stringByReplacingOccurrencesOfString:@"Gl." withString:@"Gleis"];
    }
    [super setTitle:atitle];

}

-(void)updateReloadTime
{
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"dd.MM.YY, HH:mm"];
    NSDate* date = [NSDate date];
    NSString* dateString = [df stringFromDate:date];
    NSString* staticPart = @"Wagenreihungsplan Stand: ";
    NSMutableAttributedString* str = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@",staticPart, dateString ] attributes:@{NSFontAttributeName:[UIFont db_RegularTwelve]}];
    [str addAttributes:@{NSFontAttributeName:[UIFont db_BoldTwelve]} range:NSMakeRange(staticPart.length,str.length-staticPart.length)];
    self.updateTimestampLabel.attributedText = str;
    [self.updateTimestampLabel sizeToFit];

}

-(void)updateTitle{
    NSMutableString* titleString = [NSMutableString new];
    [titleString appendString:@"Wagenreihung"];
    if(self.wagenstand.plan_time.length > 0){
        if(UIAccessibilityIsVoiceOverRunning()){
            [titleString appendFormat:@" %@ Uhr",self.wagenstand.plan_time];
        } else {
            [titleString appendFormat:@" %@",self.wagenstand.plan_time];
        }
    }
    if(self.wagenstand.platform.length > 0){
        if(UIAccessibilityIsVoiceOverRunning()){
            [titleString appendString:@", Gleis "];
        } else {
            [titleString appendString:@" | Gl. "];
        }
        [titleString appendString:self.wagenstand.platform];
    }
    self.title = titleString;
}

-(void)refreshData
{
    NSLog(@"refreshData");
    [self.refreshControl beginRefreshing];

    [[WagenstandRequestManager sharedManager] loadISTWagenstandWithWagenstand:self.wagenstand completionBlock:^(Wagenstand *istWagenstand) {
        
        //NSLog(@"IST-Api responded with %@",istWagenstand);
        if(istWagenstand){
            self.wagenstand = istWagenstand;
            [self updateTitle];
            
            [self.headerViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [self updateHeaderViews];
            [self.view setNeedsLayout];
            [self.wagenstandTable reloadData];
        } else {
            //keep last data, update time???
        }
        [self updateReloadTime];
        [self.refreshControl endRefreshing];
    }];
}


-(void)pushSwitchChanged:(UISwitch*)pushSwitch{
    pushSwitch.userInteractionEnabled = NO;
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        if(settings.authorizationStatus == UNAuthorizationStatusNotDetermined){
            [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:UNAuthorizationOptionAlert|UNAuthorizationOptionSound completionHandler:^(BOOL granted, NSError * _Nullable error) {
                NSLog(@"got notif access %d, %@",granted,error);
                dispatch_async(dispatch_get_main_queue(), ^{
                    pushSwitch.userInteractionEnabled = YES;
                    [self userSettingsRegistered:granted];
                });
            }];
        } else if(settings.authorizationStatus == UNAuthorizationStatusDenied) {
            dispatch_async(dispatch_get_main_queue(), ^{
                pushSwitch.userInteractionEnabled = YES;
                [self userSettingsRegistered:NO];
            });
        } else {
            //should be authorized
            dispatch_async(dispatch_get_main_queue(), ^{
                pushSwitch.userInteractionEnabled = YES;
                [self userSettingsRegistered:YES];
            });
        }
    }];
}

-(void)findPendingNotificationWithCompletion:(void (^)(UNNotificationRequest *))completion{
    NSString* trainNumber = [Wagenstand getTrainNumberForWagenstand:_wagenstand];
    NSString* time = _wagenstand.request_date;
    //iterate over registered notifications and check if we need to cancel one

    UNUserNotificationCenter* notificationCenter = UNUserNotificationCenter.currentNotificationCenter;
    [notificationCenter getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
        for(UNNotificationRequest* request in requests){
            NSDictionary* userInfo = request.content.userInfo;
            if([[userInfo objectForKey:@"type"] isEqualToString:@"wagenstand"] &&
               [[userInfo objectForKey:WAGENSTAND_TRAINNUMBER] isEqualToString:trainNumber] &&
               [[userInfo objectForKey:WAGENSTAND_DATE_FOR_REQUEST] isEqualToString:time]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(request);
                });
                return;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil);
        });
    }];
}

-(void)updateLocalNotif{
    NSString* trainNumber  =[Wagenstand getTrainNumberForWagenstand:_wagenstand];
    NSString* request_date = _wagenstand.request_date;
    NSString* time = _wagenstand.expected_time;
    if(!time){
        //fallback to planed time
        time = _wagenstand.plan_time;
    }
    NSLog(@"pushSwitch changed status to %d, must register/remove local notification for train %@ at %@", self.pushHeader.pushSwitch.on, trainNumber, time);
    
    NSString* identifier = @"trainOrderNotif";
    
    UNUserNotificationCenter* notificationCenter = UNUserNotificationCenter.currentNotificationCenter;
    [self findPendingNotificationWithCompletion:^(UNNotificationRequest * nr) {
        if(nr){
            NSLog(@"remove a pending notif %@",nr.identifier);
            [notificationCenter removePendingNotificationRequestsWithIdentifiers:@[ nr.identifier ]];
        }
        
        if(self.pushHeader.pushSwitch.on){
            //register new notification
            NSDate* fireDate = [NSDateFormatter dateFromString:time forPattern:@"HH:mm"];
            
            NSCalendar *calendar = [NSCalendar currentCalendar];
            NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:fireDate];
            NSInteger hour = [components hour];
            NSInteger minute = [components minute];
            
            fireDate = [self fireDate:hour minute:minute];
            //fireDate = [NSDate dateWithTimeIntervalSinceNow:20];// for testing we fire 20s from now

            if([fireDate earlierDate:[NSDate date]] == fireDate){
                //this would fire in the past and display immediately, instead display alert
                // NSLog(@"ignore notification with date in past");
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Wagenreihungsplan" message:@"Die Erinnerungsfunktion steht nur bis 10 Minuten vor Einfahrt des Zuges zur Verfügung." preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
                self.pushHeader.pushSwitch.on = NO;
                return;
            }
            AppDelegate* app = (AppDelegate*) [UIApplication sharedApplication].delegate;
            NSNumber* stationNumber = app.selectedStation.mbId;
            if(!stationNumber) {
                stationNumber = @0;
            }
            NSString* stationName = app.selectedStation.title;
            if(!stationName) {
                stationName = @"";
            }
            
            NSString *destination = ((Train*)self.wagenstand.subtrains.firstObject).destinationStation;
            NSString* trainType  =[Wagenstand getTrainTypeForWagenstand:self.wagenstand];
            
            UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
            content.title = @"Bahnhof live";
            content.body = [NSString stringWithFormat:@"Ihr Zug %@ %@ nach %@ Hbf fährt in Kürze ein. Jetzt Wagenreihung prüfen.",
            trainType,
            trainNumber,
            destination];
            content.sound = [UNNotificationSound defaultSound];
            content.userInfo = @{
                @"type":@"wagenstand",
                WAGENSTAND_TRAINNUMBER:trainNumber,
                WAGENSTAND_DATE_FOR_REQUEST:request_date,
                WAGENSTAND_TYPETRAIN:trainType,
                @"stationNumber":stationNumber,
                @"stationName":stationName,
                WAGENSTAND_EVA_NR:self.wagenstand.evaId,
                WAGENSTAND_DEPARTURE:@(self.wagenstand.departure),
                @"body":content.body,
            };
            
            NSTimeInterval interval = [fireDate timeIntervalSinceNow];
            
            UNNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:interval repeats:NO];
            NSString* uuidString = [NSUUID UUID].UUIDString;
            uuidString = [identifier stringByAppendingString:uuidString];
            UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:uuidString content:content trigger:trigger];
            [notificationCenter addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                NSLog(@"added notif %@ with %@ at %@, error %@",uuidString,content.userInfo,fireDate,error);
            }];
        }
    }];
    

}

-(void)userSettingsRegistered:(BOOL)success{
    NSLog(@"registered notif: %d",success);
    if(!success){
        self.pushHeader.pushSwitch.on = NO;
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Hinweis" message:@"Sie müssen der App in den Einstellungen Mitteilungen erlauben um diese Funktion nutzen zu können." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Einstellungen" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [MBUrlOpening openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Schließen" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        
    }
    [self updateLocalNotif];
}

- (NSDate*) fireDate:(NSInteger)hour minute:(NSInteger)minutes
{
    NSDate *date = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components: NSUIntegerMax fromDate: date];
    [components setHour: hour];
    [components setMinute: minutes];
    
    NSDate *fullDate = [gregorian dateFromComponents: components];
    return [fullDate dateByAddingTimeInterval:-10*60];//10min earlier
}

# pragma -
# pragma UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // standard cell height 160 for length 2.0
    // half cell height 80 for length 1.0
    CGFloat height = 0.f;
    Waggon *waggon = self.wagenstand.waggons[indexPath.item];
    if (waggon) {
        if (waggon.isTrainBothWays && waggon != [self.wagenstand.waggons lastObject] && waggon != [self.wagenstand.waggons firstObject]) {
            height = 130.f;
        } else {
            height = [waggon heightOfCell];
            if(waggon.fahrzeugausstattung.count > 0){
                //maybe update height depending on items...
                double widthOfLegendPart = [WaggonCell widthOfLegendPartForWidth:self.view.frame.size.width];
                NSArray* tags = [waggon setupTagViewsForWidth:widthOfLegendPart];
                UIView* v = tags.lastObject;
                CGFloat spaceAtTheEndOfCell = 10;
                CGFloat maxHeight = CGRectGetMaxY(v.frame) + spaceAtTheEndOfCell;
                if(maxHeight > height){
                    height = maxHeight;
                }
            }
        }
    }
    
    return height;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.wagenstand.waggons.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Waggon *waggon = self.wagenstand.waggons[indexPath.item];
    Train *train = [self.wagenstand destinationForWaggon:waggon];

    UITableViewCell *tableCell;
    
    if (waggon.isTrainHead || waggon.isTrainBack || waggon.isTrainBothWays) {
        HeadCell *cell = [tableView dequeueReusableCellWithIdentifier:kHeadCell forIndexPath:indexPath];
        [cell setWaggon:waggon lastPosition:indexPath.item==self.wagenstand.waggons.count-1];
        [cell setTrain:train];
        tableCell = cell;
    } else {
        WaggonCell *cell = [tableView dequeueReusableCellWithIdentifier:kWaggonCell forIndexPath:indexPath];
        cell.waggon = waggon;
        tableCell = cell;
    }
    
    tableCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return tableCell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSArray *visibleIndexPaths = [self.wagenstandTable indexPathsForVisibleRows];
    if (visibleIndexPaths.count > 0) {
        NSArray* sortedIndexPaths = [visibleIndexPaths sortedArrayUsingSelector:@selector(compare:)];
        NSIndexPath *firstVisibleIndexPath = [sortedIndexPaths firstObject];
        
        Waggon *waggon = self.wagenstand.waggons[firstVisibleIndexPath.row];
        NSString *section = [waggon.sections lastObject];
                
        [self.sectionIndicator setActiveSection:section atIndex:firstVisibleIndexPath.row animateTo:YES];
        [self.sectionIndicator setActiveWaggonAtIndex:firstVisibleIndexPath.row animateTo:YES];

    }
}


# pragma -
# pragma Layout

- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

//    int y = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    int y = 0;
    y += 18;
    for(MBWagenstandHeaderRedesigned* header in self.headerViews){
        CGRect f = header.frame;
        f.origin.y = y;
        header.frame = f;
        [header resizeForWidth:self.view.sizeWidth];
        y += header.frame.size.height;
    }
    
    [self.updateTimestampView setY:y];
    y += self.updateTimestampView.sizeHeight;
    
    if(self.pushHeader){
        self.pushHeader.frame = CGRectMake(0, y-14, self.view.sizeWidth, self.pushHeader.sizeHeight);
        self.sectionIndicator.frame = CGRectMake(0,CGRectGetMaxY(self.pushHeader.frame)+13, self.view.sizeWidth, 70);
        self.wagenstandTable.frame = CGRectMake(0,CGRectGetMaxY(self.sectionIndicator.frame), self.view.sizeWidth, self.view.sizeHeight-(CGRectGetMaxY(self.pushHeader.frame)));
    } else {
        self.sectionIndicator.frame = CGRectMake(0,y, self.view.sizeWidth, 70);
        self.wagenstandTable.frame = CGRectMake(0,CGRectGetMaxY(self.sectionIndicator.frame), self.view.sizeWidth, self.view.sizeHeight-(CGRectGetMaxY(self.sectionIndicator.frame)));
    }
    
    self.headerBackgroundView.frame = CGRectMake(0, 0, self.view.sizeWidth, self.sectionIndicator.frame.origin.y);
    
    self.sectionIndicator.layer.shadowColor = [UIColor blackColor].CGColor;
    self.sectionIndicator.layer.shadowOffset = CGSizeMake(0,1);
    self.sectionIndicator.layer.shadowOpacity = 0.3;
    self.sectionIndicator.layer.shadowRadius = 2;
    
    // Increase the content inset, so we can scroll the last cell to the top of the view.
    // This way we make sure, that we can reach all sections of the train
    if (self.wagenstand.waggons.count > 0) {
        Waggon *waggon = [self.wagenstand.waggons lastObject];
        double heightOfLastWaggon = [waggon heightOfCell];
        self.wagenstandTable.contentInset = UIEdgeInsetsMake(0,
                                                             0,
                                                             self.wagenstandTable.sizeHeight-heightOfLastWaggon
                                                             ,
                                                             0);
    }
}

#pragma -
#pragma SectionIndicatorDelegate

- (void)sectionView:(SectionIndicatorView *)sectionView didSelectSection:(NSString *)section
{
    NSInteger index = [self.wagenstand indexOfWaggonForSection:section];
    
    if (index != -1) {
        [self.wagenstandTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [(MBStationNavigationViewController *)self.navigationController hideNavbar:NO];
    [(MBStationNavigationViewController *)self.navigationController showBackgroundImage:NO];
    [(MBStationNavigationViewController *)self.navigationController setShowRedBar:YES];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    
    
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark -
#pragma mark MBMapViewControllerDelegate


-(id)mapSelectedPOI{
    return [self.station poiForPlatform:self.wagenstand.platform];
}
-(NSArray<NSString *> *)mapFilterPresets{
    return @[ PRESET_DB_TIMETABLE ];
}


#pragma mark helper methods

+(void) showWagenstandForUserInfo:(NSDictionary *)userInfo fromViewController:(MBUIViewController*)vc
{
    // NSLog(@"load and display wagenstand for %@",userInfo);
    
    [MBProgressHUD showHUDAddedTo:vc.navigationController.view animated:YES];
    
    UINavigationController* navi = vc.navigationController;

    MBRootContainerViewController* root = nil;
    if([vc isKindOfClass:[MBStationSearchViewController class]]){
        //opened wagenstand when inside a station
        root = ((MBStationSearchViewController*)vc).stationMapController;
        navi = root.timetableNavigationController;
    } else if([vc isKindOfClass:[MBRootContainerViewController class]]){
        //opened wagenstand when outside of a station
        root = (MBRootContainerViewController*)vc;
        if(root.view){//force loading of view to get access to timetable
            navi = root.timetableNavigationController;
            // NSLog(@"open wagenstand for navi %@",navi);
        }
    }

    [[WagenstandRequestManager sharedManager] loadISTWagenstandWithTrain:userInfo[WAGENSTAND_TRAINNUMBER] type:userInfo[WAGENSTAND_TYPETRAIN] date:userInfo[WAGENSTAND_DATE_FOR_REQUEST] evaId:userInfo[WAGENSTAND_EVA_NR] departure:((NSNumber*)userInfo[WAGENSTAND_DEPARTURE]).boolValue completionBlock:^(Wagenstand *istWagenstand) {
        
        if(istWagenstand){
            MBTrainPositionViewController *wagenstandDetailViewController = [[MBTrainPositionViewController alloc] init];
            wagenstandDetailViewController.station = vc.station;
            wagenstandDetailViewController.wagenstand = istWagenstand;
            [root selectTimetableTab];
            [navi pushViewController:wagenstandDetailViewController animated:YES];
        } else {
            //no IST-data
            UIAlertController* alertView = [UIAlertController alertControllerWithTitle:@"Hinweis" message:@"Beim Abrufen des Wagenreihungsplans ist ein Fehler aufgetreten. Bitte versuchen Sie es später erneut." preferredStyle:UIAlertControllerStyleAlert];
            [alertView addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:nil]];
            [root presentViewController:alertView animated:YES completion:nil];
            [MBProgressHUD hideHUDForView:vc.navigationController.view animated:YES];
            return;
        }
        
        [MBProgressHUD hideHUDForView:vc.navigationController.view animated:YES];
    }];
}

@end
