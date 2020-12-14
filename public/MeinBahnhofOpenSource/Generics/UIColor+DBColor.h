// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>

@interface UIColor (DBColor)

+ (UIColor*)dbColorWithRGB:(int)rgbValue;

+ (UIColor *)db_e5e5e5;
+ (UIColor *)db_a5a6ac;
+ (UIColor *)db_646973;
+ (UIColor *)db_878c96;
+ (UIColor *)db_333333;
+ (UIColor *)db_f5f5f5;
+ (UIColor *)db_5f5f5f;
+ (UIColor *)db_dadada;
+ (UIColor *)db_aaca57;
+ (UIColor *)db_cccccc;

+ (UIColor *)db_76c030;
+ (UIColor *)db_787d87;

+ (UIColor *)db_38a63d;
+ (UIColor *)db_mainColor;

+ (UIColor *)db_eaeef1;
+ (UIColor *)db_f0f3f5;

+ (UIColor *)db_00415c;
+ (UIColor *)db_0daef2;
+ (UIColor *)db_9edcf7;
+ (UIColor *)db_f3f5f7;
+ (UIColor *)db_HeaderColor;
+ (UIColor *)db_GrayButton;
+ (UIColor *)db_light_lineColor;

+ (UIColor*)db_firstClass;
+ (UIColor*)db_secondClass;
+ (UIColor*)db_restaurant;
+ (UIColor*)db_luggageCoach;
+ (UIColor*)db_sleepingCoach;
+ (UIColor*)db_fallback;

+ (UIColor *)db_grayBackgroundColor;
+ (UIColor *)db_lightGrayTextColor;
+ (UIColor *)db_lightGrayBackgroundColor;

@end
