// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "SharedMobilityAPI.h"
#import "SharedMobilityMappable.h"


@implementation SharedMobilityAPI

- (instancetype) init
{
    if (self = [super init]) {
        
    }
    return self;
}

+ (instancetype)client
{
    static SharedMobilityAPI *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *baseUrl = [NSURL URLWithString:@""];
        sharedClient = [[self alloc] initWithBaseURL:baseUrl];
    });
    return sharedClient;
}

- (NSURLSessionTask *)getMappables:(CLLocationCoordinate2D)coordinate
                                              success:(void (^)(NSArray<MobilityMappable*> *mappables))success
                                 failureBlock:(void (^)(NSError *error))failureBlock
{
    return nil;
}

@end
