// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MBStatusImageView : UIImageView

-(void)setStatusActive;
-(void)setStatusInactive;
-(void)setStatusUnknown;

@end

NS_ASSUME_NONNULL_END
