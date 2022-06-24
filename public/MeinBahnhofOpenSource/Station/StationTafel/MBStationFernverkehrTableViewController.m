// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBStationFernverkehrTableViewController.h"
#import "MBStationTafelTableViewCell.h"
#import "MBUIHelper.h"

@interface MBStationFernverkehrTableViewController ()

@end

@implementation MBStationFernverkehrTableViewController

- (instancetype)initWithTrains:(NSArray *)trains {
    self = [super initWithStyle:UITableViewStylePlain];
    self.trains = trains;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.userInteractionEnabled = YES;
    [self.tableView registerClass:[MBStationTafelTableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Empty"];
    //self.tableView.rowHeight = 60.0;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.userInteractionEnabled = NO;
    if (@available(iOS 11.0, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        // Fallback on earlier versions
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if (nil != parent) {
        [self.tableView reloadData];
    }
}

#pragma mark - Table view data source

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *labelWrapper = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 50.0)];
    labelWrapper.backgroundColor = [UIColor clearColor];
    
    UIView* grayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 50)];
    grayView.backgroundColor = [UIColor whiteColor];
    [labelWrapper addSubview:grayView];
    
    UIView* line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 2)];
    line.backgroundColor = [UIColor db_mainColor];
    [grayView addSubview:line];
    [line setGravityBottom:4];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 10.0, labelWrapper.frame.size.width - 16.0, 20.0)];
    label.font = [UIFont db_BoldSixteen];
    label.textColor = [UIColor db_333333];
    label.text = self.title;
    [labelWrapper addSubview:label];
    
    return labelWrapper;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50.0;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(self.trains && self.trains.count == 0){
        return 100;
    }
    return 50.0+10;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(self.trains && self.trains.count == 0){
        return 1;
    }
    return self.trains.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.trains && self.trains.count == 0){
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Empty" forIndexPath:indexPath];
        cell.textLabel.text = @"Daten nicht verfügbar.";
        cell.textLabel.font = [UIFont db_RegularFourteen];
        cell.textLabel.textColor = [UIColor db_mainColor];
        cell.imageView.image = [UIImage db_imageNamed:@"app_error"];
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        return cell;
    }
    MBStationTafelTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    // Configure the cell...
    id item = [self.trains objectAtIndex:indexPath.row];
    if ([item isKindOfClass:[Stop class]]) {
        cell.stop = item;
    } else {
        cell.hafas = item;
    }
    
    return cell;
}

@end
