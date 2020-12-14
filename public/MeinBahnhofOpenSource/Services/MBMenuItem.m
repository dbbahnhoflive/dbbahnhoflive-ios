// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBMenuItem.h"
#import "MBService.h"

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
        @"parkplaetze": @"bahnhofsausstattung_parkplatz",
        @"aufzuegeundfahrtreppen": @"app_aufzug",
        @"wlan" : @"rimap_wlan_grau",
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
