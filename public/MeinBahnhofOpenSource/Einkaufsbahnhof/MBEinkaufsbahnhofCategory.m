// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBEinkaufsbahnhofCategory.h"

@implementation MBEinkaufsbahnhofCategory

-(UIImage *)icon{
    return [MBEinkaufsbahnhofCategory menuIconForCategoryTitle:self.name];
}
-(NSString*)iconFilename{
    NSString* categoryName = [MBEinkaufsbahnhofCategory categoryNameForCatTitle:self.name];
    return categoryName;
}
+(UIImage*)menuIconForCategoryTitle:(NSString*)title{
    NSString* categoryName = [self categoryNameForCatTitle:title];
    return [UIImage db_imageNamed:categoryName];
}
+(NSString*)categoryNameForCatTitle:(NSString*)title{
    NSDictionary *categoryNames = @{
                                    @"Bäckereien": @"rimap_backwaren_grau",
                                    @"Gastronomie": @"rimap_restaurant_grau",
                                    @"Lebensmittel": @"rimap_lebensmittel_grau",
                                    @"Gesundheit & Pflege": @"rimap_gesundheit_grau",
                                    @"Presse & Buch": @"rimap_presse_grau",
                                    @"Shops": @"rimap_mode_grau",
                                    @"Dienstleistungen": @"rimap_dienstleistungen_grau"
                                    };
    NSString *categoryName = [categoryNames objectForKey:title];
    return categoryName;
}

+(MBEinkaufsbahnhofCategory *)createCategoryWithName:(NSString *)name number:(NSNumber *)number{
    MBEinkaufsbahnhofCategory* res = [MBEinkaufsbahnhofCategory new];
    res.name = name;
    res.number = number;
    return res;
}

@end
