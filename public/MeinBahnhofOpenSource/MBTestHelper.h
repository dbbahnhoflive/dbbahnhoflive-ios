// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MBTestHelper : NSObject

+(BOOL)isTestRun;
+(NSString* _Nullable)mockDataForKey:(NSString*)key;

@end

NS_ASSUME_NONNULL_END
