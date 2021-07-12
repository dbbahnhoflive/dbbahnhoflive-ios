// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: -
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MBStation;

@interface MBPlatformAccessibilityView : UIView

@property(nonatomic,weak) UIViewController* viewController;

-(instancetype)initWithFrame:(CGRect)frame station:(MBStation*)station;
@end

NS_ASSUME_NONNULL_END
