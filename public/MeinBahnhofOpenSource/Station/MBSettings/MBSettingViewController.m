// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBSettingViewController.h"
#import "MBStationNavigationViewController.h"
#import "MBSettingsTableViewCell.h"
#import "MBFavoriteStationManager.h"
#import "MBTutorialManager.h"
#import "MBStationSearchViewController.h"
#import "MBUIHelper.h"
#import "MBTrackingManager.h"
#import "FacilityStatusManager.h"
#import "MBProgressHUD.h"

@interface MBSettingViewController ()<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic,strong) UITableView* settingTableView;
@property(nonatomic,strong) NSMutableArray<MBStationFromSearch*>* favStations;

@end

@implementation MBSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor db_f0f3f5];
    [MBUIViewController addBackButtonToViewController:self andActionBlockOrNil:nil];

    
    if ([self.navigationController isKindOfClass:[MBStationNavigationViewController class]]) {
        [(MBStationNavigationViewController *)self.navigationController hideNavbar:NO];
        [(MBStationNavigationViewController *)self.navigationController showBackgroundImage:NO];
        [(MBStationNavigationViewController *)self.navigationController setShowRedBar:YES];
    }

    self.settingTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.sizeWidth, self.view.sizeHeight) style:UITableViewStyleGrouped];
    [self.settingTableView registerClass:MBSettingsTableViewCell.class forCellReuseIdentifier:@"cell"];
    self.settingTableView.delegate = self;
    self.settingTableView.dataSource = self;
    self.settingTableView.backgroundColor = [UIColor db_f0f3f5];
    self.settingTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.settingTableView setContentInset:UIEdgeInsetsMake(0, 0, 80, 0)];

    [self.view addSubview:self.settingTableView];
        
    self.favStations = [[[MBFavoriteStationManager client] favoriteStationsList] mutableCopy];
    //is current station in list?
    BOOL currentStationIsFavorite = NO;
    for(MBStationFromSearch* dict in self.favStations){
        if(dict.stationId && [self.currentStation.mbId isEqualToNumber:dict.stationId]){
            currentStationIsFavorite = YES;
            break;
        }
    }
    if(!currentStationIsFavorite){
        MBStationFromSearch* s = [MBStationFromSearch new];
        s.title = self.currentStation.title;
        s.stationId = self.currentStation.mbId;
        s.eva_ids = self.currentStation.stationEvaIds;
        s.isOPNVStation = self.currentStation.mbId == nil;
        s.coordinate = self.currentStation.positionAsLatLng;
        [self.favStations insertObject:s atIndex:0];
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [MBTrackingManager trackStatesWithStationInfo:@[@"d2", @"einstellungen"]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

-(void)didBecomeActive:(id)sender{
    [self.settingTableView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.settingTableView.frame = self.view.bounds;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(section == 0){
        return self.favStations.count;
    }
    return 1+1;//Tipps+Push
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 156+4;
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 43;
}
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView* header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.sizeWidth, 43)];
    header.backgroundColor = [UIColor db_f0f3f5];
    UILabel* title = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, tableView.sizeWidth, 43)];
    title.backgroundColor =[UIColor clearColor];
    title.textColor = [UIColor db_787d87];
    title.font = [UIFont db_RegularFourteen];
    switch(section){
        case 0:
            title.text = @"Favoriten verwalten";
            break;
        case 1:
            title.text = @"Benachrichtigungen verwalten";
            break;
    }
    [header addSubview:title];
    return header;
}
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    cell.backgroundColor = [UIColor db_f0f3f5];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    MBSettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    if(indexPath.section == 0){
        cell.mainIcon.image = [UIImage db_imageNamed:@"app_bahnhof"];
        MBStationFromSearch* dict = self.favStations[indexPath.row];
        cell.mainTitleLabel.text = dict.title;
        cell.subTitleLabel.text = @"Als Favorit hinzugefügt";
    } else if(indexPath.section == 1) {
        if(indexPath.row == 0){
            cell.mainTitleLabel.text = @"Tipps & Hinweise";
            cell.mainIcon.image = [UIImage db_imageNamed:@"setting_Tips"];
            cell.subTitleLabel.text = @"Anzeigen";
        } else {
            cell.mainTitleLabel.text = @"Push-Mitteilungen";
            cell.mainIcon.image = [UIImage db_imageNamed:@"setting_Push"];
            cell.subTitleLabel.text = @"Push-Mitteilungen erhalten";
        }
    }
    
    cell.aSwitch.data = indexPath;
    [cell.aSwitch removeTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [cell.aSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.showDetails = YES;
        
    if(indexPath.section == 0){
        MBStationFromSearch* dict = self.favStations[indexPath.row];
        cell.aSwitch.on = [[MBFavoriteStationManager client] isFavorite:dict];
    } else if(indexPath.section == 1) {
        if(indexPath.row == 0){
            cell.aSwitch.on = ![MBTutorialManager singleton].userDisabledTutorials;
        } else {
            cell.aSwitch.on = FacilityStatusManager.client.isGlobalPushActive && FacilityStatusManager.client.isSystemPushActive;
        }
    }

    cell.accessibilityLabel = [NSString stringWithFormat:@"%@. %@: %@",cell.mainTitleLabel.text,cell.subTitleLabel.text,cell.aSwitch.on ? @"Ein":@"Aus"];

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MBSettingsTableViewCell* cell = (MBSettingsTableViewCell*) [tableView cellForRowAtIndexPath:indexPath];
    cell.aSwitch.on = !cell.aSwitch.on;
    [self stateChangedForIndexPath:indexPath isOn:cell.aSwitch.on];
    [self.settingTableView reloadData];
}

-(void)switchChanged:(DBSwitch*)sw{
    NSIndexPath* path = sw.data;
    BOOL isOn = sw.on;
    [self stateChangedForIndexPath:path isOn:isOn];
}
-(void)stateChangedForIndexPath:(NSIndexPath*)path isOn:(BOOL)isOn{
    if(path.section == 0){
        MBStationFromSearch* dict = self.favStations[path.row];
        if(isOn){
            [[MBFavoriteStationManager client] addStation:dict];
        } else {
            [[MBFavoriteStationManager client] removeStation:dict];
        }
    } else if(path.section == 1) {
        if(path.row == 0){
            [MBTutorialManager singleton].userDisabledTutorials = !isOn;
        } else {
            //global push setting changed
            if(!FacilityStatusManager.client.isSystemPushActive){
                [self.settingTableView reloadData];
                [self presentViewController:FacilityStatusManager.client.alertForPushNotActive animated:YES completion:nil];
                return;
            }
            
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];

            [FacilityStatusManager.client setGlobalPushActive:isOn completion:^(NSError * error) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                if(error){
                    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Hinweis" message:@"Der Status wurde nicht für alle Aufzüge gespeichert. Bitte versuchen Sie es später erneut." preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                    [self presentViewController:alert animated:YES completion:nil];
                }
            }];
        }
    }
}


@end
