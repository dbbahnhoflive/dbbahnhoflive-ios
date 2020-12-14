// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBStationTabView.h"

@protocol MBStationTabBarViewDelegate <NSObject>

- (void)didSelectTabAtIndex:(NSUInteger)index;

@end

@interface MBStationTabBarView : UIView <MBStationTabViewDelegate>

@property (nonatomic, weak) id<MBStationTabBarViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame tabBarImages:(NSArray *)templateImages titles:(NSArray*)titles;
- (void)selectTabIndex:(NSUInteger)index;
- (void)disableTabIndex:(NSUInteger)index;
- (void)enableTabIndex:(NSUInteger)index;

@end
