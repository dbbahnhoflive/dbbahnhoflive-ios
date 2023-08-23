// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

@protocol MBDetailViewDelegate <NSObject>

@optional
- (void) didOpenUrl:(NSURL*)url;
- (void) didTapOnPhoneLink:(NSString*)phoneNumber;
- (void) didTapOnEmailLink:(NSString*)mailAddress;

@end
