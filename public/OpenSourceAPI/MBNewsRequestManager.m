// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBNewsRequestManager.h"
@implementation MBNewsRequestManager

+ (MBNewsRequestManager*)sharedInstance
{
    static MBNewsRequestManager *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *baseUrl = [NSURL URLWithString:@"https://"];
        sharedClient = [[self alloc] initWithBaseURL:baseUrl];
        
    });
    return sharedClient;
}

-(NSURLSessionTask *)requestNewsForStation:(NSNumber *)stationId forcedByUser:(BOOL)forcedByUser success:(void (^)(MBNewsResponse *))success failureBlock:(void (^)(NSError *))failure{
    failure(nil);
    return nil;
}

@end
