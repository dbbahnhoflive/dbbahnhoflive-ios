// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>

@protocol MBFacilityDeleteAllTableViewCellDelegate
- (void)deleteAllFacilities;
@end

@interface MBFacilityDeleteAllTableViewCell : UITableViewCell

@property (nonatomic, weak) id<MBFacilityDeleteAllTableViewCellDelegate> delegate;

@end
