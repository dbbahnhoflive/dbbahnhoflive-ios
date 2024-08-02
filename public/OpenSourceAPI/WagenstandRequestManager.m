// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "WagenstandRequestManager.h"
#import "Wagenstand.h"

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
    NSString* dateAndTime = wagenstand.request_date;
    
    [self loadISTWagenstandWithTrain:trainNumber
                                type:trainType
                                date:dateAndTime
                               evaId:wagenstand.evaId
                           departure:wagenstand.departure
                     completionBlock:completion];
}

-(void)loadISTWagenstandWithTrain:(NSString*)trainNumber
                             type:(NSString*)trainType
                             date:(NSString*)date
                            evaId:(NSString*)evaId
                        departure:(BOOL)departure
                  completionBlock:(void (^)(Wagenstand *istWagenstand))completion
{
    if(![Wagenstand isValidTrainTypeForIST:trainType]){
        completion(nil);
        return;
    }

    completion(nil);
}




@end
