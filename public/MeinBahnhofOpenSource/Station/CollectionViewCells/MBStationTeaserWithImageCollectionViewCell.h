// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBStationCollectionViewCell.h"
#import "MBStationKachel.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBStationTeaserWithImageCollectionViewCell : MBStationCollectionViewCell

-(void)setKachel:(MBStationKachel *)kachel;

@end

NS_ASSUME_NONNULL_END
