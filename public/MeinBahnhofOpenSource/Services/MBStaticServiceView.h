// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBService.h"
#import "MBTextView.h"
#import "MBDetailViewDelegate.h"
#import "MBStation.h"

@interface MBStaticServiceView : UIView

@property (nonatomic, weak) id<MBDetailViewDelegate> delegate;
- (instancetype) initWithService:(MBService*)service station:(MBStation*)station viewController:(UIViewController*)vc fullscreenLayout:(BOOL)fullscren andFrame:(CGRect)frame;

-(NSInteger)layoutForSize:(NSInteger)frameWidth;

@end
