// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBUIViewController.h"
#import "MBTextView.h"

#import "MBService.h"

#import "MBDetailViewDelegate.h"

#import "MBStaticServiceView.h"
#import "MBMapViewController.h"

@interface MBDetailViewController : MBUIViewController <MBDetailViewDelegate,MBMapViewControllerDelegate>

@property (nonatomic, strong) NSArray *levels;
@property (nonatomic, assign) BOOL indoorNavigationEnabled;

- (instancetype) initWithStation:(MBStation*)station service:(MBService*)service;

@end
