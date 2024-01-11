// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MBPlatformAccessibilityType)  {
    MBPlatformAccessibilityType_UNKNOWN,
    MBPlatformAccessibilityType_NOT_APPLICABLE,
    MBPlatformAccessibilityType_NOT_AVAILABLE,
    MBPlatformAccessibilityType_PARTIAL,
    MBPlatformAccessibilityType_AVAILABLE,
} ;

typedef NS_ENUM(NSUInteger, MBPlatformAccessibilityFeatureType)  {
    MBPlatformAccessibilityFeatureType_audibleSignalsAvailable,
    MBPlatformAccessibilityFeatureType_automaticDoor,
    MBPlatformAccessibilityFeatureType_boardingAid,
    MBPlatformAccessibilityFeatureType_passengerInformationDisplay,
    MBPlatformAccessibilityFeatureType_standardPlatformHeight,
    MBPlatformAccessibilityFeatureType_platformSign,
    MBPlatformAccessibilityFeatureType_stairsMarking,
    MBPlatformAccessibilityFeatureType_stepFreeAccess,
    MBPlatformAccessibilityFeatureType_tactileGuidingStrips,
    MBPlatformAccessibilityFeatureType_tactileHandrailLabel,
    MBPlatformAccessibilityFeatureType_tactilePlatformAccess,
} ;


@interface MBPlatformAccessibilityFeature : NSObject

@property(nonatomic) MBPlatformAccessibilityFeatureType feature;
@property(nonatomic) MBPlatformAccessibilityType accType;

+(MBPlatformAccessibilityFeature*)featureForType:(MBPlatformAccessibilityFeatureType)feature;

+(NSArray<NSNumber*>*)featureOrder;//list with MBPlatformAccessibilityFeatureType

-(NSString*)serverKey;
-(NSString*)displayText;
-(NSString*)descriptionText;

-(BOOL)isEqual:(id)object;

@end

NS_ASSUME_NONNULL_END
