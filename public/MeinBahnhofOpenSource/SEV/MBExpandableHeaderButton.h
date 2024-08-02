// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MBExpandableHeaderButton : UIButton
- (instancetype)initWithText:(NSString*)text;
@property(nonatomic) BOOL isExpanded;
@end

NS_ASSUME_NONNULL_END
