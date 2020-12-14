// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "POIFilterItem.h"

@class MBPoiFilterView;


@protocol MBPoiFilterViewDelegate <NSObject>

- (void) poiFilterWantsClose:(MBPoiFilterView*)view;
- (void) poiFilterDidChangeFilter:(MBPoiFilterView*)view;

@end

@interface MBPoiFilterView : UIView

-(instancetype)initWithFrame:(CGRect)frame categories:(NSArray*)categories;

@property (nonatomic, weak) id<MBPoiFilterViewDelegate> delegate;

-(void)animateInitialView;

-(NSArray*)currentFilterCategories;

@end
