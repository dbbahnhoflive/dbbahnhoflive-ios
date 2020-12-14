// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "VenueExtraField.h"
#import "MBDetailViewDelegate.h"

@interface MBContactInfoView : UIView

@property (nonatomic, weak) id<MBDetailViewDelegate>delegate;

- (instancetype)initWithExtraField:(VenueExtraField *)extraField;
- (void)updateButtonConstraints;

@end
