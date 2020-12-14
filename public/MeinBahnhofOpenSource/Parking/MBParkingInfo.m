// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBParkingInfo.h"
#import "MBMarker.h"
#import "NSDictionary+MBDictionary.h"

@interface MBParkingInfo()
@property(nonatomic,strong) NSDictionary* serverData;
@end

@implementation MBParkingInfo

static NSNumberFormatter * numberFormatter = nil;

+(MBParkingInfo *)parkingInfoFromServerDict:(NSDictionary *)dict{
    if([dict isKindOfClass:NSDictionary.class]){
        MBParkingInfo* item = [MBParkingInfo new];
        item.serverData = dict;
        return item;
    }
    return nil;
}


- (CLLocationCoordinate2D) location
{
    NSDictionary* address = [self.serverData db_dictForKey:@"address"];
    NSDictionary* location = [address db_dictForKey:@"location"];
    NSNumber* lat = [location db_numberForKey:@"latitude"];
    NSNumber* lng = [location db_numberForKey:@"longitude"];
    if(lat && lng){
        return CLLocationCoordinate2DMake(lat.doubleValue, lng.doubleValue);
    } else {
        return kCLLocationCoordinate2DInvalid;
    }
}

- (NSString *) maximumParkingTime
{
    return [[self tarifInformationDynamic] db_stringForKey:@"tariffMaxParkingTime"];
}

- (NSString *) name
{
    NSArray* nameList = [self.serverData db_arrayForKey:@"name"];
    NSArray* contextFieldValues = @[ @"DISPLAY", @"NAME", @"LABEL", @"SLOGAN", @"UNKNOWN" ];
    NSString* possibleResult = nil;
    for(NSString* key in contextFieldValues){
        //do we have this name?
        for(NSDictionary* dict in nameList){
            if([dict isKindOfClass:NSDictionary.class]){
                NSString* context = [dict db_stringForKey:@"context"];
                if([context isEqualToString:key]){
                    possibleResult = [dict db_stringForKey:@"name"];
                    if(possibleResult){
                        break;
                    }
                }
            }
        }
        if(possibleResult){
            break;
        }
    }
    if(possibleResult){
        return possibleResult;
    }
    //just get the first one as a fallback
    NSDictionary* dict = nameList.firstObject;
    if([dict isKindOfClass:NSDictionary.class]){
        possibleResult = [dict db_stringForKey:@"name"];
        if(possibleResult){
            return possibleResult;
        }
    }
    
    //second fallback: use a static string
    return @"Parkplatz";//MAIK?
}

- (NSString*) iconForType
{
    return [self isParkHaus] ? @"rimap_parkhaus" : @"rimap_parkplatz";
}

-(BOOL)isParkHaus{
    NSString* type = self.typeOfParking;
    //NSLog(@"got parking type %@",type);
    if([type isEqualToString:@"Tiefgarage"] || [type isEqualToString:@"Parkhaus"] || [type isEqualToString:@"Überdacht"]){
        return YES;
    }
    //other values: Offen, Parkplatz
    return NO;
}
/*
-(NSString*)textForStatus{
    if(self.isOutOfOrder){
        return self.outOfOrderText;
    }
    if(self.tarifFreeParkTime.length > 1){
        //NOTE: >1 because string can contain "N" meaning there is no free parking
        return [NSString stringWithFormat:@"Frei Parken (%@)",self.tarifFreeParkTime];
    }
    if(self.hasParkingReservation){
        return @"Parkraumreservierung möglich";
    }
    return @"";
}*/

- (NSString*) textForAllocation
{
    if(self.allocationCategory && self.allocationCategory.integerValue > 0 && self.allocationCategory.integerValue <= 4){
        switch (self.allocationCategory.integerValue) {
            case 1:
                return @"0 - 10 freie Stellplätze";
            case 2:
                return @"10 - 30 freie Stellplätze";
            case 3:
                return @"30 - 50 freie Stellplätze";
            case 4:
                return @"> 50 freie Stellplätze";
        }
    }
    return nil;
}

- (NSString *)shortTextForAllocation
{
    if(self.allocationCategory && self.allocationCategory.integerValue > 0 && self.allocationCategory.integerValue <= 4){
        switch (self.allocationCategory.integerValue) {
            case 1:
                return @"10\u207b";
            case 2:
                return @"10\u207a";
            case 3:
                return @"30\u207a";
            case 4:
                return @"50\u207a";
        }
    }
    return @"";
}

- (UIImage *) iconForAllocation
{
    if(self.allocationCategory && self.allocationCategory.integerValue > 0 && self.allocationCategory.integerValue <= 4){
        return [UIImage db_imageNamed:[NSString stringWithFormat:@"parkingcategory%ld",(long)self.allocationCategory.integerValue]];
    }
    return nil;
}

-(NSString*)equipment{
    NSDictionary* equipment = [self.serverData db_dictForKey:@"equipment"];
    NSDictionary* charging = [equipment db_dictForKey:@"charging"];
    BOOL hasCharging = [[charging db_numberForKey:@"hasChargingStation"] boolValue];
    NSDictionary* additionalInformation = [equipment db_dictForKey:@"additionalInformation"];
    if(additionalInformation.count > 0 || hasCharging){
        NSMutableString* res = [NSMutableString new];
        if(hasCharging){
            [res appendString:@"Ladestation, "];
        }
        for(NSString* key in additionalInformation){
            BOOL isAvailable = [[additionalInformation db_numberForKey:key] boolValue];
            if(isAvailable && [key isKindOfClass:NSString.class]){
                [self appendStringWithKey:key to:res];
            }
        }
        if(res.length > 3){
            //delete the last ", "
            [res deleteCharactersInRange:NSMakeRange(res.length-2, 2)];
        }        
        return res;
    }
    return nil;
}
-(void)appendStringWithKey:(NSString*)key to:(NSMutableString*)string{
    if([key isEqualToString:@"isLighted"]){
        [string appendString:@"Beleuchtung, "];
    } else if([key isEqualToString:@"hasParentChildPlaces"]){
        [string appendString:@"Eltern-Kind Parkplätze, "];
    } else if([key isEqualToString:@"hasLift"]){
        [string appendString:@"Aufzug, "];
    } else if([key isEqualToString:@"hasToilets"]){
        [string appendString:@"WC, "];
    } else if([key isEqualToString:@"hasWomenPlaces"]){
        [string appendString:@"Frauenparkplätze, "];
    } else if([key isEqualToString:@"hasDisabledPlaces"]){
        [string appendString:@"Behindertengerechte Parkplätze, "];
    }
}

- (MBMarker*) markerForParkingWithSelectable:(BOOL)isSelectable
{
    CLLocationCoordinate2D location = [self location];
    if(!CLLocationCoordinate2DIsValid(location)){
        return nil;
    }
    MBMarker *marker = [MBMarker markerWithPosition:location andType:PARKING];
    marker.userData = @{@"venue": self, @"isSelectable": [NSNumber numberWithBool:isSelectable]};
    marker.category = @"Individualverkehr";
    marker.secondaryCategory = [self isParkHaus] ? @"Parkhaus" : @"Parkplatz";
    marker.zoomLevel = 16;//17 in RiMaps!
    marker.icon = [UIImage db_imageNamed:[self iconForType]];
    marker.zIndex = 800;
    return marker;
}

-(BOOL)isOutOfOrder{
    NSDictionary* access = [self.serverData db_dictForKey:@"access"];
    NSDictionary* outOfService = [access db_dictForKey:@"outOfService"];
    NSNumber* oos = [outOfService db_numberForKey:@"isOutOfService"];
    BOOL isOutOfService = [oos boolValue];
    return isOutOfService;
}
-(NSString*)outOfOrderText{
    NSDictionary* access = [self.serverData db_dictForKey:@"access"];
    NSDictionary* outOfService = [access db_dictForKey:@"outOfService"];
    return [outOfService db_stringForKey:@"reason"];
}

-(BOOL)hasPrognosis{
    NSNumber* num = [self.serverData db_numberForKey:@"hasPrognosis"];
    return [num boolValue];
}

-(NSString*)idValue{
    return [self.serverData db_stringForKey:@"id"];
}

-(NSString *)operatorCompany{
    NSDictionary* operator = [self.serverData db_dictForKey:@"operator"];
    return [operator db_stringForKey:@"name"];
}

- (NSString *)distanceToStation{
    NSDictionary* station = [self.serverData db_dictForKey:@"station"];
    NSString* m = [station db_stringForKey:@"distance"];
    if(m.length > 0 && !([m hasSuffix:@"m"] || [m hasSuffix:@"eter"])){
        return [m stringByAppendingString:@"m"];
    }
    return m;
}

-(BOOL)hasParkingReservation{
    return NO;//in testdata no station had this value; display to user unclear
    /*
    NSDictionary* reservation = [self.serverData db_dictForKey:@"reservation"];
    NSNumber* num = [reservation db_numberForKey:@"hasReservation"];
    return [num boolValue];*/
}

-(NSString *)accessDescription{
    NSDictionary* address = [self.serverData db_dictForKey:@"address"];
    return [address db_stringForKey:@"streetAndNumber"];
}

-(NSString*)accessDetailsForType:(NSString*)type{
    NSDictionary* access = [self.serverData db_dictForKey:@"access"];
    NSArray* details = [access db_arrayForKey:@"details"];
    for(NSDictionary* dict in details){
        if([dict isKindOfClass:NSDictionary.class]){
            if([[dict db_stringForKey:@"type"] isEqualToString:type]){
                return [dict db_stringForKey:@"text"];
            }
        }
    }
    return nil;
}

-(NSString*)accessDetailsDay{
    return [self accessDetailsForType:@"MAIN_ACCESS"];
}
-(NSString*)accessDetailsNight{
    return [self accessDetailsForType:@"NIGHT_ACCESS"];
}

-(NSString*)openingTimes{
    NSDictionary* access = [self.serverData db_dictForKey:@"access"];
    NSDictionary* openingHours = [access db_dictForKey:@"openingHours"];
    NSString* s = [openingHours db_stringForKey:@"text"];
    //add linebreaks after ;
    s = [s stringByReplacingOccurrencesOfString:@";" withString:@";\n"];
    //ensure that we dont get duplicated linebreaks
    s = [s stringByReplacingOccurrencesOfString:@";\n\n" withString:@";\n"];
    return s;
}



-(NSString *)typeOfParking{
    NSDictionary* type = [self.serverData db_dictForKey:@"type"];
    return [type db_stringForKey:@"name"];//docu said "type" but data has "name" with "Tiefgarage" or "Offen"
}

-(NSString *)technology{
    return nil;
}
-(NSString *)numberOfParkingSpaces{
    return [self capacityForType:@"PARKING"];
}
-(NSString *)numberOfParkingSpacesHandicapped{
    return [self capacityForType:@"HANDICAPPED_PARKING"];
}
-(NSString *)numberOfParkingSpacesParentChild{
    return [self capacityForType:@"PARENT_AND_CHILD_PARKING"];
}
-(NSString *)numberOfParkingSpacesWoman{
    return [self capacityForType:@"WOMAN_PARKING"];
}
-(NSString*)capacityForType:(NSString*)typeSearched{
    NSArray* capacity = [self.serverData db_arrayForKey:@"capacity"];
    for(NSDictionary* dict in capacity){
        if([dict isKindOfClass:NSDictionary.class]){
            NSString* type = [dict db_stringForKey:@"type"];
            if([type isEqualToString:typeSearched]){
                return [dict db_stringForKey:@"total"];
            }
        }
    }
    return @"";
}

//helper
-(NSDictionary*)tarifInformationDynamic{
    NSDictionary* tariff = [self.serverData db_dictForKey:@"tariff"];
    NSDictionary* information = [tariff db_dictForKey:@"information"];
    NSDictionary* dynamic = [information db_dictForKey:@"dynamic"];
    return dynamic;
}
-(NSArray*)tarifPrices{
    NSDictionary* tariff = [self.serverData db_dictForKey:@"tariff"];
    return [tariff db_arrayForKey:@"prices"];
}

-(NSString*)paymentTypes{
    return [[self tarifInformationDynamic] db_stringForKey:@"tariffPaymentOptions"];
}
-(NSString*)tarifNotes{
    return [[self tarifInformationDynamic] db_stringForKey:@"tariffNotes"];
}
-(NSString*)tarifDiscount{
    return [[self tarifInformationDynamic] db_stringForKey:@"tariffDiscount"];
}
-(NSString*)tarifSpecial{
    return [[self tarifInformationDynamic] db_stringForKey:@"tariffSpecial"];
}

-(NSString *)tarifFreeParkTime{
    return [[self tarifInformationDynamic] db_stringForKey:@"tariffFreeParkingTime"];
}

-(NSArray<NSArray<NSString*>*>*)tarifPricesList{
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:10];
    NSArray* tarifPrices = [self tarifPrices];
    for(NSDictionary* dict in tarifPrices){
        if([dict isKindOfClass:NSDictionary.class]){
            NSNumber* price = [dict db_numberForKey:@"price"];
            NSString* period = [dict db_stringForKey:@"period"];
            NSString* duration = [dict db_stringForKey:@"duration"];
            if(price && duration){
                NSDictionary* group = [dict db_dictForKey:@"group"];
                NSString* groupName = [group db_stringForKey:@"groupName"];
                NSString* groupLabel = [group db_stringForKey:@"groupLabel"];
                BOOL isStandardGroup = [groupName isEqualToString:@"standard"];

                NSMutableString* keyString = [NSMutableString new];
                if(!isStandardGroup && groupLabel.length > 0){
                    [keyString appendString:groupLabel];
                    [keyString appendString:@" "];
                }
                if(period.length > 0){
                    [keyString appendString:period];
                    [keyString appendString:@", "];
                }
                duration = [self replaceDuration:duration];
                [keyString appendString:duration];
                NSString* priceString = [self priceAsString:price];
                [res addObject:@[ keyString, priceString ]];
            }
        }
    }
    return res;
}
-(NSString*)replaceDuration:(NSString*)duration{
    if([duration isEqualToString:@"20min"]){
        return @"20 Minuten";
    }
    if([duration isEqualToString:@"30min"]){
        return @"30 Minuten";
    }
    if([duration isEqualToString:@"1hour"]){
        return @"1 Stunde";
    }
    if([duration isEqualToString:@"1day"]){
        return @"1 Tag";
    }
    if([duration isEqualToString:@"1dayDiscount"]){
        return @"1 Tag (Rabatt)";
    }
    if([duration isEqualToString:@"1week"]){
        return @"1 Woche";
    }
    if([duration isEqualToString:@"1weekDiscount"]){
        return @"1 Woche (Rabatt)";
    }
    if([duration isEqualToString:@"1monthVendingMachine"]){
        return @"1 Woche (am Automaten)";
    }
    if([duration isEqualToString:@"1monthLongTerm"]){
        return @"1 Monat Langzeitparken";
    }
    if([duration isEqualToString:@"1monthReservation"]){
        return @"1 Monat Reserviert";
    }
    return duration;
}

-(NSString*)priceAsString:(NSNumber*)price{
    if(!numberFormatter){
        numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
        numberFormatter.currencySymbol = @"€";
    }
    NSString *numberAsString = [numberFormatter stringFromNumber:price];
    return numberAsString;
}




@end
