// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

// This class allows automatic test runs without Firebase.
// When MBTestHelper.isTestPush returns true, topics are stored in a local set

#import "MBPushManager.h"
#import "MBTestHelper.h"
@import Firebase;

@interface MBPushManager()
@property(nonatomic,strong) NSMutableSet<NSString*>* testPushIds;
@end

@implementation MBPushManager

+ (MBPushManager*)client
{
    static MBPushManager *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[self alloc] init];
        sharedClient.testPushIds = [NSMutableSet setWithCapacity:10];
    });
    return sharedClient;
}

-(void)subscribeToTopic:(NSString *)topic completion:(void (^)(NSError * _Nullable))completion{
    if(MBTestHelper.isTestPush){
        if([self.testPushIds containsObject:topic]){
            NSLog(@"WARNING: subscribe called for a topic that is already in the list! %@",topic);
        }
        [self.testPushIds addObject:topic];
        NSLog(@"debug subscribed topics modified to: %@",self.testPushIds);
        if(completion){
            completion(nil);
        }
    } else {
        FIRMessaging* messaging = [FIRMessaging messaging];
        [messaging subscribeToTopic:topic completion:completion];
    }
}

-(void)unsubscribeFromTopic:(NSString *)topic completion:(void (^)(NSError * _Nullable))completion{
    if(MBTestHelper.isTestPush){
        if(![self.testPushIds containsObject:topic]){
            NSLog(@"WARNING: unsubscribe called for a topic that is not in the list! %@",topic);
        }
        [self.testPushIds removeObject:topic];
        NSLog(@"debug subscribed topics modified to: %@",self.testPushIds);
        if(completion){
            completion(nil);
        }
    } else {
        FIRMessaging* messaging = [FIRMessaging messaging];
        [messaging unsubscribeFromTopic:topic completion:completion];
    }
}

-(NSSet<NSString*>*)debugSubscribedTopics{
    return self.testPushIds;
}

@end
