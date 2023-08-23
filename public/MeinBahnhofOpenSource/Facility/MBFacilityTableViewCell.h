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
- (void)facilityCell:(MBFacilityTableViewCell *)cell addsPush:(FacilityStatus *)status;
- (void)facilityCell:(MBFacilityTableViewCell *)cell removesPush:(FacilityStatus *)status;
- (void)facilityCell:(MBFacilityTableViewCell *)cell wantsGlobalPushDialog:(FacilityStatus *)status;
- (void)facilityCell:(MBFacilityTableViewCell *)cell wantsSystemPushDialog:(FacilityStatus *)status;

- (void)facilityCell:(MBFacilityTableViewCell *)cell togglesPushSwitch:(UISwitch*)aSwitch newState:(BOOL)on forFacility:(FacilityStatus *)status;

@end

@interface MBFacilityTableViewCell : UITableViewCell

@property (nonatomic, weak) id<MBFacilityTableViewCellDelegate> delegate;
@property (nonatomic, strong) FacilityStatus *status;
@property (nonatomic, strong) NSString *currentStationName;
@property (nonatomic) BOOL expanded;

@end
