// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBNews.h"

@class MBNewsContainerViewController;

NS_ASSUME_NONNULL_BEGIN

@interface MBNewsContainerView : UIView

@property(nonatomic,strong) MBNews* news;
@property(nonatomic,weak) MBNewsContainerViewController* containerVC;

@end

NS_ASSUME_NONNULL_END
