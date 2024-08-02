// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <UIKit/UIKit.h>
#import "MBStation.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBWegbegleitungInfoViewController : UIViewController
-(instancetype)initWithStation:(MBStation*)station;
@property(nonatomic,strong) MBStation* station;
@end

NS_ASSUME_NONNULL_END
