// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    LockerSizeUnknown,
    LockerSizeSmall,
    LockerSizeMedium,
    LockerSizeLarge,
    LockerSizeJumbo,
} LockerSize;

@interface MBLocker : NSObject

-(MBLocker*)initWithDict:(NSDictionary*)dict;

@property(nonatomic,readonly) NSInteger amount;
@property(nonatomic,readonly) LockerSize size;
@property(nonatomic,readonly,nullable) NSString* paymentTypes;
@property(nonatomic,readonly) NSInteger fee;
@property(nonatomic,readonly,nullable) NSString* feePeriod;
@property(nonatomic,readonly,nullable) NSString* maxLeaseDuration;
@property(nonatomic,readonly) BOOL isShortLeaseLocker;

@property(nonatomic,readonly) NSInteger depth;
@property(nonatomic,readonly) NSInteger width;
@property(nonatomic,readonly) NSInteger height;

-(NSString*)headerText;
-(NSString*)lockerDescriptionTextForVoiceOver:(BOOL)voiceOver;

@end

NS_ASSUME_NONNULL_END
