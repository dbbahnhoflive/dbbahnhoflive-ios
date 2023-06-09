// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>

@interface MBLinkButton : UIButton

@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *value;
@property (nonatomic, strong) NSString *labelText;
@property (nonatomic, strong) UIFont *labelFont;
@property (nonatomic, strong) UIColor *titleColor;


+ (instancetype) buttonWithLeftImage:(NSString*)imageName;
+ (instancetype) buttonWithRightImage:(NSString*)imageName;
+ (instancetype) buttonWithRedLink;
+ (instancetype) boldButtonWithRedLink;
+ (instancetype) boldButtonWithRedExternalLink;
@end
