// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (MBString)

- (NSMutableAttributedString*) attributedHtmlString;
- (NSMutableAttributedString*) rawHtmlString;

- (CGSize) calculateSizeConstrainedTo:(CGSize)constraints;
- (CGSize) calculateSizeConstrainedTo:(CGSize)constraints andFont:(UIFont*)font;

- (NSAttributedString*) convertFonts:(NSDictionary*)options;

- (NSString *)MD5String;

- (CGFloat)fontSizeWithFont:(UIFont *)font constrainedToSize:(CGSize)size;

@end
