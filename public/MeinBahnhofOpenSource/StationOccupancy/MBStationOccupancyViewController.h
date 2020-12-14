// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <UIKit/UIKit.h>
#import "MBStation.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBStationOccupancyViewController : UIViewController

@property(nonatomic,strong) MBStation* station;
-(void)loadData;
@end

NS_ASSUME_NONNULL_END
