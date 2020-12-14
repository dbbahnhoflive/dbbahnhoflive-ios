// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>

@class Wagenstand;
@class Train;

@interface MBWagenstandHeaderRedesigned : UIView

- (instancetype) initWithWagenstand:(Wagenstand*)wagenstand train:(Train*)train andFrame:(CGRect)frame;

-(void)resizeForWidth:(CGFloat)width;

@end
