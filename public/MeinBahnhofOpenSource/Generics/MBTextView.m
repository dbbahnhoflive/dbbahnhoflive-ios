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
    self.dataDetectorTypes = UIDataDetectorTypeNone;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)url inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction
{
    if ([self.delegado respondsToSelector:@selector(didInteractWithURL:)] /*&& ([[url absoluteString] rangeOfString:@"http"].length > 0)*/) {
        [self.delegado didInteractWithURL:url];
        return NO;
    }
    return YES;
}

- (void)resizeForWidth:(NSInteger)width{
    CGSize size = [self sizeThatFits:CGSizeMake(width, NSIntegerMax)];
    [self setSize:CGSizeMake(ceilf(size.width), ceilf(size.height))];
}

@end
