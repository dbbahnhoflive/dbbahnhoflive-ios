// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBUIViewController.h"
#import "MBParkingInfo.h"
#import "MBTextView.h"
#import "MBOverlayViewController.h"

@interface MBSingleParkingOverviewViewController : MBOverlayViewController <MBTextViewDelegate>

@property(nonatomic,strong) MBParkingInfo* parking;

@property(nonatomic) BOOL showTarif;

@end
