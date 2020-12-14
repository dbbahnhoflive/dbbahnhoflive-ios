// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MBStationOccupancyDayView;
@class MBStation;
@class MBStationOccupancy;

@protocol MBStationOccupancyDayViewDelegate <NSObject>

- (void)openDropdownFromView:(UIView *)btn inDayView:(MBStationOccupancyDayView*)view;

@end

@interface MBStationOccupancyDayView : UIView
-(instancetype)initWithWeekday:(NSInteger)weekday isToday:(BOOL)isToday;
-(void)loadData:(MBStationOccupancy*)occupancy;
@property(nonatomic,weak) id<MBStationOccupancyDayViewDelegate> delegate;

+(NSArray*)weekdays;
+(NSString*)weekdayToday;

@end

NS_ASSUME_NONNULL_END
