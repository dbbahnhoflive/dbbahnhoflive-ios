// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBParkingTableViewController.h"
#import "MBMapViewController.h"
#import "MBParkingExpandableTableViewCell.h"
#import "MBParkingInfoView.h"
#import "MBStationNavigationViewController.h"
#import "MBParkingManager.h"
#import "MBSingleParkingOverviewViewController.h"
#import "MBStationTabBarViewController.h"
#import "MBRootContainerViewController.h"
#import "MBParkingOccupancyManager.h"
#import "MBTutorialManager.h"
#import "MBRoutingHelper.h"
#import "MBUIHelper.h"
#import "MBTrackingManager.h"
#import "MBStation.h"

@interface MBParkingTableViewController () <MBMapViewControllerDelegate, MBParkingInfoDelegate>
@property (nonatomic, strong) NSIndexPath *selectedRow;
@property (nonatomic, assign) CGFloat additionalHeightForExpandedCell;
@property(nonatomic,strong) NSArray* parkingList;

@end

@implementation MBParkingTableViewController

-(instancetype)initWithStation:(MBStation*)station{
    self = [super init];
    if(self){
        self.trackingTitle = @"parkplaetze";
        self.parkingList = station.parkingInfoItems;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [MBTrackingManager trackStatesWithStationInfo:@[@"d1", self.trackingTitle]];

    [MBUIViewController addBackButtonToViewController:self andActionBlockOrNil:nil];

    self.title =  @"Parkplätze";
    self.selectedRow = [NSIndexPath indexPathForRow:-1 inSection:-1];
    [self.tableView registerClass:[MBParkingExpandableTableViewCell class] forCellReuseIdentifier:@"Cell"];
    self.tableView.backgroundColor = [UIColor db_f0f3f5];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 80, 0)];

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];

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
    
    [[MBTutorialManager singleton] displayTutorialIfNecessary:MBTutorialViewType_D1_Parking withOffset:60];
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[MBTutorialManager singleton] hideTutorials];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MBParkingExpandableTableViewCell *tableCell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (self.selectedRow && self.selectedRow.row == indexPath.row) {
        self.selectedRow = [NSIndexPath indexPathForRow:-1 inSection:-1];
        tableCell.expanded = NO;
        self.additionalHeightForExpandedCell = 0;
    } else {
        [[MBTutorialManager singleton] markTutorialAsObsolete:MBTutorialViewType_D1_Parking];
        
        self.selectedRow = indexPath;
        for (MBParkingExpandableTableViewCell *cell in [tableView visibleCells]) {
            cell.expanded = NO;
        }
        tableCell.expanded = YES;
        self.additionalHeightForExpandedCell = tableCell.bottomViewHeight + 4.0;
    }
    [self.tableView reloadData];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat res = [indexPath isEqual:self.selectedRow] ? 88.0 + self.additionalHeightForExpandedCell : 88.0;
    return res;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.parkingList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MBParkingExpandableTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.item = [self.parkingList objectAtIndex:indexPath.row];
    cell.delegate = self;
    cell.expanded = self.selectedRow.row == indexPath.row;

    return cell;
}

#pragma mark MBParkingInfoDelegate
- (void)didOpenTarifForParking:(MBParkingInfo *)parking {
    MBSingleParkingOverviewViewController * tarif = [[MBSingleParkingOverviewViewController alloc] init];
    tarif.title = @"Tarif";
    tarif.showTarif = YES;
    tarif.parking = parking;
    [MBRootContainerViewController presentViewControllerAsOverlay:tarif];
}

- (void)didOpenOverviewForParking:(MBParkingInfo *)parking {
    MBSingleParkingOverviewViewController * overview = [[MBSingleParkingOverviewViewController alloc] init];
    overview.title = @"Übersicht";
    overview.showTarif = NO;
    overview.parking = parking;
    [MBRootContainerViewController presentViewControllerAsOverlay:overview];
}

- (void)didStartNavigationForParking:(MBParkingInfo *)parking {
    [MBTrackingManager trackActionsWithStationInfo:@[@"connection", @"parking", @"directions"]];
    if(!CLLocationCoordinate2DIsValid(parking.location)){
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Hinweis" message:@"Für diese Einrichtung liegen keine Ortsdaten vor." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    [MBRoutingHelper showRoutingForParking:parking fromViewController:self];
}


//refreshing
-(void)refresh:(UIRefreshControl*)refresh{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        dispatch_group_t group = dispatch_group_create();
        
        for(MBParkingInfo* parkingInfo in self.parkingList){
            if(parkingInfo.hasPrognosis){
                NSString* num = parkingInfo.idValue;
                // NSLog(@"request occupancy for id %@",num);
                dispatch_group_enter(group);
                
                [[MBParkingOccupancyManager client] requestParkingOccupancy:num success:^(NSNumber *allocationCategory) {
                    //update allocationCategory
                    parkingInfo.allocationCategory = allocationCategory;
                    
                    // NSLog(@"request occupancy done for id %@",num);
                    dispatch_group_leave(group);
                    
                } failureBlock:^(NSError *error) {
                    //ignore
                    // NSLog(@"request occupancy failed for id %@, %@",num,error);
                    dispatch_group_leave(group);
                }];
                
            }
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            // NSLog(@"refresh end");
            //we have an autolayout issue when a cell is extended - quick fix: close!
            for (MBParkingExpandableTableViewCell *cell in [self.tableView visibleCells]) {
                cell.expanded = NO;
            }
            self.selectedRow = [NSIndexPath indexPathForRow:-1 inSection:-1];
            self.additionalHeightForExpandedCell = 0;
            [self.refreshControl endRefreshing];
            [self.tableView reloadData];
        });
        
    });
}


#pragma mark MBMapViewControllerDelegate

-(NSArray<NSString *> *)mapFilterPresets{
    return @[ PRESET_PARKING ];
}

-(id)mapSelectedPOI{
    if (self.selectedRow.row >= 0) {
        return [self.parkingList objectAtIndex:self.selectedRow.row];
    } else {
        return self.parkingList.firstObject;
    }
}

@end
