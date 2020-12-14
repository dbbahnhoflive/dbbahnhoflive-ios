// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBStationCollectionViewCell.h"
#import "MBStationKachel.h"

@interface MBStationNavigationCollectionViewCell : MBStationCollectionViewCell

@property (nonatomic, strong) MBStationKachel *kachel;
@property (nonatomic, strong) UIImage *icon;
@property (nonatomic) BOOL imageAsBackground;


@end
