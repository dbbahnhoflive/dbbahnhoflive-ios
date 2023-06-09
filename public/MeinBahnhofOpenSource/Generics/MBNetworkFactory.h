// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

NS_ASSUME_NONNULL_BEGIN

@interface MBNetworkFactory : NSObject

+(AFHTTPSessionManager*)createRISSessionManager;
+(void)configureRISHeader:(AFHTTPSessionManager*)networkManager;

@end

NS_ASSUME_NONNULL_END
