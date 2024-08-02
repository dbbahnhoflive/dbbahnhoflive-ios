// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBMenuItem.h"
#import "MBService.h"
#import "UIImage+MBImage.h"


@implementation MBMenuItem

+ (NSValueTransformer *)servicesJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:MBService.class];
}

- (NSArray*) servicesByPosition
{
    NSArray *sortedServices = [self.services sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES]]];
    return sortedServices;
}

- (UIImage*) iconForType
{
    NSDictionary *iconMapping = @{                                  
        @"mobilitaethandicap": @"app_mobilitaetservice",
        @"rufnummern": @"app_service_rufnummern",
        @"infoservices": @"bahnhofsausstattung_db_info",
        @"zugang": @"app_zugang_wege",
        kServiceType_Barrierefreiheit: @"app_zugang_wege",
        kServiceType_Parking: @"bahnhofsausstattung_parkplatz",
        @"aufzuegeundfahrtreppen": @"app_aufzug",
        kServiceType_WLAN : @"rimap_wlan_grau",
        kServiceType_SEV: @"sev_bus",
        kServiceType_SEV_AccompanimentService: @"SEV_Icon",
        kServiceType_Locker: @"rimap_schliessfach_grau",
        kServiveType_Dirt_Whatsapp: @"verschmutzungmelden",
        kServiceType_Dirt_NoWhatsapp: @"verschmutzungmelden",
        kServiceType_Rating: @"app_bewerten",
        kServiceType_Problems: @"probleme_app_melden",
    };
    
    NSString *iconFileName = [iconMapping objectForKey:self.type];
    if (!iconFileName) {
        iconFileName = @"";
    }
    return [UIImage db_imageNamed:iconFileName];
}



+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"type": @"type",
             @"title": @"title",
             @"services": @"services",
             @"position": @"position"
             };
}

@end
