// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBStationKachel.h"

@interface MBServiceCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) MBStationKachel *kachel;
@property (nonatomic, strong) UIImage *icon;
@property (nonatomic) BOOL imageAsBackground;


@end
