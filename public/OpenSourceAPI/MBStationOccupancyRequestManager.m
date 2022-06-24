// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBStationOccupancyRequestManager.h"
#import "Constants.h"
#import "NSDictionary+MBDictionary.h"

@implementation MBStationOccupancyRequestManager

+ (MBStationOccupancyRequestManager*)sharedInstance
{
    static MBStationOccupancyRequestManager *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *baseUrl = [NSURL URLWithString:[Constants kDBAPI]];
        sharedClient = [[self alloc] initWithBaseURL:baseUrl];
        
    });
    return sharedClient;
}

-(void)getOccupancyForStation:(NSNumber *)stationId forcedByUser:(BOOL)forcedByUser success:(void (^)(MBStationOccupancy *))success failureBlock:(void (^)(NSError *))failure{
    failure(nil);
}


@end
