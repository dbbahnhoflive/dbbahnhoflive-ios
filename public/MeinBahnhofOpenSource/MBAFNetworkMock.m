// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBAFNetworkMock.h"
#import "MBTestHelper.h"

@implementation MBAFNetworkMock

- (nullable NSURLSessionDataTask *)GET:(NSString *)URLString
                            parameters:(nullable id)parameters
                               headers:(nullable NSDictionary <NSString *, NSString *> *)headers
                              progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgress
                               success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                               failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure{
    if(MBTestHelper.isTestRun){
        NSLog(@"Mock request for %@",URLString);
        //NSLog(@"all environment: %@",NSProcessInfo.processInfo.environment);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSString* response = [MBTestHelper mockDataForKey:URLString];
            NSLog(@"Mock returns %@",response);
            if(!response){
                //there was no response defined, treat this as a failure in the request
                failure(nil,nil);
            } else {
                NSData* data = [response dataUsingEncoding:NSUTF8StringEncoding];
                id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                NSAssert(json != nil, @"could not load json from environment for %@: %@",URLString,response);
                success(nil, json);
            }
        });
    } else {
        NSAssert(false, @"MBAFNetworkMock used in !isTestRun");
    }
    return nil;
}

@end
