// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBTextView.h"
#import "MBUIHelper.h"

@implementation MBTextView

- (instancetype) initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.editable = NO;
        self.dataDetectorTypes = UIDataDetectorTypeLink|UIDataDetectorTypeAddress|UIDataDetectorTypePhoneNumber;
        self.scrollEnabled = NO;
        
        // remove text padding
        self.delegate = self;
        self.textContainer.lineFragmentPadding = 0;
        self.textContainerInset = UIEdgeInsetsZero;
        
        // set style for links
        [self setLinkTextAttributes:@{NSForegroundColorAttributeName: [UIColor db_878c96], NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)}];
    }
    return self;
}

- (void)setHtmlString:(NSString *)htmlString
{
    _htmlString = [htmlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSMutableAttributedString *mutableHTML = [htmlString attributedStringFromHtml];
    self.attributedText = mutableHTML;
}

- (void) convertFonts
{
    NSMutableAttributedString *tempString = [self.attributedText mutableCopy];
    NSRange range = (NSRange){0,[tempString length]};
    [tempString enumerateAttribute:NSFontAttributeName inRange:range options:NSAttributedStringEnumerationReverse usingBlock:^(id value, NSRange range, BOOL *stop) {
        UIFont *replacementFont = nil;
        
        replacementFont = [UIFont db_RegularFourteen];
        
        [tempString addAttribute:NSFontAttributeName value:replacementFont range:range];
        [tempString addAttribute:NSForegroundColorAttributeName value:[UIColor db_333333] range:range];
    }];
    [self setAttributedText:tempString];
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)url inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction
{
    if ([self.delegado respondsToSelector:@selector(didInteractWithURL:)] /*&& ([[url absoluteString] rangeOfString:@"http"].length > 0)*/) {
        [self.delegado didInteractWithURL:url];
        return NO;
    }
    return YES;
}

@end
