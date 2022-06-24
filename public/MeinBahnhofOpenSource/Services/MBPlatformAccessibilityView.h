// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: -
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define MB_SERVICE_ACCESSIBILITY_CONFIG_KEY_PLATFORM @"MB_SERVICE_ACCESSIBILITY_CONFIG_KEY_PLATFORM"

@class MBStation;

@interface MBPlatformAccessibilityView : UIView

@property(nonatomic,weak) UIViewController* viewController;

-(instancetype)initWithFrame:(CGRect)frame station:(MBStation*)station platform:(NSString*_Nullable)platform;
@end

NS_ASSUME_NONNULL_END
