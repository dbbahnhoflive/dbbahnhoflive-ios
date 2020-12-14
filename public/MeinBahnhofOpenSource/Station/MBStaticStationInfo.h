// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

@class MBService;
@class MBStation;

@interface MBStaticStationInfo : NSObject

+(MBService*)serviceForType:(NSString*)type withStation:(MBStation*)station;
+(NSDictionary*)infoForType:(NSString*)type;
+(NSString*)textForType:(NSString*)type;


@end
