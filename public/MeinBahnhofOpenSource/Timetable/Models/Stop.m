// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "Stop.h"
#import "NSDateFormatter+MBDateFormatter.h"

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

+(BOOL)stopShouldHaveTrainRecord:(Stop*)timetableStop{
    if ([timetableStop.transportCategory.transportCategoryType isEqualToString:@"ICE"]
        || [timetableStop.transportCategory.transportCategoryType isEqualToString:@"IC"]
        || [timetableStop.transportCategory.transportCategoryType isEqualToString:@"EC"])
    {
        return YES;
    }
    return NO;
}

@end
