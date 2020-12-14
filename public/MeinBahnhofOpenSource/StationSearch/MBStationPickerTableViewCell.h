// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBPTSStationFromSearch.h"

@class MBStationPickerTableViewCell;

@protocol MBStationPickerTableViewCellDelegate <NSObject>

@optional
- (void) stationPickerCell:(MBStationPickerTableViewCell*)cell changedFavStatus:(BOOL)favStatus;
- (void) stationPickerCellDidLongPress:(MBStationPickerTableViewCell*)cell;
- (void) stationPickerCellDidTapDeparture:(MBStationPickerTableViewCell*)cell;

@end

@interface MBStationPickerTableViewCell : UITableViewCell

@property(nonatomic,strong) MBPTSStationFromSearch* station;
@property(nonatomic,weak) id<MBStationPickerTableViewCellDelegate> delegate;
@property(nonatomic) BOOL showDetails;
@property(nonatomic) BOOL showDistance;

@end
