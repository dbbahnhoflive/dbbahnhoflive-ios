// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "SharedMobilityMappable.h"

@implementation MobilityMappable

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error
{
    if (self = [super initWithDictionary:dictionaryValue error:error]) {

        self.gearBox = @"k.A.";
        self.fuelStatus = @"k.A.";
        
        for (NSDictionary *dataDictionary in self.data) {
            NSString *key = [dataDictionary objectForKey:@"key"];
            NSString *content = [dataDictionary objectForKey:@"content"];
            
            if ([key isEqualToString:@"model"]) {
                self.model = content;
            } else if ([key isEqualToString:@"automatic"]) {
                self.gearBox = ([content integerValue] == 1) ? @"Automatik" : @"Manuell";
            } else if ([key isEqualToString:@"fuel"]) {
                self.fuelStatus = content;
            }
            
            BOOL isBikeOffer = [[self.typeName lowercaseString] rangeOfString:@"bike"].location != NSNotFound;
            self.isBikeOffer = isBikeOffer;
            
        }
    }
    return self;
}

- (UIImage*) pinForProvider
{
    NSDictionary *providers = @{
            @"flinkster": @"PinFlinkster",
            @"callabike": @"PinCallABike",
            @"stadtmobil": @"PinStadtmobil",
            @"car2go": @"PinCar2Go",
            @"drivenow": @"PinDriveNow",
            @"citeecar": @"PinCiteecar",
            @"hertz247": @"PinHertz247",
            @"tamyca": @"PinTamyca",
            @"greenwheels": @"PinGreenwheels",
            @"multicity": @"PinMulticity",
            @"multicitygas": @"PinMulticityGas",
            @"autonetzer": @"PinAutonetzer",
            @"cambio": @"PinCambio",
            @"nextbike": @"PinNextBike",
            @"car2goblack": @"PinCar2GoBlack",
            @"emio": @"PinEMio",
            @"quicar": @"PinQuicar",
            @"catchacar": @"PinCatchACar",
            @"enjoy": @"PinEnjoy",
            @"jaano": @"PinJaano",
            @"mobility": @"PinMobility",
            @"sco2t": @"PinSco2t",
            @"starcar": @"PinShareAStarCar",
            @"stattauto": @"PinStattauto",
            @"zipcar": @"PinZipcar",
            @"citybikewien": @"PinCitybike",
            @"kemas": @"PinKemas",
            @"citybikes": @"PinGenericBikes",
            };
    //Missing Icons: eMio, Multicity Gas, Car2Go Black

    if (self.typeName) {
        
        NSString *iconNameForProvider = [providers objectForKey:[self sanitizedProvider]];
        if (iconNameForProvider) {
            return [UIImage db_imageNamed:iconNameForProvider];
        }
    }
    
    return [UIImage db_imageNamed:@"PinDefault"];
}

- (NSString*) appStoreUrlForProvider
{
    NSDictionary *urls = @{
                           @"tamyca": @"https://itunes.apple.com/de/app/tamyca/id481098740?mt=8",
                           @"drivenow": @"https://itunes.apple.com/de/app/drivenow-carsharing/id435719709?mt=8",
                           @"flinkster": @"https://itunes.apple.com/de/app/flinkster/id421390893?mt=8",
                           @"callabike": @"https://itunes.apple.com/de/app/call-a-bike/id420360589?mt=8",
                           @"car2go": @"https://itunes.apple.com/de/app/car2go/id514921710?mt=8",
                           @"citeecar": @"https://itunes.apple.com/de/app/citeecar-carsharing/id599630457?mt=8",
                           @"hertz247": @"https://itunes.apple.com/at/app/hertz-24-7/id536499953?mt=8",
                           @"greenwheels": @"https://itunes.apple.com/de/app/greenwheels/id513239812?mt=8",
                           @"multicity": @"https://itunes.apple.com/de/app/multicity-carsharing/id554074490?mt=8",
                           @"cambio": @"https://itunes.apple.com/be/app/cambio-carsharing/id516627231?mt=8",
                           @"nextbike": @"https://itunes.apple.com/de/app/nextbike/id504288371?mt=8",
                           @"emio": @"https://itunes.apple.com/de/app/emio/id980900815?mt=8",
                           @"multicitygas": @"https://itunes.apple.com/de/app/multicity-carsharing/id554074490?mt=8",
                           @"car2goblack": @"https://itunes.apple.com/de/app/car2go-black/id794886894?mt=8",
                           @"jaano": @"https://itunes.apple.com/de/app/jaano-scootersharing/id1017691014?mt=8",
                           @"catchacar": @"https://itunes.apple.com/ch/app/catch-car/id900072461?mt=8",
                           @"starcar": @"https://itunes.apple.com/de/app/starcar/id526306583?mt=8"
                           };
    return [urls objectForKey:[self sanitizedProvider]];
}

- (NSString*) sanitizedProvider
{
    
    if (!self.typeName) {
        return @"";
    }
    
    NSString *sanitizedProvider = [self.typeName lowercaseString];
    sanitizedProvider = [sanitizedProvider stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    sanitizedProvider = [sanitizedProvider stringByReplacingOccurrencesOfString:@" " withString:@""];
    return sanitizedProvider;
}


- (NSURL*) urlScheme
{
    NSString *provider = [self sanitizedProvider];
    
    //Car2GO Scheme to deep link: car2go://vehicle/$VIN?location=$LOCATION_ID
    if ([provider isEqualToString:@"car2go"]) {
        return [NSURL URLWithString:[NSString stringWithFormat:@"%@://vehicle/%@", provider, self.externalId]];
    }
    
    return[NSURL URLWithString:[NSString stringWithFormat:@"%@://", provider]];
}

- (MBMarker*)marker
{
    CLLocationCoordinate2D position = CLLocationCoordinate2DMake([self.latitude doubleValue], [self.longitude doubleValue]);
    MBMarker *marker = [MBMarker markerWithPosition:position andType:MOBILITY];
    marker.icon = [self pinForProvider];
    marker.category = @"Individualverkehr"; //(self.isBikeOffer) ? @"Bike-Sharing" : @"Car-Sharing";
    
    NSString* provider = [self sanitizedProvider];
    BOOL isFlinkster = [provider isEqualToString:@"flinkster"];
    BOOL iscallabike = [provider isEqualToString:@"callabike"];
    if(self.isBikeOffer){
        if(iscallabike){
            marker.secondaryCategory = @"Call a Bike";
        } else {
            marker.secondaryCategory = @"Fahrradverleih";
        }
    } else {
        if(isFlinkster){
            marker.secondaryCategory = @"Flinkster";
        } else {
            marker.secondaryCategory = @"Carsharing";
        }
    }
    marker.userData = @{@"venue": self, @"level":@0};
    return marker;
}


+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"shareableId": @"id",
             @"externalId": @"external_id",
             @"name": @"name",
             @"address": @"address",
             @"typeName": @"type_name",
             @"translatedTypeName": @"type_name_i18n",
             @"city": @"city",
             @"data": @"data",
             @"latitude": @"latitude",
             @"longitude": @"longitude"
             };
}


@end
