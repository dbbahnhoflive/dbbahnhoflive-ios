// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBUIViewController.h"
#import "MBTextView.h"

@interface MBImprintViewController : MBUIViewController

@property (nonatomic, assign) BOOL openAsModal;
@property (nonatomic, strong) NSString *url;

@end
