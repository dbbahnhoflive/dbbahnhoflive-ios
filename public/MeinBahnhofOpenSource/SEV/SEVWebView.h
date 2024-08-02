// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <WebKit/WebKit.h>
#import <UIKit/UIKit.h>
@import WebKit;

NS_ASSUME_NONNULL_BEGIN

@interface SEVWebView : WKWebView
-(void)loadService;
@end

NS_ASSUME_NONNULL_END
