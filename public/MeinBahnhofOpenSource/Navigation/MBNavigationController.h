// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>

@interface MBNavigationController : UINavigationController <UIGestureRecognizerDelegate, UIBarPositioningDelegate, UINavigationBarDelegate>

@property (nonatomic, strong) UIColor *navigationBarColor;
@property (nonatomic, assign) BOOL swipeBackGestureEnabled;
@property (nonatomic, assign) BOOL rotationEnabled;


- (void) showLaunchImage;
- (void) hideLaunchImage;


@end
