// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "DBSwitch.h"

@interface MBSettingsTableViewCell : UITableViewCell

@property(nonatomic,strong) UILabel* mainTitleLabel;
@property(nonatomic,strong) UILabel* subTitleLabel;
@property(nonatomic,strong) UIImageView* mainIcon;
@property(nonatomic,strong) DBSwitch* aSwitch;
@property(nonatomic) BOOL showDetails;

@end
