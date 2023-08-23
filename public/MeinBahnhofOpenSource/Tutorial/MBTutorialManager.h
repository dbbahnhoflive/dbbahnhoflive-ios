// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import "MBTutorial.h"



@interface MBTutorialManager : NSObject

+ (MBTutorialManager*)singleton;

//properties/methods for settings
@property(nonatomic) BOOL userDisabledTutorials;
-(BOOL)userDidCloseAllTutorials;

- (BOOL)displayTutorialIfNecessary:(MBTutorialViewType)type;
- (BOOL)displayTutorialIfNecessary:(MBTutorialViewType)type withOffset:(NSInteger)y;
- (void)hideTutorials;//ignored tutorials
-(void)userClosedTutorial:(MBTutorial*)tutorial;
-(void)markTutorialAsObsolete:(MBTutorialViewType)type;

@end
