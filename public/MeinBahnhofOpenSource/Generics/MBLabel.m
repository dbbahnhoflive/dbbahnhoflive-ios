// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBLabel.h"
#import "MBUIHelper.h"

@implementation MBLabel

//@synthesize htmlString = _htmlString;

- (void)setHtmlString:(NSString *)htmlString
{
    NSMutableAttributedString *mutableHTML = [htmlString attributedHtmlString];
    self.attributedText = mutableHTML;
    self.lineBreakMode = NSLineBreakByWordWrapping;
    
    [self convertFonts];
}

- (void) convertFonts
{
    NSMutableAttributedString *tempString = [self.attributedText mutableCopy];
    NSRange range = (NSRange){0,[tempString length]};
    [tempString enumerateAttribute:NSFontAttributeName inRange:range options:NSAttributedStringEnumerationReverse usingBlock:^(id value, NSRange range, BOOL *stop) {
        UIFont* currentFont = value;
        UIFont *replacementFont = nil;
        
        if ([currentFont.fontName rangeOfString:@"b" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            replacementFont = [UIFont db_RegularSixteen];
        } else {
            replacementFont = [UIFont db_RegularSixteen];
        }
        
        [tempString addAttribute:NSFontAttributeName value:replacementFont range:range];
        [tempString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:range];
    }];
    [self setAttributedText:tempString];
}

+ (MBLabel *)labelWithTitle:(NSString *)title andText:(NSString *)text {
    MBLabel *label = [MBLabel new];
    NSDictionary *titleAttributes = @{NSForegroundColorAttributeName: [UIColor db_333333],
                                      NSFontAttributeName:[UIFont db_BoldFourteen]
                                      };
    NSDictionary *textAttributes = @{NSForegroundColorAttributeName: [UIColor db_333333],
                                     NSFontAttributeName:[UIFont db_RegularFourteen]
                                     };
    NSAttributedString *titleAtt = [[NSAttributedString alloc] initWithString:title
                                                                   attributes:titleAttributes];
    
    NSAttributedString *textAtt = [[NSAttributedString alloc] initWithString:text attributes:textAttributes];
    NSMutableAttributedString *completeText = [[NSMutableAttributedString alloc] initWithAttributedString:titleAtt];
    [completeText appendAttributedString:textAtt];
    label.attributedText = completeText;
    label.numberOfLines = 0;
    
    [label sizeToFit];
    return label;
}

@end
