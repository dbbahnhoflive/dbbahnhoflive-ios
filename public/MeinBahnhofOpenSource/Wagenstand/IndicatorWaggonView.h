// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>

@class Waggon;

@interface IndicatorWaggonView : UIView

@property (nonatomic, assign) BOOL highlighted;
@property (nonatomic, strong) NSString *section;

- (instancetype) initWithFrame:(CGRect)frame andWaggon:(Waggon*)waggon;

@end
