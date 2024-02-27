// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBExpandableTableViewCell.h"
#import "MBShopDetailCellView.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBShopPoiTableViewCell : MBExpandableTableViewCell

@property(nonatomic,strong) RIMapPoi* _Nullable poiItem;
@property (nonatomic, strong)  MBShopDetailCellView * _Nullable shopDetailView;
// only visible in expanded view, and when the shop contains contact information
@property (nonatomic, strong) UIView *contactAddonView;

@end

NS_ASSUME_NONNULL_END
