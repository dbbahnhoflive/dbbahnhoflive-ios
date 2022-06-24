// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MBMapConsent : NSObject

+ (MBMapConsent*)sharedInstance;

-(void)showConsentDialogInViewController:(UIViewController*)vc completion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
