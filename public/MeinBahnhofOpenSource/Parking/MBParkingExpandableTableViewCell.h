// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBParkingInfo.h"
#import "MBParkingInfoView.h"

@interface MBParkingExpandableTableViewCell : UITableViewCell <MBParkingInfoDelegate>

@property (nonatomic, strong) MBParkingInfo *item;
@property (nonatomic, weak) id<MBParkingInfoDelegate> delegate;
@property (nonatomic, assign) BOOL expanded;

-(NSInteger)bottomViewHeight;
@end
