// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBNextAppOverlayViewController.h"
#import "MBNews.h"
#import "MBTextView.h"
#import "MBButtonWithData.h"
#import "UIColor+DBColor.h"
#import "UIFont+DBFont.h"
#import "UIView+Frame.h"
#import "MBUrlOpening.h"
#import "MBTrackingManager.h"
#import "AppDelegate.h"

#import "MBService.h"
#import "MBStaticStationInfo.h"
#import "MBStaticServiceView.h"

@interface MBNextAppOverlayViewController ()<MBDetailViewDelegate>

@end

@implementation MBNextAppOverlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NEW_APP_HEADER;
    
    [MBTrackingManager trackStates:@[@"h0",@"nextapp"]];

    NSString* type = kServiceType_NEXTAPP;
    MBService* service = [MBStaticStationInfo serviceForType:type withStation:nil];
    service.title = NEW_APP_HEADER;
    service.descriptionText = NEW_APP_DESCRIPTION;

    MBStaticServiceView *staticServiceView = [[MBStaticServiceView alloc] initWithService:service station:nil viewController:self fullscreenLayout:NO andFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    staticServiceView.delegate = self;
    [self.contentScrollView addSubview:staticServiceView];
    
    [self updateContentScrollViewContentHeight:CGRectGetMaxY(staticServiceView.frame)+30];
}

- (void) didOpenUrl:(NSURL*)url{
    [MBTrackingManager trackActions:@[@"h0",@"nextapp",@"appstore"]];
    [MBUrlOpening openURL:url];
}


@end
