// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBNews.h"
#import "MBStation.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBNewsContainerViewController : UIViewController

@property(nonatomic,strong) NSArray<MBNews*>* newsList;
@property(nonatomic,strong) MBStation* station;
@end

NS_ASSUME_NONNULL_END
