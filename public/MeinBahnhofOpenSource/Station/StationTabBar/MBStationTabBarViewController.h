// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBStationTabBarView.h"
#import "MBStation.h"

@protocol MBStationTabBarViewControllerDelegate <NSObject>

- (void)goBackToSearchAnimated:(BOOL)animated;

@end

@interface MBStationTabBarViewController : UIViewController

@property (nonatomic, strong) NSArray *viewControllers;
@property (nonatomic, weak) id<MBStationTabBarViewControllerDelegate> delegate;
@property (nonatomic, strong) MBStationTabBarView *tabBarView;
@property (nonatomic, strong) NSNumber *topSlack;

- (UIViewController *)selectViewControllerAtIndex:(NSUInteger)index;
- (UIViewController *)visibleViewController; 
- (void)disableTabAtIndex:(NSUInteger)index;
- (void)enableTabAtIndex:(NSUInteger)index;
- (void)showTabbar;
- (instancetype)initWithViewControllers:(NSArray *)viewControllers station:(MBStation*)station;

@end
