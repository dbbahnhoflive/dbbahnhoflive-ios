// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "Stop.h"

@implementation Stop

- (NSDictionary*) requestParamsForWagenstandWithEvent:(Event*)event;
{
    if(!self.transportCategory.transportCategoryType || !self.transportCategory.transportCategoryNumber){
        return nil;
    }
    NSString *formattedDate = [NSDateFormatter
                               formattedDate:[NSDate dateWithTimeIntervalSince1970:event.timestamp]
                               forPattern:@"HH:mm"];
    
    NSMutableDictionary *parameters = [@{
                                 @"platform": [event.originalPlatform stringByReplacingOccurrencesOfString:@"[\\D+]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [event.originalPlatform length])],
                                 @"trainId": self.stopId} mutableCopy];
    
    if (![self.transportCategory.transportCategoryType isEqualToString:@"RE"]
        && ![self.transportCategory.transportCategoryType isEqualToString:@"RB"]) {
        [parameters setObject:formattedDate forKey:@"time"];
        [parameters setObject:self.transportCategory.transportCategoryNumber forKey:@"trainNumber"];
    } else {
        [parameters setObject:self.transportCategory.transportCategoryType forKey:@"trainType"];
        
        if (self.transportCategory.transportCategoryGenericNumber) {
            [parameters setObject:self.transportCategory.transportCategoryGenericNumber forKey:@"trainNumber"];
        } else {
            [parameters setObject:self.transportCategory.transportCategoryNumber forKey:@"trainNumber"];
        }
    }
    
    return parameters;
}

- (Event*)eventForDeparture:(BOOL)departure;
{
    Event *event;
    if (departure) {
        event = self.departure;
    } else {
        event = self.arrival;
    }
    return event;
}

- (NSString*) formattedTransportType:(NSString*)lineIdentifier
{
    if (lineIdentifier) {
        return[NSString stringWithFormat: @"%@ %@",
               self.transportCategory.transportCategoryType,
               lineIdentifier];
    }
    if(self.transportCategory.transportCategoryNumber){
        return[NSString stringWithFormat: @"%@ %@",
               self.transportCategory.transportCategoryType,
               self.transportCategory.transportCategoryNumber];
    } else {
        return self.transportCategory.transportCategoryType;
    }
}

- (NSString*) replacementTrainMessage:(NSString*)lineIdentifier
{
    if (self.oldTransportCategory) {
        
        if (lineIdentifier) {
            return [NSString stringWithFormat:@"Ersatzzug für %@ %@",
                    self.oldTransportCategory.transportCategoryType,
                    lineIdentifier];
            
        }
        
        return [NSString stringWithFormat:@"Ersatzzug für %@ %@",
                self.oldTransportCategory.transportCategoryType,
                self.oldTransportCategory.transportCategoryNumber];
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
        if (lineIdentifier) {
            return [NSString stringWithFormat:@"Heute als %@ %@",
                    self.changedTransportCategory.transportCategoryType,
                    lineIdentifier];
        }
        return [NSString stringWithFormat:@"Heute als %@ %@",
                self.changedTransportCategory.transportCategoryType,
                self.changedTransportCategory.transportCategoryNumber];
    }
    return nil;
}

@end
