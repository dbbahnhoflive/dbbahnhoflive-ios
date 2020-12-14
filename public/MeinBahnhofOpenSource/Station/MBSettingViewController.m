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

@interface MBSettingViewController ()<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic,strong) UITableView* settingTableView;
@property(nonatomic,strong) NSMutableArray<MBPTSStationFromSearch*>* favStations;
@property(nonatomic,strong) NSIndexPath* selectedCell;

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
    
    self.selectedCell = [NSIndexPath indexPathForRow:-1 inSection:-1];
    
    self.favStations = [[[MBFavoriteStationManager client] favoriteStationsList] mutableCopy];
    //is current station in list?
    BOOL currentStationIsFavorite = NO;
    for(MBPTSStationFromSearch* dict in self.favStations){
        if(dict.stationId && [self.currentStation.mbId isEqualToNumber:dict.stationId]){
            currentStationIsFavorite = YES;
            break;
        }
    }
    if(!currentStationIsFavorite){
        MBPTSStationFromSearch* s = [MBPTSStationFromSearch new];
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
    return 1;//Tipps
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section == self.selectedCell.section && indexPath.row == self.selectedCell.row){
        return 156;//maybe more for section 2?
    } else {
        return 84;
    }
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
            title.text = @"Tipps und Hinweise";
            break;
        case 2:
            title.text = @"Suche";
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
        MBPTSStationFromSearch* dict = self.favStations[indexPath.row];
        cell.mainTitleLabel.text = dict.title;
        cell.subTitleLabel.text = @"Als Favorit hinzugefügt";
    } else if(indexPath.section == 1) {
        cell.mainTitleLabel.text = @"Tipps & Hinweise";
        cell.mainIcon.image = [UIImage db_imageNamed:@"tutorialicon"];
        cell.subTitleLabel.text = @"Anzeigen";
    } else {
        cell.mainTitleLabel.text = @"Suchhistorie";
        cell.mainIcon.image = [UIImage db_imageNamed:@"app_lupe"];
        cell.subTitleLabel.text = @"Suchhistorie zurücksetzen";
    }

    [cell.aSwitch removeTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];

    if(self.selectedCell.section == indexPath.section && self.selectedCell.row == indexPath.row){
        cell.showDetails = YES;
        if(indexPath.section == 0){
            MBPTSStationFromSearch* dict = self.favStations[indexPath.row];
            cell.aSwitch.on = [[MBFavoriteStationManager client] isFavorite:dict];
            [cell.aSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        } else if(indexPath.section == 1) {
            cell.aSwitch.on = ![MBTutorialManager singleton].userDisabledTutorials;
            [cell.aSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        } else if(indexPath.section == 2){
            cell.aSwitch.on = NO;
            [cell.aSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        }
    } else {
        cell.showDetails = NO;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}
-(void)switchChanged:(UISwitch*)sw{
    if(self.selectedCell.section == 0){
        MBPTSStationFromSearch* dict = self.favStations[self.selectedCell.row];
        if(sw.on){
            [[MBFavoriteStationManager client] addStation:dict];
        } else {
            [[MBFavoriteStationManager client] removeStation:dict];
        }
    } else if(self.selectedCell.section == 1) {
        [MBTutorialManager singleton].userDisabledTutorials = !sw.on;
    } else {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Suchhistorie" message:@"Möchten Sie die Suchhistorie löschen?" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Abbrechen" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            sw.on = NO;
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Löschen" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:SETTINGS_LAST_SEARCHES];
            sw.on = NO;
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(self.selectedCell.section == indexPath.section && self.selectedCell.row == indexPath.row){
        //deselect and close
        self.selectedCell = [NSIndexPath indexPathForRow:-1 inSection:-1];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else {
        if(self.selectedCell.section >= 0){
            //changed cell
            NSIndexPath* oldSelection =self.selectedCell;
            self.selectedCell = indexPath;
            [tableView reloadRowsAtIndexPaths:@[oldSelection,indexPath] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            //selected initial cell
            self.selectedCell = indexPath;
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

@end
