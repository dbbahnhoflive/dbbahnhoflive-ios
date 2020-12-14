// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "POIFilterItem.h"

@class MBPoiFilterContentView;

@protocol MBPoiFilterContentViewDelegate <NSObject>

- (void) poiContent:(MBPoiFilterContentView*)view didSelectCategory:(POIFilterItem*)item;
- (void) poiContent:(MBPoiFilterContentView*)view didToggleAll:(BOOL)selected;
- (void) poiContent:(MBPoiFilterContentView*)view didChangeCategory:(POIFilterItem*)item;

@end


@interface MBPoiFilterContentView : UIView

@property(nonatomic,strong) POIFilterItem* parentCategory;
@property (nonatomic, strong) NSArray *categories;

-(instancetype)initWithFrame:(CGRect)frame items:(NSArray*)items parent:(POIFilterItem*)parent;
-(void)reloadData;
@property(nonatomic,weak) id<MBPoiFilterContentViewDelegate> delegate;

@end
