// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <UIKit/UIKit.h>

#define STATION_SEARCH_PLACEHOLDER @"Suchen Sie etwas am Bahnhof?"

NS_ASSUME_NONNULL_BEGIN

@interface MBContentSearchButton : UIButton
@property(nonatomic,strong) UIView* contentSearchButtonShadow;
-(void)layoutForScreenWidth:(NSInteger)w;
@end

NS_ASSUME_NONNULL_END
