// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>

@class MBContentSearchResult;

@interface MBServiceListTableViewController : UITableViewController

- (instancetype)initWithItem:(id)item;

@property (nonatomic, strong) NSString *trackingTitle;
@property (nonatomic, strong) MBContentSearchResult* searchResult;


@end
