// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBTestHelper.h"

@implementation MBTestHelper

+(BOOL)isTestRun{
    //return true;
    NSString* status = NSProcessInfo.processInfo.environment[@"isTestRun"];
    return [status isEqualToString:@"1"];
}
+(NSString*)mockDataForKey:(NSString*)key{
    NSString* jsonString = NSProcessInfo.processInfo.environment[@"mock_requests"];
    if(!jsonString){
        return nil;
    }
    //NSAssert(jsonString != nil, @"no mock_requests defined for mock test run");
    NSData* data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSAssert(json != nil, @"mock_requests not valid json");
    return json[key];
}

@end
