// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <UIKit/UIKit.h>
#import "MBStationOccupancy.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBStationOccupancyDiagramView : UIView

@property(nonatomic,strong) MBStationOccupancy* occupancy;
@property(nonatomic) NSInteger currentWeekday;

@end

NS_ASSUME_NONNULL_END
