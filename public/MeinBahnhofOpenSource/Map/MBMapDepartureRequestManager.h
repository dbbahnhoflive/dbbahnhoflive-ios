// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import "MBMapFlyout.h"

@interface MBMapDepartureRequestManager : NSObject

+ (MBMapDepartureRequestManager*)sharedManager;

-(void)registerUpdateForFlyout:(MBMapFlyout*)mapFlyout;

@end
