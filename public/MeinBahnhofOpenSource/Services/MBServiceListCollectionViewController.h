// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>
#import "MBStation.h"
#import "MBStationTabBarViewController.h"
#import "MBMapViewController.h"
#import "MBMenuItem.h"

@class MBContentSearchResult;

typedef NS_ENUM(NSUInteger, MBServiceCollectionType) {
    MBServiceCollectionTypeInfo = 0,
    MBServiceCollectionTypeShopping = 1,
};


@interface MBServiceListCollectionViewController : UIViewController<MBMapViewControllerDelegate>

@property (nonatomic, strong) MBContentSearchResult* searchResult;
@property (nonatomic) BOOL openWegbegleitungScreen;
@property (nonatomic) BOOL openChatBotScreen;
@property (nonatomic) BOOL openServiceNumberScreen;
@property (nonatomic, strong) MBStation *station;
@property (nonatomic, assign) BOOL showsBackButton;

@property (nonatomic, weak) MBStationTabBarViewController *tabBarViewController;

/// @param type NSString @"info" for Bahnhofsinformationen, @"shopping" for Shoppen & Schlemmen
- (instancetype)initWithType:(MBServiceCollectionType)type;

- (NSArray *)prepareServices;

-(void)reloadData;

+(MBMenuItem*)createMenuItemErsatzverkehrWithStation:(MBStation*)station;

@end
