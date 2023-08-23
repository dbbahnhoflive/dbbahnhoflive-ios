// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBUIViewController.h"
#import "MBLabel.h"
#import "MBMapViewController.h"
#import "TimetableManager.h"
#import "HafasRequestManager.h"
#import "MBOPNVStation.h"

@class MBContentSearchResult;

@interface MBTimetableViewController : MBUIViewController <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, MBMapViewControllerDelegate>

@property (nonatomic, strong) MBLabel *lastUpdateLabel;

@property (nonatomic, assign) BOOL embeddedInController;
@property (nonatomic, assign) BOOL departure;

@property (nonatomic, assign) BOOL dbOnly;
@property (nonatomic, assign) BOOL oepnvOnly;
@property (nonatomic, assign) BOOL includeLongDistanceTrains;
@property (nonatomic) BOOL showFernverkehr;
@property(nonatomic) BOOL trackToggleChange;

@property (nonatomic, strong) MBOPNVStation *hafasStation;
@property (nonatomic, strong) HafasTimetable* hafasTimetable;

@property (nonatomic,strong) NSArray* mapMarkers;

-(instancetype)initWithFernverkehr:(BOOL)showFernverkehr;
-(instancetype)initWithOPNVAndAllowBack:(BOOL)allowBack;
-(instancetype)initWithBackButton:(BOOL)showBackButton fernverkehr:(BOOL)showFernverkehr;

- (void)reloadTimetable;

- (BOOL)filterIsActive;
-(void)showTrack:(NSString*)track trainOrder:(Stop*)trainStop;

-(void)handleSearchResult:(MBContentSearchResult*)search;
@end
