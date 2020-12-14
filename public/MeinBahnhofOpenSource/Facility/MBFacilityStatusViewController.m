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

@interface MBFacilityStatusViewController () <UITableViewDelegate, UITableViewDataSource, MBFacilityTableViewCellDelegate, MBFacilityDeleteAllTableViewCellDelegate, MBMapViewControllerDelegate>
@property (nonatomic, strong) NSArray *facilities;
@property (nonatomic, strong) NSArray *storedFacilities;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSIndexPath *selectedRow;
@property (nonatomic) BOOL showUebersicht;
@end

@implementation MBFacilityStatusViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Aufzüge";
    
    [MBTrackingManager trackStatesWithStationInfo:@[@"d1", @"aufzuege"]];
    
    [MBUIViewController addBackButtonToViewController:self andActionBlockOrNil:nil];
    
    self.selectedRow = [NSIndexPath indexPathForRow:-1 inSection:-1];
    self.showUebersicht = YES;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor db_f0f3f5];
    [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 80, 0)];
    [self.tableView setSectionHeaderHeight:78.0];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"EmptyCell"];
    [self.tableView registerClass:[MBFacilityDeleteAllTableViewCell class] forCellReuseIdentifier:@"DeleteCell"];
    [self.tableView registerClass:[MBFacilityTableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    [self.view addSubview:self.tableView];
    //[self.tableView reloadData];
    

    
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
    [self updateStoredFacilities];
    
    [[MBTutorialManager singleton] displayTutorialIfNecessary:MBTutorialViewType_D1_Aufzuege withOffset:60];
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[MBTutorialManager singleton] hideTutorials];
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
        [[FacilityStatusManager client] removeAll];
        [self updateStoredFacilities];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Nein" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        //do nothing
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MBFacilityTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (self.selectedRow && self.selectedRow.row == indexPath.row) {
        self.selectedRow = [NSIndexPath indexPathForRow:-1 inSection:-1];
        cell.expanded = NO;
    } else {
        for (MBFacilityTableViewCell *otherCell in [tableView visibleCells]) {
            if ([otherCell respondsToSelector:@selector(setExpanded:)]) {
                otherCell.expanded = NO;
            }
        }
        if ([cell respondsToSelector:@selector(setExpanded:)]) {
            self.selectedRow = indexPath;
            cell.expanded = YES;
        }
    }
    [self.tableView reloadData];
    //[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];//animation is broken in some cases
}

#pragma mark UITableViewDataSource
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
    CGFloat height = 90.0;
    if (nil != self.selectedRow && self.selectedRow.row == indexPath.row) {
        height += 74.0;
    }
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (indexPath.row == 0) {
        if ((self.showUebersicht && self.facilities.count == 0)
            || (!self.showUebersicht && self.storedFacilities.count == 0)) {
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
        NSUInteger actualIndex = self.showUebersicht && self.facilities.count > 0 ? indexPath.row : indexPath.row - 1;
        cell = [self cellForIndex:actualIndex andRow:indexPath.row];
    }
    return cell;
}

- (MBFacilityTableViewCell *)cellForIndex:(NSUInteger)index andRow:(NSUInteger)row {
    MBFacilityTableViewCell *facilityCell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
    facilityCell.selectionStyle = UITableViewCellSelectionStyleNone;
    facilityCell.currentStationName = self.station.title;
    facilityCell.status = [self.facilities objectAtIndex:index];
    facilityCell.delegate = self;
    if (nil != self.selectedRow && self.selectedRow.row == row) {
        facilityCell.expanded = YES;
    } else {
        facilityCell.expanded = NO;
    }
    return facilityCell;
}

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

- (void)updateStoredFacilities {
    [[FacilityStatusManager client] requestFacilityStatusForFacilities:[[FacilityStatusManager client] storedFavorites] success:^(NSArray *facilityStatusItems) {
        self.storedFacilities = [facilityStatusItems sortedArrayUsingComparator:^NSComparisonResult(FacilityStatus* _Nonnull obj1, FacilityStatus*  _Nonnull obj2) {
            // sort result alphabetical by station name and then by description
            NSComparisonResult res = [[[FacilityStatusManager client] stationNameForStationNumber:obj1.stationNumber.description] compare:[[FacilityStatusManager client] stationNameForStationNumber:obj2.stationNumber.description]];
            if(res == NSOrderedSame){
                return [obj1.shortDescription compare:obj2.shortDescription];
            } else {
                return res;
            }
        }];
        if (!self.showUebersicht) {
            self.facilities = self.storedFacilities;
            self.selectedRow = [NSIndexPath indexPathForRow:-1 inSection:-1];
        }
        [self.tableView reloadData];
    } failureBlock:^(NSError *bhfError) {
        // NSLog(@"error: %@",bhfError);
        NSString *errorHeadline = @"Bahnhof live";
        NSString *errorMessage = @"Die Aufzugsdaten konnten nicht geladen werden. Bitte versuchen Sie es später erneut.";
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:errorHeadline message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];

    }];
}

- (void)toggleList:(MBSwitch *)sender {
    self.showUebersicht = sender.on;
    self.selectedRow = [NSIndexPath indexPathForRow:-1 inSection:-1];
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

    }
}

#pragma mark MBFacilityTableViewCellDelegate
- (void)facilityCell:(MBFacilityTableViewCell *)cell removesFacility:(FacilityStatus *)status {
    [[FacilityStatusManager client] removeFromFavorites:status.equipmentNumber.description];
    [self updateStoredFacilities];
}

- (void)facilityCell:(MBFacilityTableViewCell *)cell addsFacility:(FacilityStatus *)status {
    
    [[FacilityStatusManager client] enablePushForFacility:status.equipmentNumber.description stationNumber:self.station.mbId.description stationName:self.station.title];
    [self updateStoredFacilities];
}

#pragma mark MBMapViewControllerDelegate

-(NSArray<NSString *> *)mapFilterPresets{
    return @[ PRESET_ELEVATORS ];
}

-(id)mapSelectedPOI{
    NSInteger actualIndex = self.selectedRow.row;
    if (!self.showUebersicht) {
        actualIndex -= 1;
    }
    if(actualIndex >= 0){
        return [self.facilities objectAtIndex:actualIndex];
    }
    return self.facilities.firstObject;
}

@end
