// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBStationTabBarView.h"

@interface MBStationTabBarView()

@property (nonatomic) NSUInteger selectedIndex;
@property (nonatomic, strong) NSMutableArray *tabs;
@end

@implementation MBStationTabBarView

- (instancetype)initWithFrame:(CGRect)frame tabBarImages:(NSArray *)templateImages titles:(NSArray *)titles{
    self = [super initWithFrame:frame];
    // create tab views in order of the array
    NSMutableArray *mTabs = [NSMutableArray array];
    NSInteger i = 0;
    for (UIImage *templateImage in templateImages) {
        NSString* title = titles[i];
        MBStationTabView *tabView = [[MBStationTabView alloc] initWithFrame:CGRectZero templateImage:templateImage tabIndex:i title:title];
        tabView.delegate = self;
        [mTabs addObject:tabView];
        [self addSubview:tabView];
        i++;
    }
    self.tabs = mTabs;
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat tabsWidth = self.tabs.count * 50.0 + (self.tabs.count - 1) * 20.0;
    CGFloat stepSize = floor(tabsWidth / self.tabs.count);
    CGFloat leftSlack = (self.frame.size.width - tabsWidth) / 2.0;
    for (MBStationTabView *tab in self.tabs) {
        NSUInteger index = [self.tabs indexOfObject:tab];
        CGRect tabFrame = CGRectMake(leftSlack + index * stepSize, 5.0, stepSize, 50.0);
        tab.frame = tabFrame;
    }
}

- (void)selectTabIndex:(NSUInteger)index {
    if (index != self.selectedIndex) {
        self.selectedIndex = index;
        for (MBStationTabView *tab in self.tabs) {
            if (tab.index == index) {
                tab.selected = YES;
            } else {
                tab.selected = NO;
            }
        }
    }
}

- (void)disableTabIndex:(NSUInteger)index {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"index == %ld", (long)index];
    NSArray *filteredTabs = [self.tabs filteredArrayUsingPredicate:predicate];
    MBStationTabView *tab = filteredTabs.lastObject;
    [tab setEnabled:NO];
//    [tab removeFromSuperview];
//    [self.tabs removeObject:tab];
}
- (void)enableTabIndex:(NSUInteger)index {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"index == %ld", (long)index];
    NSArray *filteredTabs = [self.tabs filteredArrayUsingPredicate:predicate];
    MBStationTabView *tab = filteredTabs.lastObject;
    [tab setEnabled:YES];
}

#pragma mark MBStationTabViewDelegate
- (void)didSelectTabAtIndex:(NSUInteger)index {
    if (nil != self.delegate) {
        if ([self.delegate respondsToSelector:@selector(didSelectTabAtIndex:)]) {
            [self.delegate didSelectTabAtIndex:index];
        }
    }
}

@end
