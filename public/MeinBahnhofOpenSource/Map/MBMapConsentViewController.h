// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MBMapConsentViewController : UIViewController
+(void)presentAlertOnViewController:(UIViewController*)vc consentCompletion:(void (^)(void))completion;
@end

NS_ASSUME_NONNULL_END
