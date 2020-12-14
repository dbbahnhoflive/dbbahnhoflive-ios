// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MBStationOccupancyDropdownMenuView;

@protocol MBStationOccupancyDropdownMenuViewDelegate <NSObject>

- (void)changeDayTo:(NSInteger)index fromDropdown:(MBStationOccupancyDropdownMenuView*)dropdown;
-(void)closeDropDown:(MBStationOccupancyDropdownMenuView*)dropdown;

@end

@interface MBStationOccupancyDropdownMenuView : UIView
-(instancetype)initWithWeekday:(NSInteger)weekday today:(NSInteger)today;
@property(nonatomic,weak) id<MBStationOccupancyDropdownMenuViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
