// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>

@class MBStation;

@interface MBParkingTableViewController : UITableViewController

@property (nonatomic, strong) NSString *trackingTitle;

-(MBParkingTableViewController*)initWithStation:(MBStation*)station;

@end
