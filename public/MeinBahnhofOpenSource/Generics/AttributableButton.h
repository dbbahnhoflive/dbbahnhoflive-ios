// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <UIKit/UIKit.h>

@interface AttributableButton : UIButton

@property (nonatomic, strong) NSString *actionValue;
@property (nonatomic, strong) NSString *actionType;

@end
