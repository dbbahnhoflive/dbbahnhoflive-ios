// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>

@class MBTimeTableFilterViewCell;
@protocol MBTimeTableFilterViewCellDelegate <NSObject>

- (void)filterCellWantsToFilter;

@optional
- (void)filterCell:(MBTimeTableFilterViewCell *)cell setsAbfahrt:(BOOL)abfahrt;

@end

@interface MBTimeTableFilterViewCell : UITableViewCell

@property (nonatomic, weak) id<MBTimeTableFilterViewCellDelegate> delegate;
@property (nonatomic, assign) BOOL filterOnly;
@property (nonatomic, assign) BOOL filterActive;
-(void)setFilterHidden:(BOOL)hidden;
-(void)switchToDeparture;
-(void)switchToArrival;
@end
