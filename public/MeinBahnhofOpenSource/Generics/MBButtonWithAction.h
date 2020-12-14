// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>

typedef void (^MBButtonActionBlock)(void);


@interface MBButtonWithAction : UIButton

@property(nonatomic,copy) MBButtonActionBlock actionBlock;

@end
