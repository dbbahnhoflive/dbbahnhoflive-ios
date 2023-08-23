// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MBPushManager : NSObject
+ (MBPushManager*)client;

-(void)subscribeToTopic:(NSString*)topic completion:(void(^)(NSError * _Nullable error))completion;
-(void)unsubscribeFromTopic:(NSString*)topic completion:(void(^)(NSError * _Nullable error))completion;

-(NSSet<NSString*>*)debugSubscribedTopics;

@end

NS_ASSUME_NONNULL_END
