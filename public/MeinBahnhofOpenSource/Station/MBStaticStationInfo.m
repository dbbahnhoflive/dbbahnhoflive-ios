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
#import "MBPTSTravelcenter.h"

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
    MBService *service = [[MBService alloc] initWithDictionary:data error:nil];
    if(station){
        if([type isEqualToString:@"3-s-zentrale"]){
            service.descriptionText = [service.descriptionText stringByReplacingOccurrencesOfString:@"[PHONENUMBER]" withString:station.stationDetails.phoneNumber3S];
        } else if([type isEqualToString:@"mobilitaetsservice"]){
            //service.additionalText = station.stationDetails.mobilityServiceText;
        } else if([type isEqualToString:@"db_information"]){
            MBPTSAvailabilityTimes* times = station.stationDetails.dbInfoAvailabilityTimes;
            [service fillTableWithOpenTimes:times.availabilityString];
        } else if([type isEqualToString:@"mobiler_service"]){
            MBPTSAvailabilityTimes* times = station.stationDetails.localServiceStaffAvailabilityTimes;
            [service fillTableWithOpenTimes:times.availabilityString];
        } else if([type isEqualToString:@"local_travelcenter"]){
            
            if(!station.stationDetails.hasTravelCenter && station.travelCenter){
                //this is an external travel center with opening times displayed at top
                service.title = @"Reisezentrum";
                service.firstHeader = @"Nächstes Reisezentrum";
                service.addressHeader = station.travelCenter.title;
                service.addressStreet = station.travelCenter.address;
                service.addressPLZ = station.travelCenter.postCode;
                service.addressCity = station.travelCenter.city;
                service.addressLocation = station.travelCenter.coordinate;
                service.secondHeader = @"Öffnungszeiten";
                service.secondText = station.travelCenter.openingTimes;
                service.travelCenter = station.travelCenter;
            } else {
                
                if(station.travelCenter){
                    //the the opening times from this object
                    [service fillTableWithOpenTimes:station.travelCenter.openingTimes];
                } else {
                    //find the pxr item to get the opening times
                    if(station.riPois.count > 0){
                        for(RIMapPoi* poi in station.riPois){
                            if([poi.menusubcat isEqualToString:@"DB Reisezentrum"]){
                                [service fillTableWithOpenTimes:poi.allOpenTimes];
                                break;
                            }
                        }
                    } else if(station.einkaufsbahnhofCategories.count > 0){
                        BOOL found = NO;
                        for(MBEinkaufsbahnhofCategory* cat in station.einkaufsbahnhofCategories){
                            for(MBEinkaufsbahnhofStore* v in cat.shops){
                                if([v.name isEqualToString:@"DB Reisezentrum"]){
                                    NSString* times = [MBShopDetailCellView displayStringOpenTimesForStore:v];
                                    if(times.length > 0){
                                        [service fillTableWithOpenTimes:times];
                                    }
                                    found = YES;
                                    break;
                                }
                            }
                            if(found)
                                break;
                        }
                    }
                }
            }
        }
    }
    service.trackingKey = type;
    if([type isEqualToString:@"stufenfreier_zugang"]){
        service.trackingKey = @"zugang_wege";
    }    
    return service;
}

@end
