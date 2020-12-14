// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "Stop.h"
#import "HafasDeparture.h"

@interface MBStationTafelTableViewCell : UITableViewCell

@property (nonatomic, strong) Stop *stop;
@property (nonatomic, strong) Event *event;
@property (nonatomic, strong) HafasDeparture *hafas;

@end
