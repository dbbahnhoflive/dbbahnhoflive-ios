// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBMapDepartureRequestManager.h"

@interface MBMapDepartureRequestManager ()

@property(nonatomic,strong) NSMutableArray* mapFlyouts;

@end

@implementation MBMapDepartureRequestManager

+ (MBMapDepartureRequestManager*)sharedManager
{
    static MBMapDepartureRequestManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
        sharedManager.mapFlyouts = [NSMutableArray arrayWithCapacity:5];
    });
    return sharedManager;
}

-(void)registerUpdateForFlyout:(MBMapFlyout*)mapFlyout{
    [self.mapFlyouts addObject:mapFlyout];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(updateMapDepartures) withObject:nil afterDelay:1];
//    [mapFlyout updateDepartures];
}

// some documentation: the whole purpose of this class is to defer departure update on map flyouts.
// It can happen that the UI is updates quickly and we request data for some flyouts that are already gone.
// We delay the update and check if the flyout still has a superview (is valid).

-(void)updateMapDepartures{
    NSLog(@"updateMapDepartures-start");
    for(MBMapFlyout* flyout in self.mapFlyouts){
        //NSLog(@"flyout %@, in %@",flyout,flyout.superview);
        if(flyout.superview){
            [flyout updateDepartures];
        }
    }
    [self.mapFlyouts removeAllObjects];
    NSLog(@"updateMapDepartures-done");
}

@end
