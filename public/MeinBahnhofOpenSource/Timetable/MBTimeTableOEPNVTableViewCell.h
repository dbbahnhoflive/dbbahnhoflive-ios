// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "HafasDeparture.h"

@interface MBTimeTableOEPNVTableViewCell : UITableViewCell

@property (nonatomic, strong) HafasDeparture *hafas;
@property (nonatomic) BOOL expanded;

@end
