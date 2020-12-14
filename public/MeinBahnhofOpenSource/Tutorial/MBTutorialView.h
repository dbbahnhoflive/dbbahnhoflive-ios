// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>

@class MBTutorial;

@interface MBTutorialView : UIView

@property(nonatomic,strong) MBTutorial* tutorial;
@property(nonatomic) NSInteger viewYOffset;

-(instancetype)initWithTutorial:(MBTutorial*)tutorial;


@end
