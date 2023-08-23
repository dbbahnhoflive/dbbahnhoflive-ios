// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBFacilityStatusViewController.h"
#import "MBFacilityTableViewCell.h"
#import "MBFacilityDeleteAllTableViewCell.h"

#import "MBSwitch.h"
#import "MBStationNavigationViewController.h"
#import "FacilityStatusManager.h"

#import "MBMapViewController.h"

#import "MBUIViewController.h"

#import "MBTutorialManager.h"
#import "MBUIHelper.h"
#import "MBTrackingManager.h"
#import "MBProgressHUD.h"

@interface MBFacilityStatusViewController () <UITableViewDelegate, UITableViewDataSource, MBFacilityTableViewCellDelegate, MBFacilityDeleteAllTableViewCellDelegate, MBMapViewControllerDelegate>
@property (nonatomic, strong) NSArray *facilities;
@property (nonatomic, strong) NSArray *storedFacilities;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic) BOOL showUebersicht;
@property (nonatomic) BOOL needsFavoriteListUpdate;
@property (nonatomic) BOOL suspendTableReloads;

@property(nonatomic,strong) UIRefreshControl* refreshControl;
@end

@implementation MBFacilityStatusViewController

-(instancetype)init{
    self = [super init];
    if(self){
        self.trackingTitle = @"aufzuege";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Aufzüge";
    
    [MBTrackingManager trackStatesWithStationInfo:@[@"d1", self.trackingTitle]];
    
    [MBUIViewController addBackButtonToViewController:self andActionBlockOrNil:nil];
    
    self.showUebersicht = YES;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.remembersLastFocusedIndexPath = true;//this does not work with the alert
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor db_f0f3f5];
    [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 80, 0)];
    [self.tableView setSectionHeaderHeight:78.0];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"EmptyCell"];
    [self.tableView registerClass:[MBFacilityDeleteAllTableViewCell class] forCellReuseIdentifier:@"DeleteCell"];
    [self.tableView registerClass:[MBFacilityTableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    [self.view addSubview:self.tableView];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshData) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = self.refreshControl;
}

-(void)refreshData{
    [self.refreshControl beginRefreshing];
    if(self.showUebersicht){
        [self updateFacilities];
    } else {
        [self updateStoredFacilities];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (nil != self.navigationController) {
        if ([self.navigationController isKindOfClass:[MBStationNavigationViewController class]]) {
            [(MBStationNavigationViewController *)self.navigationController hideNavbar:NO];
            [(MBStationNavigationViewController *)self.navigationController showBackgroundImage:NO];
            [(MBStationNavigationViewController *)self.navigationController setShowRedBar:NO];
        }
    }
    [self.tableView reloadData];
    [[MBTutorialManager singleton] displayTutorialIfNecessary:MBTutorialViewType_D1_Aufzuege withOffset:60];
    [[MBTutorialManager singleton] displayTutorialIfNecessary:MBTutorialViewType_D1_FacilityPush withOffset:60];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    if(self.reloadStatusOnFirstView){
        self.reloadStatusOnFirstView = false;
        [self updateFacilities];
    }
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[MBTutorialManager singleton] hideTutorials];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

-(void)didBecomeActive:(id)sender{
    [self.tableView reloadData];
}

- (void)setStation:(MBStation *)station {
    _station = station;
    self.facilities = station.facilityStatusPOIs;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect rect = self.view.frame;
    rect.origin.y = 0;
    self.tableView.frame = rect;
}

- (void)deleteAllFacilities {
    // alert user about what is going to happen now
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Liste leeren" message:@"Möchten Sie alle Einträge aus der Liste entfernen?" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Ja" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [FacilityStatusManager.client removeAll];
        [self updateStoredFacilities];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Nein" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        //do nothing
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(![self displayEmptyCell] && (self.showUebersicht || (!self.showUebersicht && indexPath.row > 0))){
        FacilityStatus* f = [self.facilities objectAtIndex:[self actualIndexForIndexPath:indexPath]];
        if(UIAccessibilityIsVoiceOverRunning()){
            [self showAlertForFacility:f indexPath:indexPath];
        } else {
            [self changeStatusForFacility:f];
            [self.tableView reloadData];
        }
    } else {
    }
    //[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];//animation is broken in some cases
}

-(void)showAlertForFacility:(FacilityStatus*)facility indexPath:(NSIndexPath *)indexPath{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Optionen" message:facility.shortDescription preferredStyle:UIAlertControllerStyleAlert];
    NSString* text1 = @"Zur Merkliste hinzufügen";
    NSString* text2 = @"Zur Merkliste hinzufügen und Mitteilungen aktivieren";
    
    BOOL isFavorite = [FacilityStatusManager.client isFavoriteFacility:facility.equipmentNumberString];
    BOOL isPushActive = [FacilityStatusManager.client isPushActiveForFacility:facility.equipmentNumberString];
    if(isFavorite){
        if(isPushActive){
            text1 = @"Aus Merkliste entfernen und Mitteilungen deaktivieren";
            text2 = @"Mitteilungen deaktivieren";
        } else {
            text1 = @"Aus Merkliste entfernen";
            text2 = @"Mitteilungen aktivieren";
        }
    }
    self.suspendTableReloads = true;
    if(isFavorite && isPushActive){
        //push-option moves to the first button
        [alert addAction:[UIAlertAction actionWithTitle:text2 style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self facilityCell:nil togglesPushSwitch:nil newState:!isPushActive forFacility:facility];
            [self updateCell:indexPath];
            self.suspendTableReloads = false;
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:text1 style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self changeStatusForFacility:facility];
            if(!self.showUebersicht && isFavorite){
                //we just deleted this cell, dont' select it
                [self.tableView reloadData];
            } else {
                [self updateCell:indexPath];
            }
            self.suspendTableReloads = false;
        }]];
    } else {
        [alert addAction:[UIAlertAction actionWithTitle:text1 style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self changeStatusForFacility:facility];
            if(!self.showUebersicht && isFavorite){
                //we just deleted this cell, dont' select it
                [self.tableView reloadData];
            } else {
                [self updateCell:indexPath];
            }
            self.suspendTableReloads = false;
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:text2 style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if(!isFavorite){
                [self changeStatusForFacility:facility];
            }
            [self facilityCell:nil togglesPushSwitch:nil newState:!isPushActive forFacility:facility];
            [self updateCell:indexPath];
            self.suspendTableReloads = false;
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Abbrechen" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }]];
    [self presentViewController:alert animated:true completion:nil];
}
-(void)updateCell:(NSIndexPath*)indexPath{
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    //[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    UIView* cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, cell);
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = self.facilities.count;
    if (self.showUebersicht) {
        if (count == 0) {
            count = 1;
        }
    } else {
        // Merkliste: 1 additional row for "delete all"
        count += 1;
    }
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat height = 70.0;
    if (self.showUebersicht && self.facilities.count > 0) {
        height += 8.0;
    }
    return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    CGFloat heigth = 70.0;
    CGFloat bottomSlack = 0.0;
    if (self.showUebersicht) {
        bottomSlack = 8.0;
    }
    UIView *backView = [[UIView alloc] initWithFrame:CGRectMake(0, 0.0, tableView.frame.size.width, heigth+bottomSlack)];
    
    MBSwitch *header = [[MBSwitch alloc] initWithFrame:CGRectMake(0, 0.0, tableView.frame.size.width, heigth) onTitle:@"Übersicht" offTitle:@"Merkliste" onState:self.showUebersicht];
    [header addTarget:self action:@selector(toggleList:) forControlEvents:UIControlEventValueChanged];
    header.noShadow = YES;
    header.noRoundedCorners = YES;
    header.activeLabelFont = [UIFont db_BoldTwentyTwo];
    header.inActiveLabelFont = [UIFont db_RegularTwentyTwo];
    header.activeTextColor = [UIColor db_333333];
    header.inActiveTextColor = [UIColor db_dadada];
    header.backgroundColor = [UIColor whiteColor];
    
    [backView addSubview:header];
    
    return backView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 84.0;
    if (indexPath.row == 0) {
        if ([self displayEmptyCell]) {
            return height;
        } else if (!self.showUebersicht && self.storedFacilities.count > 0) {
            return height;
        }
    }
    NSInteger index = [self actualIndexForIndexPath:indexPath];
    FacilityStatus* status = [self.facilities objectAtIndex:index];
    if([FacilityStatusManager.client isFavoriteFacility:status.equipmentNumberString]){
        return 140;
    }
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (indexPath.row == 0) {
        if ([self displayEmptyCell]) {
            UITableViewCell* noContentCell = [tableView dequeueReusableCellWithIdentifier:@"EmptyCell" forIndexPath:indexPath];
            noContentCell.imageView.image = [UIImage db_imageNamed:@"app_warndreieck"];
            noContentCell.textLabel.numberOfLines = 0;
            noContentCell.textLabel.text = self.showUebersicht ? @"An diesem Bahnhof sind keine Anlagen vorhanden" : @"Noch keine Einträge vorhanden";
            noContentCell.textLabel.textColor = [UIColor db_878c96];
            noContentCell.textLabel.font = [UIFont db_RegularTwelve];
            noContentCell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell = noContentCell;

        } else if (!self.showUebersicht && self.storedFacilities.count > 0) {
            // Merkliste special delete them all cell
            MBFacilityDeleteAllTableViewCell *deleteCell = [tableView dequeueReusableCellWithIdentifier:@"DeleteCell"];
            deleteCell.delegate = self;
            cell = deleteCell;
        } else {
            cell = [self cellForIndex:0 andRow:0];
        }
    } else {
        cell = [self cellForIndex:[self actualIndexForIndexPath:indexPath] andRow:indexPath.row];
    }
    return cell;
}

//helper methods

-(BOOL)displayEmptyCell{
    return (self.showUebersicht && self.facilities.count == 0)
    || (!self.showUebersicht && self.storedFacilities.count == 0);
}

-(NSUInteger)actualIndexForIndexPath:(NSIndexPath*)indexPath{
    NSUInteger actualIndex = self.showUebersicht && self.facilities.count > 0 ? indexPath.row : indexPath.row - 1;
    return actualIndex;
}

- (MBFacilityTableViewCell *)cellForIndex:(NSUInteger)index andRow:(NSUInteger)row {
    MBFacilityTableViewCell *facilityCell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
    facilityCell.selectionStyle = UITableViewCellSelectionStyleNone;
    facilityCell.currentStationName = self.station.title;
    facilityCell.status = [self.facilities objectAtIndex:index];
    facilityCell.delegate = self;
    return facilityCell;
}

-(void)setStoredFacilities:(NSArray *)storedFacilities{
    _storedFacilities = [storedFacilities sortedArrayUsingComparator:^NSComparisonResult(FacilityStatus* _Nonnull obj1, FacilityStatus*  _Nonnull obj2) {
        // sort result alphabetical by station name and then by description
        NSComparisonResult res = [[FacilityStatusManager.client stationNameForStationNumber:obj1.stationNumber.description] compare:[FacilityStatusManager.client stationNameForStationNumber:obj2.stationNumber.description]];
        if(res == NSOrderedSame){
            return [obj1.shortDescription compare:obj2.shortDescription];
        } else {
            return res;
        }
    }];
}

- (void)updateStoredFacilities {
    //update the "merkliste"
    self.needsFavoriteListUpdate = false;
    if(self.storedFacilities == nil){
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
    //note that requestFacilityStatusForFacilities returns success without network access, if the list of storedFavorites is empty
    [FacilityStatusManager.client requestFacilityStatusForFacilities:[FacilityStatusManager.client storedFavorites] success:^(NSArray *facilityStatusItems) {
        [self.refreshControl endRefreshing];
        if(self.storedFacilities == nil){
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }
        self.storedFacilities = facilityStatusItems;
        if (!self.showUebersicht) {
            self.facilities = self.storedFacilities;
        }
        [self.tableView reloadData];
    } failureBlock:^(NSError *bhfError) {
        [self.refreshControl endRefreshing];
        if(self.storedFacilities == nil){
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }
        // NSLog(@"error: %@",bhfError);
        [self showLoadError];
    }];
}
-(void)updateFacilities{
    //update the facilities for the "Overview" tab, all facilities in this station
    [FacilityStatusManager.client requestFacilityStatus:self.station.mbId success:^(NSArray<FacilityStatus *> *facilityStatusItems) {
        [self.refreshControl endRefreshing];
        if(facilityStatusItems.count != self.station.facilityStatusPOIs.count){
            NSLog(@"Error: count has changed, this is probably a loading error and will be ignored");
            return;
        }
        self.station.facilityStatusPOIs = facilityStatusItems;
        if(self.showUebersicht){
            self.facilities = self.station.facilityStatusPOIs;
            [self.tableView reloadData];
        }
    } failureBlock:^(NSError *error) {
        [self.refreshControl endRefreshing];
        [self showLoadError];
    }];
}
-(void)showLoadError{
    NSString *errorHeadline = @"Bahnhof live";
    NSString *errorMessage = @"Die Aufzugsdaten konnten nicht geladen werden. Bitte versuchen Sie es später erneut.";
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:errorHeadline message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)toggleList:(MBSwitch *)sender {
    self.showUebersicht = sender.on;
    if (sender.on) {
        // Übersicht
        self.facilities = self.station.facilityStatusPOIs;
        [self.tableView reloadData];
        [MBTrackingManager trackStatesWithStationInfo:@[@"d1", @"aufzuege"]];
    } else {
        // Merkliste
        self.facilities = self.storedFacilities;
        [self.tableView reloadData];
        [MBTrackingManager trackStatesWithStationInfo:@[@"d1", @"aufzuege_gemerkt"]];
        if(self.storedFacilities == nil || self.needsFavoriteListUpdate){
            [self updateStoredFacilities];
        }
    }
}

-(void)changeStatusForFacility:(FacilityStatus*)facility{
    if([FacilityStatusManager.client isFavoriteFacility:facility.equipmentNumberString]){
        [self removeFromWatchList:facility];
    } else {
        [self addToWatchList:facility];
    }
}

-(void)removeFromWatchList:(FacilityStatus*)facility{
    [MBTrackingManager trackActionsWithStationInfo:@[@"d1",@"aufzuege",@"favorit",@"remove"]];
    [FacilityStatusManager.client removeFromFavorites:facility.equipmentNumberString];
    NSMutableArray* list = [self.storedFacilities mutableCopy];
    [list removeObject:facility];
    self.storedFacilities = list;
    if(!self.showUebersicht){
        self.facilities = self.storedFacilities;
    }
    if(_suspendTableReloads){
        return;
    }
    [self.tableView reloadData];
}
-(void)addToWatchList:(FacilityStatus*)facility{
    [MBTrackingManager trackActionsWithStationInfo:@[@"d1",@"aufzuege",@"favorit",@"add"]];
    [FacilityStatusManager.client addToFavorites:facility.equipmentNumberString stationNumber:self.station.mbId.description stationName:self.station.title];
    self.needsFavoriteListUpdate = true;
    if(_suspendTableReloads){
        return;
    }
    [self.tableView reloadData];
}

#pragma mark MBFacilityTableViewCellDelegate
- (void)facilityCell:(MBFacilityTableViewCell *)cell removesFacility:(FacilityStatus *)status {
    [self removeFromWatchList:status];
}

- (void)facilityCell:(MBFacilityTableViewCell *)cell addsFacility:(FacilityStatus *)status {
    [self addToWatchList:status];
}

-(void)facilityCell:(MBFacilityTableViewCell *)cell togglesPushSwitch:(UISwitch *)sender newState:(BOOL)on forFacility:(FacilityStatus *)status{
    if(!FacilityStatusManager.client.isSystemPushActive && ((sender && on) || (!sender))){
        sender.on = false;
        [self facilityCell:cell wantsSystemPushDialog:status];
        return;
    }
    if(!FacilityStatusManager.client.isGlobalPushActive && on){
        [self facilityCell:cell wantsGlobalPushDialog:status];
        return;
    }
    if (on) {
        [self facilityCell:cell addsPush:status];
    } else {
        [self facilityCell:cell removesPush:status];
    }
}

-(void)facilityCell:(MBFacilityTableViewCell *)cell addsPush:(FacilityStatus *)status{
    [FacilityStatusManager.client enablePushForFacility:status.equipmentNumberString completion:^(BOOL success,NSError * error) {
        if(success){
            [MBTrackingManager trackActionsWithStationInfo:@[@"d1",@"aufzuege",@"favorit",@"push",@"active"]];
        }
    }];
}
-(void)facilityCell:(MBFacilityTableViewCell *)cell removesPush:(FacilityStatus *)status{
    [FacilityStatusManager.client disablePushForFacility:status.equipmentNumberString completion:^(BOOL success,NSError * error) {
        if(success){
            [MBTrackingManager trackActionsWithStationInfo:@[@"d1",@"aufzuege",@"favorit",@"push",@"inactive"]];
        }
    }];
}
-(void)facilityCell:(MBFacilityTableViewCell *)cell wantsSystemPushDialog:(FacilityStatus *)status{
    [self presentViewController:FacilityStatusManager.client.alertForPushNotActive animated:YES completion:nil];
}
-(void)facilityCell:(MBFacilityTableViewCell *)cell wantsGlobalPushDialog:(FacilityStatus *)status{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Push-Mitteilungen" message:@"Push-Mitteilungen sind deaktiviert. Möchten Sie Benachrichtigungen aktivieren?" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Nein" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if(self.suspendTableReloads){
            return;
        }
        [self.tableView reloadData];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Ja" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [FacilityStatusManager.client setGlobalPushActive:YES completion:^(NSError * error) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if(![FacilityStatusManager.client isPushActiveForFacility:status.equipmentNumberString]){
                [FacilityStatusManager.client enablePushForFacility:status.equipmentNumberString completion:^(BOOL success,NSError * error) {
                }];
            }
            [self.tableView reloadData];
        }];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark MBMapViewControllerDelegate

-(NSArray<NSString *> *)mapFilterPresets{
    return @[ PRESET_ELEVATORS ];
}

-(id)mapSelectedPOI{
    return self.facilities.firstObject;
}

@end
