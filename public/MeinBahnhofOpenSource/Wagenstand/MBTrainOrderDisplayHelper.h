// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class Stop;
@class MBStation;

@interface MBTrainOrderDisplayHelper : NSObject

-(void)showWagenstandForStop:(Stop *)stop station:(MBStation*)station departure:(BOOL)departure inViewController:(UIViewController*)vc;

@end

NS_ASSUME_NONNULL_END
