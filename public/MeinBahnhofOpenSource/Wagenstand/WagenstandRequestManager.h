// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

#define WAGENSTAND_TYPETRAIN @"traintype"
#define WAGENSTAND_TRAINNUMBER @"trainnumber"
#define WAGENSTAND_EVAS_NR @"evasNr"
#define WAGENSTAND_TIME @"time"

@class Wagenstand;

@interface WagenstandRequestManager : NSObject

+ (instancetype) sharedManager;


-(void)loadISTWagenstandWithWagenstand:(Wagenstand*)wagenstand completionBlock:(void (^)(Wagenstand *istWagenstand))completion;
-(void)loadISTWagenstandWithTrain:(NSString*)trainNumber type:(NSString*)trainType departure:(NSString*)departure evaIds:(NSArray*)evaIds completionBlock:(void (^)(Wagenstand *istWagenstand))completion;

@end
