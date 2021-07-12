// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import "MBPlatformAccessibilityFeature.h"

NS_ASSUME_NONNULL_BEGIN

//the accessibility data for a single platform
@interface MBPlatformAccessibility : NSObject

@property(nonatomic,strong) NSString* name;
@property(nonatomic) NSArray<MBPlatformAccessibilityFeature*>* features;

-(NSArray<NSString*>*)availableTypesDisplayStrings;


+(MBPlatformAccessibility* _Nullable)parseDict:(NSDictionary*)dict;
+(MBPlatformAccessibilityType)statusStepFreeAccessForAllPlatforms:(NSArray<MBPlatformAccessibility*>*)platforms;
+(NSArray<NSString*>*)getPlatformList:(NSArray<MBPlatformAccessibility*>*)platforms;

@end

NS_ASSUME_NONNULL_END
