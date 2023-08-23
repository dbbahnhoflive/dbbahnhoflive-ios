// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "UIColor+DBColor.h"
#import "Constants.h"

@implementation UIColor (DBColor)

+ (UIColor*)dbColorWithRGB:(int)rgbValue{
    return [self dbColorWithRGB:rgbValue alpha:1.0];
}
+ (UIColor*)dbColorWithRGB:(int)rgbValue alpha:(int)alpha{
    return [UIColor \
            colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
            green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
            blue:((float)(rgbValue & 0xFF))/255.0 alpha:alpha];
}

+(UIColor*)db_switchOn {
    return [UIColor dbColorWithRGB:0x282D37];
}

+(UIColor*)db_switchOff {
    return [UIColor dbColorWithRGB:0xD7DCE1];
}

+ (UIColor *)db_878c96 { return [UIColor colorWithRed:135./255. green:140./255. blue:150./255. alpha:1]; }
+ (UIColor *)db_e5e5e5 { return [UIColor colorWithRed:229./255. green:229./255. blue:229./255. alpha:1]; }
+ (UIColor *)db_646973 { return [UIColor colorWithRed:100./255.f green:105.f/255.f blue:115.f/255.f alpha:1]; }
+ (UIColor *)db_333333 { return [UIColor colorWithRed:51.f/255.f green:51.f/255.f blue:51.f/255.f alpha:1]; }
+ (UIColor *)db_cccccc { return [UIColor colorWithRed:204./255.f green:204.f/255.f blue:204.f/255.f alpha:1]; }
+ (UIColor *)db_5f5f5f { return [UIColor colorWithRed:95.f/255.f green:95.f/255.f blue:95.f/255.f alpha:1]; }
+ (UIColor *)db_dadada { return [UIColor colorWithRed:218.f/255.f green:218.f/255.f blue:218.f/255.f alpha:1]; }
+ (UIColor *)db_f5f5f5 { return [UIColor colorWithRed:245./255 green:245./255 blue:245./255 alpha:1];}

+ (UIColor *)db_787d87 { return [UIColor colorWithRed:120./255. green:125./255. blue:135./255. alpha:1];}

//Grün
+(UIColor*)db_green { return [UIColor dbColorWithRGB:0x508B1B]; }
//Rot
+ (UIColor *)db_mainColor { return
    [Constants dbMainColor];
}

+ (UIColor *)db_f0f3f5 { return [UIColor colorWithRed:240./255 green:243./255 blue:245./255 alpha:1];}
+ (UIColor *)db_light_lineColor { return [UIColor colorWithRed:231./255. green:235./255. blue:239./255. alpha:1.]; }

+ (UIColor *)db_f3f5f7 { return [UIColor colorWithRed:243./255 green:245./255 blue:247./255 alpha:1];}
+ (UIColor *)db_HeaderColor { return [UIColor dbColorWithRGB:0xDFE3E7];}
+ (UIColor *)db_GrayButton { return [UIColor dbColorWithRGB:0x787D85];}



// 1
+ (UIColor*)db_firstClass { return [UIColor dbColorWithRGB:0xFFD800]; }
// 2
+ (UIColor*)db_secondClass { return [UIColor db_green]; }
// b
+ (UIColor*)db_restaurant { return [UIColor db_mainColor]; }
// 8
+ (UIColor*)db_luggageCoach { return [UIColor colorWithRed:153./255. green:153./255. blue:153./255. alpha:1];}
// c
+ (UIColor*)db_sleepingCoach { return [UIColor colorWithRed:0 green:115./255. blue:255./255. alpha:1];}
//misc
+ (UIColor*)db_fallback { return [UIColor colorWithRed:255./255. green:97./255. blue:3./255. alpha:1];}

+ (UIColor *)db_grayBackgroundColor { return [UIColor colorWithRed:250./255 green:250./255 blue:250./255 alpha:1]; }

+ (UIColor *)db_lightGrayTextColor { return [UIColor colorWithRed:135./255. green:140./255. blue:150./255. alpha:1]; }

@end
