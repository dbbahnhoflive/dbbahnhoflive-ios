// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBExpandableTableViewCell.h"
#import "MBNews.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBCouponTableViewCell : MBExpandableTableViewCell

@property(nonatomic,strong) MBNews* newsItem;

-(NSInteger)expandableHeight;
@end

NS_ASSUME_NONNULL_END
