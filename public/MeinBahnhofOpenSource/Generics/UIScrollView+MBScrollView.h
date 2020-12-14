// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>

@interface UIScrollView (MBScrollView)

- (void) resizeToFitContent;
- (CGSize) calculateContentSize;
- (CGSize) calculateContentSizeHorizontally;

@end
