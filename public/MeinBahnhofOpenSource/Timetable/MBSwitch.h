// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>

@interface MBSwitch : UIControl

@property (nonatomic, assign, getter=isOn) BOOL on;

@property (nonatomic, assign) BOOL noShadow;
@property (nonatomic, assign) BOOL noRoundedCorners;
@property (nonatomic, strong) UIFont *activeLabelFont;
@property (nonatomic, strong) UIFont *inActiveLabelFont;
@property (nonatomic, strong) UIColor *activeTextColor;
@property (nonatomic, strong) UIColor *inActiveTextColor;

- (instancetype)initWithFrame:(CGRect)frame onTitle:(NSString *)onTitle offTitle:(NSString *)offTitle onState:(BOOL)onState;

@end
