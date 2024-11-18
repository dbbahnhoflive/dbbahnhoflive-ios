// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

#define WAGENSTAND_TYPETRAIN @"traintype"
#define WAGENSTAND_TRAINNUMBER @"trainnumber"
#define WAGENSTAND_EVA_NR @"evaNr"
#define WAGENSTAND_DATE_FOR_REQUEST @"date_request"
#define WAGENSTAND_DEPARTURE @"departure"

@class Wagenstand;

@interface WagenstandRequestManager : NSObject

+ (instancetype) sharedManager;

-(void)loadAdministrators;
-(BOOL)hasDataForAdministration:(NSString*)administrationId;

-(void)loadISTWagenstandWithWagenstand:(Wagenstand*)wagenstand completionBlock:(void (^)(Wagenstand *istWagenstand))completion;
-(void)loadISTWagenstandWithTrain:(NSString*)trainNumber type:(NSString*)trainType date:(NSString*)date evaId:(NSString*)evaId departure:(BOOL)departure completionBlock:(void (^)(Wagenstand *istWagenstand))completion;

@end
