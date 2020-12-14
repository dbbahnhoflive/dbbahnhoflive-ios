// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "NSString+MBString.h"

@interface MBLabel : UILabel

//@property (nonatomic, strong) NSString *htmlString;

//- (void) convertFonts;
+ (MBLabel *)labelWithTitle:(NSString *)title andText:(NSString *)text;

@end
