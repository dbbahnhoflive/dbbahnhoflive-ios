// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "FacilityStatus.h"

@class MBFacilityTableViewCell;

@protocol MBFacilityTableViewCellDelegate
- (void)facilityCell:(MBFacilityTableViewCell *)cell addsFacility:(FacilityStatus *)status;
- (void)facilityCell:(MBFacilityTableViewCell *)cell removesFacility:(FacilityStatus *)status;
@end

@interface MBFacilityTableViewCell : UITableViewCell

@property (nonatomic, weak) id<MBFacilityTableViewCellDelegate> delegate;
@property (nonatomic, strong) FacilityStatus *status;
@property (nonatomic, strong) NSString *currentStationName;
@property (nonatomic) BOOL expanded;

@end
