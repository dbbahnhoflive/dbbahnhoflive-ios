// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <UIKit/UIKit.h>

@interface MBExpandableTableViewCell : UITableViewCell

@property (nonatomic, assign) BOOL expanded;
-(void)updateStateAfterExpandChange;
@end
