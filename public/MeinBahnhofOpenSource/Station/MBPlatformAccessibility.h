// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import "MBPlatformAccessibilityFeature.h"

NS_ASSUME_NONNULL_BEGIN

//the accessibility data for a single platform
@interface MBPlatformAccessibility : NSObject

@property(nonatomic,strong) NSArray<NSString*>* linkedPlatforms;
@property(nonatomic) BOOL headPlatform;
@property(nonatomic,strong) NSString* parentPlatform;
@property(nonatomic,strong) NSString* name;
@property(nonatomic,strong) NSString* _Nullable level;//filled in later with information from RiMaps
@property(nonatomic) NSArray<MBPlatformAccessibilityFeature*>* _Nullable features;

//temporary storage while merging data
@property(nonatomic,strong) NSSet<NSString*>* platformSetWithNameAndLinked;
@property(nonatomic,strong) NSArray<MBPlatformAccessibility*>* linkedMBPlatformAccessibility;


-(NSArray<MBPlatformAccessibilityFeature*>*)availableFeatures;

+(MBPlatformAccessibility* _Nullable)parseDict:(NSDictionary*)dict;
+(MBPlatformAccessibilityType)statusStepFreeAccessForAllPlatforms:(NSArray<MBPlatformAccessibility*>*)platforms;
+(NSArray<NSString*>*)getPlatformList:(NSArray<MBPlatformAccessibility*>*)platforms;

+(void)sortArray:(NSMutableArray<MBPlatformAccessibility*>*)list;
+(NSComparisonResult)sortObj1:(NSString*)num1 obj2:(NSString*)num2;

@end

NS_ASSUME_NONNULL_END
