// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBPlatformAccessibility.h"
#import "NSDictionary+MBDictionary.h"
#import "MBStation.h"

@implementation MBPlatformAccessibility

+(MBPlatformAccessibility * _Nullable)parseDict:(NSDictionary *)dict{
    MBPlatformAccessibility* res = [MBPlatformAccessibility new];
    res.parentPlatform = [dict db_stringForKey:@"parentPlatform"];
    res.name = [dict db_stringForKey:@"name"];
    if(!res.name){
        return nil;
    }
    NSDictionary* accessibility = [dict db_dictForKey:@"accessibility"];
    if(accessibility){
        NSMutableArray<MBPlatformAccessibilityFeature*>* features = [NSMutableArray arrayWithCapacity:12];
        res.features = features;
        for(NSNumber* featureType in [MBPlatformAccessibilityFeature featureOrder]){
            MBPlatformAccessibilityFeature* feature = [MBPlatformAccessibilityFeature featureForType:featureType.integerValue];
            feature.accType = [self parseAccessibility:[accessibility db_stringForKey:feature.serverKey]];
            if((feature.feature == MBPlatformAccessibilityFeatureType_boardingAid ||
                feature.feature == MBPlatformAccessibilityFeatureType_automaticDoor)
               && (feature.accType == MBPlatformAccessibilityType_UNKNOWN ||
                   feature.accType == MBPlatformAccessibilityType_NOT_AVAILABLE ||
                   feature.accType == MBPlatformAccessibilityType_NOT_APPLICABLE)
               ){
                //skip boardingAid and automaticDoor when not available, BAHNHOFLIVE-2400
                continue;
            }
            [features addObject:feature];
        }
    }
    
    
    res.headPlatform = [dict db_boolForKey:@"headPlatform"];
    NSArray* list = [dict db_arrayForKey:@"linkedPlatforms"];
    NSMutableArray* linked = [NSMutableArray arrayWithCapacity:list.count];
    NSString* thisTrack = res.name;
    for(NSString* s in list){
        if([s isKindOfClass:NSString.class] && s.length > 0){
            if(![linked containsObject:s] && ![s isEqualToString:thisTrack]){
                [linked addObject:s];
            }
        }
    }
    res.linkedPlatforms = linked;
    
    //if(res.features == nil && !res.headPlatform && res.linkedPlatforms.count == 0){
        //no information available, ignore this
        //return nil;
    //}
    
    return res;
}

-(NSString *)description{
    return [NSString stringWithFormat:@"MBPlatformAccessibility<%@,linked=%@,level=%@, set=%@>",self.name,self.linkedPlatforms,self.level,self.platformSetWithNameAndLinked];
}

+(void)sortArray:(NSMutableArray<MBPlatformAccessibility *> *)list{
    [list sortUsingComparator:^NSComparisonResult(MBPlatformAccessibility* obj1, MBPlatformAccessibility* obj2) {
        NSString* num1 = obj1.name;
        NSString* num2 = obj2.name;
        return [self sortObj1:num1 obj2:num2];
    }];
}
+(NSComparisonResult)sortObj1:(NSString*)num1 obj2:(NSString*)num2{
    if(num1.integerValue == num2.integerValue){
        return [num1 compare:num2];
    } else if(num1.integerValue < num2.integerValue){
        return NSOrderedAscending;
    } else {
        return NSOrderedDescending;
    }
}

-(NSArray<MBPlatformAccessibilityFeature *> *)availableFeatures{
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:self.features.count];
    for(MBPlatformAccessibilityFeature* feature in self.features){
        if(feature.accType != MBPlatformAccessibilityType_NOT_APPLICABLE){
            [res addObject:feature];
        }
    }
    return res;
}

-(MBPlatformAccessibilityType)typeForFeature:(MBPlatformAccessibilityFeatureType)featureType{
    for(MBPlatformAccessibilityFeature* f in self.features){
        if(f.feature == featureType){
            return f.accType;
        }
    }
    return MBPlatformAccessibilityType_UNKNOWN;
}

+(MBPlatformAccessibilityType)statusStepFreeAccessForAllPlatforms:(NSArray<MBPlatformAccessibility *> *)platforms{
    MBPlatformAccessibilityType res = MBPlatformAccessibilityType_UNKNOWN;
    BOOL hasAvailable = false;
    BOOL hasNotAvailable = false;
    for(MBPlatformAccessibility* p in platforms){
        MBPlatformAccessibilityType stepFreeAccessType = [p typeForFeature:MBPlatformAccessibilityFeatureType_stepFreeAccess];
        if(stepFreeAccessType == MBPlatformAccessibilityType_PARTIAL){
            return MBPlatformAccessibilityType_PARTIAL;
        }
        if(stepFreeAccessType == MBPlatformAccessibilityType_AVAILABLE){
            hasAvailable = true;
        }
        if(stepFreeAccessType == MBPlatformAccessibilityType_NOT_AVAILABLE){
            hasNotAvailable = true;
        }
    }
    if(hasAvailable && hasNotAvailable){
        return MBPlatformAccessibilityType_PARTIAL;
    } else if(hasAvailable){
        return MBPlatformAccessibilityType_AVAILABLE;
    } else if(hasNotAvailable){
        return MBPlatformAccessibilityType_NOT_AVAILABLE;
    }
    return res;
}
+(NSArray<NSString *> *)getPlatformList:(NSArray<MBPlatformAccessibility *> *)platforms{
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:platforms.count];
    for(MBPlatformAccessibility* p in platforms){
        [res addObject:p.name];
    }
    return [res sortedArrayUsingComparator:^NSComparisonResult(NSString* _Nonnull obj1, NSString* _Nonnull obj2) {
        NSInteger n1 = obj1.integerValue;
        NSInteger n2 = obj2.integerValue;
        if( n1 == n2 ){
            return NSOrderedSame;
        } else if( n1 < n2 ){
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }];
}

+(MBPlatformAccessibilityType)parseAccessibility:(NSString*)serverValue{
    if([serverValue isEqualToString:@"AVAILABLE"]){
        return MBPlatformAccessibilityType_AVAILABLE;
    }
    if([serverValue isEqualToString:@"PARTIAL"]){
        return MBPlatformAccessibilityType_PARTIAL;
    }
    if([serverValue isEqualToString:@"NOT_AVAILABLE"]){
        return MBPlatformAccessibilityType_NOT_AVAILABLE;
    }
    if([serverValue isEqualToString:@"NOT_APPLICABLE"]){
        return MBPlatformAccessibilityType_NOT_APPLICABLE;
    }
    return MBPlatformAccessibilityType_UNKNOWN;
}


@end
