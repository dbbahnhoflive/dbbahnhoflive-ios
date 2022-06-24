// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBStaticStationInfo.h"
#import "MBService.h"
#import "RIMapPoi.h"
#import "MBEinkaufsbahnhofCategory.h"
#import "MBEinkaufsbahnhofStore.h"
#import "MBStation.h"
#import "MBShopDetailCellView.h"
#import "MBTravelcenter.h"
#import "MBOSMOpeningHoursParser.h"
#import "RIMapSEV.h"

@implementation MBStaticStationInfo

+(NSDictionary*)infoForType:(NSString*)type{
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"staticInfo" ofType:@"json"]] options:0 error:nil];
    NSArray<NSDictionary*>* staticInfo = [json objectForKey:@"staticInfo"];
    for(NSDictionary* dict in staticInfo){
        if([[dict objectForKey:@"type"] isEqualToString:type]){
            return dict;
        }
    }
    return nil;
}

+(NSString*)textForType:(NSString*)type{
    NSDictionary* dict= [MBStaticStationInfo infoForType:type];
    return [dict objectForKey:@"descriptionText"];
}

+(MBService *)serviceForType:(NSString *)type withStation:(MBStation *)station{
    NSDictionary* data = [MBStaticStationInfo infoForType:type];
    if(data == nil){
        data = @{@"type":type};
    }
    MBService *service = [[MBService alloc] initWithDictionary:data error:nil];
    if(station){
        service.station = station;
        if([type isEqualToString:kServiceType_3SZentrale]){
            service.descriptionText = [service.descriptionText stringByReplacingOccurrencesOfString:@"[PHONENUMBER]" withString:station.stationDetails.phoneNumber3S];
        } else if([type isEqualToString:kServiceType_MobilityService]){
            //service.additionalText = station.stationDetails.mobilityServiceText;
        } else if([type isEqualToString:kServiceType_DBInfo]){
            service.openingTimesOSM = station.stationDetails.dbInfoOpeningTimesOSM;
        } else if([type isEqualToString:kServiceType_MobilerService]){
            service.openingTimesOSM = station.stationDetails.localServiceOpeningTimesOSM;
        } else if([type isEqualToString:kServiceType_LocalTravelCenter]){
            
            if(!station.stationDetails.hasTravelCenter && station.travelCenter){
                //this is an external travel center with opening times displayed at top
                service.title = @"Reisezentrum";
                service.firstHeader = @"Nächstes Reisezentrum";
                service.addressHeader = station.travelCenter.title;
                service.addressStreet = station.travelCenter.address;
                service.addressPLZ = station.travelCenter.postCode;
                service.addressCity = station.travelCenter.city;
                service.addressLocation = station.travelCenter.coordinate;
                service.openingTimesOSM = station.travelCenter.openingTimesOSM;
//                service.secondHeader = @"Öffnungszeiten";
//                service.secondText = station.travelCenter.openingTimesOSM.description;
                service.travelCenter = station.travelCenter;
            } else {
                
                if(station.travelCenter){
                    //the the opening times from this object
                    service.openingTimesOSM = station.travelCenter.openingTimesOSM;
                }
            }
        } else if([type isEqualToString:kServiceType_SEV]){
            NSString* headerText = station.sevPois.count > 1 ? @"An diesem Bahnhof finden Sie folgende Ersatzhaltestellen" : @"An diesem Bahnhof finden Sie folgende Ersatzhaltestelle";
            NSMutableString* text = [NSMutableString stringWithFormat:@"<p>%@:</p>",headerText];
            NSArray<NSArray<RIMapSEV *> *> * groups = [RIMapSEV groupSEVByWalkDescription:station.sevPois];
            for(NSArray<RIMapSEV*>* list in groups){
                //all SEV in this group have the same walkDescription: just collect the title texts
                NSMutableString* titles = [NSMutableString new];
                for(RIMapSEV* sev in list){
                    if(!UIAccessibilityIsVoiceOverRunning()){
                        [titles appendString:@"• "];
                    }
                    [titles appendString:sev.text];
                    if(sev != list.lastObject){
                        [titles appendString:@"<br>"];
                    }
                }
                [text appendFormat:@"<p><b>%@</b></p><p>Lagebeschreibung:<br>%@</p>", titles, list.firstObject.walkDescription];
            }
            service.descriptionText = text;
        }
    }
    service.trackingKey = type;
        
    return service;
}

@end
