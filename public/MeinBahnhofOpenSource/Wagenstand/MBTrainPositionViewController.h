// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBUIViewController.h"
#import "WagenstandRequestManager.h"
#import "Wagenstand.h"
#import "Waggon.h"
#import "MBStation.h"
#import "SectionIndicatorView.h"

#define NOTIFICATION_USERSETTINGS_REGISTERED @"NOTIFICATION_USERSETTINGS_REGISTERED"

#define WAGENSTAND_QUERY_TYPE @"type"
#define WAGENSTAND_QUERY_NUMBER @"number"
#define WAGENSTAND_QUERY_PLATFORM @"platform"

@interface MBTrainPositionViewController : MBUIViewController <UITableViewDelegate, UITableViewDataSource, SectionIndicatorDelegate>

@property (nonatomic) BOOL isOpenedFromTimetable;
@property (nonatomic, strong) Wagenstand *wagenstand;
@property (nonatomic, strong) NSString *waggonNumber;

@property (nonatomic, strong) NSDictionary* queryValues;


+(void) showWagenstandForUserInfo:(NSDictionary *)userInfo fromViewController:(MBUIViewController*)vc;

@end
