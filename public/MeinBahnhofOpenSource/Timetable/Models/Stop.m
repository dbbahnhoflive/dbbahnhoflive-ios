// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "Stop.h"
#import "NSDateFormatter+MBDateFormatter.h"
#import "Wagenstand.h"

@implementation Stop


- (Event*)eventForDeparture:(BOOL)departure;
{
    Event *event;
    if (departure) {
        event = self.departureEvent;
    } else {
        event = self.arrivalEvent;
    }
    return event;
}

-(BOOL)isFlixtrain:(TransportCategory*)cat{
    return [cat.transportCategoryType isEqualToString:@"FLX"];
}

- (NSString*) formattedTransportType:(NSString*)lineIdentifier
{
    return [self formattedTransportTypeForCat:self.transportCategory line:lineIdentifier];
}
- (NSString*) formattedTransportTypeForCat:(TransportCategory*)cat line:(NSString*)lineIdentifier{
    if([self isFlixtrain:cat]){
        //for Flixtrains we display the trainnumber and not the line number
        return[NSString stringWithFormat: @"%@ %@",
               cat.transportCategoryType,
               cat.transportCategoryOriginalNumber
               ];
    }
    
    if (lineIdentifier) {
//        if([self.transportCategory.transportCategoryType isEqualToString:@"S"]){
            return[NSString stringWithFormat: @"%@ %@",
                   cat.transportCategoryType,
                   lineIdentifier];
/*        }
 //prepared display of train number (will this help the user?)
        return[NSString stringWithFormat: @"%@ %@ (%@)",
               cat.transportCategoryType,
               lineIdentifier,
               cat.transportCategoryOriginalNumber];*/
    }
    if(self.transportCategory.transportCategoryNumber){
        return[NSString stringWithFormat: @"%@ %@",
               cat.transportCategoryType,
               cat.transportCategoryNumber];
    } else {
        return cat.transportCategoryType;
    }
}

- (NSString*) replacementTrainMessage:(NSString*)lineIdentifier
{
    if (self.oldTransportCategory) {
        NSString* train = [self formattedTransportTypeForCat:self.oldTransportCategory line:lineIdentifier];
        return [NSString stringWithFormat:@"Ersatzzug für %@",
                train];
        
    } else if(self.isReplacementTrain){
        return @"Ersatzzug";
    } else if(self.isExtraTourTrain){
        return @"Sonderfahrt";
    }
    return nil;
}

- (NSString*) changedTrainMessage:(NSString*)lineIdentifier
{
    if (self.changedTransportCategory) {
        NSString* train = [self formattedTransportTypeForCat:self.changedTransportCategory line:lineIdentifier];
        return [NSString stringWithFormat:@"Heute als %@",
                train];
    }
    return nil;
}


@end
