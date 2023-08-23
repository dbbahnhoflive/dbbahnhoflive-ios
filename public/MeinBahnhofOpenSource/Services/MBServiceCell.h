// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBLabel.h"
#import "MBDetailViewDelegate.h"
#import "MBStaticServiceView.h"
#import "MBExpandableTableViewCell.h"

@interface MBServiceCell : MBExpandableTableViewCell 

@property(nonatomic,strong) MBService* serviceItem;
@property (nonatomic, strong) MBStaticServiceView *staticServiceView;

@end
