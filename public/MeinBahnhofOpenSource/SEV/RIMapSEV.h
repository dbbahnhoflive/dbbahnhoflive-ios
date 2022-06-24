// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "RIMapPoi.h"

NS_ASSUME_NONNULL_BEGIN

#define SEV_TEXT_FALLBACK @"Weitere Ersatzhaltestelle"
#define SEV_WALK_FALLBACK @"Zu dieser Haltestelle liegt keine Lagebeschreibung vor"

@interface RIMapSEV : NSObject

-(instancetype)initWithDict:(NSDictionary*)dict;

@property(nonatomic,strong,readonly) NSString* text;
@property(nonatomic,strong,readonly) NSString* walkDescription;
@property(nonatomic,readonly) CLLocationCoordinate2D coordinate;

-(BOOL)isValid;

+(NSArray<NSArray<RIMapSEV*>*>*)groupSEVByWalkDescription:(NSArray<RIMapSEV*>*)list;


@end

NS_ASSUME_NONNULL_END
