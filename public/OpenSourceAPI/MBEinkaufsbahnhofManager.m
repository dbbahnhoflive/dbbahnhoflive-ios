// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBEinkaufsbahnhofManager.h"
#import <AFNetworking/AFNetworking.h>
#import "MBEinkaufsbahnhofStore.h"
#import "MBEinkaufsbahnhofCategory.h"

@interface MBEinkaufsbahnhofManager()
@property (nonatomic, strong) AFHTTPSessionManager *operationManager;
@end

@implementation MBEinkaufsbahnhofManager

+ (instancetype)sharedManager
{
    static MBEinkaufsbahnhofManager *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[self alloc] init];
    });
    return sharedClient;
}

-(instancetype)init{
    self = [super init];
    if(self){
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.operationManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
    }
    return self;
}

-(void)requestEinkaufPOI:(NSNumber *)stationId forcedByUser:(BOOL)forcedByUser success:(void (^)(NSArray *))success failureBlock:(void (^)(NSError *))failure{
    failure(nil);
}



//request overview for advertising Einkaufsbahnhof

-(void)requestAllEinkaufsbahnhofIdsForcedByUser:(BOOL)forcedByUser success:(void (^)(NSArray<NSNumber*> *))success failureBlock:(void (^)(NSError *))failure{
    
    success(@[@1071]);
}


@end
