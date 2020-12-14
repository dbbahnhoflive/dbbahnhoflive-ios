// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import "MBTimeTableFilterViewCell.h"
#import "MBTimetableViewController.h"

@class HafasDeparture;

@interface MBHafasTimetableDataSource : NSObject <UITableViewDataSource>

@property (nonatomic,strong) NSDate* lastRequestedDate;
@property (nonatomic, strong) NSIndexPath* selectedRow;
@property (nonatomic, weak) MBTimetableViewController *viewController;
@property (nonatomic, weak) id<MBTimeTableFilterViewCellDelegate> delegate;
@property (nonatomic, strong) NSString *cellIdentifier;
@property (nonatomic, strong) NSString *cellIdentifierHeader;
@property (nonatomic, strong) NSArray<HafasDeparture*> *hafasDepartures;
@property (nonatomic, strong) NSArray *hafasDeparturesByDay;

@end
