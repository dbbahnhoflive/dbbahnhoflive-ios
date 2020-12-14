// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "WagenstandRequestManager.h"
#import <AFNetworking/AFNetworking.h>
#import "Wagenstand.h"
#import "Track.h"

@interface WagenstandRequestManager()


@end

@implementation WagenstandRequestManager


+ (instancetype) sharedManager
{
    static WagenstandRequestManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}



-(void)loadISTWagenstandWithWagenstand:(Wagenstand*)wagenstand
                       completionBlock:(void (^)(Wagenstand *istWagenstand))completion
{
    NSString* trainType = [Wagenstand getTrainTypeForWagenstand:wagenstand];
    
    if(![Wagenstand isValidTrainTypeForIST:trainType]){
        completion(nil);
        return;
    }
    NSString* trainNumber = [Wagenstand getTrainNumberForWagenstand:wagenstand];
    NSString* dateAndTime = [Wagenstand makeDateStringForTime:[Wagenstand getDateAndTimeForWagenstand:wagenstand]];
    
    [self loadISTWagenstandWithTrain:trainNumber
                                type:trainType
                           departure:dateAndTime
                              evaIds:wagenstand.evaIds
                     completionBlock:completion];
}

-(void)loadISTWagenstandWithTrain:(NSString*)trainNumber
                             type:(NSString*)trainType
                        departure:(NSString*)departure
                           evaIds:(NSArray*)evaIds
                  completionBlock:(void (^)(Wagenstand *istWagenstand))completion
{
    if(![Wagenstand isValidTrainTypeForIST:trainType] || evaIds.count == 0){
        completion(nil);
        return;
    }

    completion(nil);
}




@end
