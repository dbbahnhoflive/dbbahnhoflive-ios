// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBStation.h"
#import "MBMarker.h"
#import "MBNewsResponse.h"
#import "LevelplanWrapper.h"

#import "FacilityStatus.h"
#import "RIMapPoi.h"
#import "RIMapMetaData.h"

@interface MBStation()

@property (nonatomic, copy) NSArray *eva_ids;
@property (nonatomic, copy) NSArray  *position; //lat,lng

@end

@implementation MBStation

@synthesize facilityStatusPOIs = _facilityStatusPOIs;
@synthesize levels = _levels;

-(instancetype)initWithId:(NSNumber *)stationId name:(NSString *)title evaIds:(NSArray<NSString*>*)evaIds location:(NSArray<NSNumber*>*)location{
    self = [super init];
    if(self){
        _mbId = stationId;
        _title = title;
        if(evaIds.count > 0){
            _eva_ids = evaIds;
        }
        if(location.count > 0){
            _position = location;
        }

    }
    return self;
}

- (CLLocationCoordinate2D) positionAsLatLng
{
    //prefer PTS, fallback to rimaps
    if(self.position.count == 2){
        return CLLocationCoordinate2DMake([[self.position firstObject] doubleValue], [[self.position lastObject] doubleValue]);
    } else {
        if(self.additionalRiMapData){
            CLLocationCoordinate2D loc = self.additionalRiMapData.coordinate;
            if(CLLocationCoordinate2DIsValid(loc)){
                return loc;
            }
        }
    }
    switch(self.mbId.integerValue){
        case STATION_ID_BERLIN_HBF:
            return CLLocationCoordinate2DMake( 52.525592, 13.369545 );
        case STATION_ID_FRANKFURT_MAIN_HBF:
            return CLLocationCoordinate2DMake( 50.107145, 8.663789 );
        case STATION_ID_HAMBURG_HBF:
            return CLLocationCoordinate2DMake( 53.552736, 10.006909 );
        case STATION_ID_MUENCHEN_HBF:
            return CLLocationCoordinate2DMake( 48.140232, 11.558335 );
        case STATION_ID_KOELN_HBF:
            return CLLocationCoordinate2DMake( 50.94303, 6.958729  );
        //fix for some missing geo positions in PTS data... to be removed after PTS includes data
        case 8325://Ingolstadt Audi
            return CLLocationCoordinate2DMake(48.791128, 11.406021);
        case 7433://Dornstetten-Aach
            return CLLocationCoordinate2DMake(48.473378, 8.482925);

    }
    return kCLLocationCoordinate2DInvalid;
}


- (GMSMarker*)markerForStation
{
    // set the map's center to the station position and add the pin
    CLLocationCoordinate2D position = [self positionAsLatLng];
    if(!CLLocationCoordinate2DIsValid(position)){
        return nil;
    }
    // add station pin annotation to map

    MBMarker *marker = [MBMarker markerWithPosition:position andType:STATION];
    marker.icon = [UIImage db_imageNamed:@"DBMapPin"];
    marker.appearAnimation = kGMSMarkerAnimationPop;
    return marker;
}


-(NSArray*)getFacilityMapMarker{
    NSMutableArray* facilityMarker = [NSMutableArray arrayWithCapacity:self.facilityStatusPOIs.count];
    for (FacilityStatus *facilityStatusPOI in self.facilityStatusPOIs) {
        MBMarker *marker = [MBMarker markerWithPosition:[facilityStatusPOI centerLocation] andType:FACILITY];
        marker.userData = @{@"venue": facilityStatusPOI};
        marker.category = @"Wegeleitung";
        marker.secondaryCategory = @"Aufzug";
        marker.zoomLevel = 16;//19 in RIMaps!
        marker.icon = [facilityStatusPOI iconForState];
        marker.zIndex = 800;
        [facilityMarker addObject:marker];
    }
    return facilityMarker;
}


- (NSArray*)levels
{
    return [_levels sortedArrayUsingComparator:^NSComparisonResult(LevelplanWrapper *obj1, LevelplanWrapper *obj2) {
        return [@(obj1.levelNumber) compare: @(obj2.levelNumber)];
    }];
}




+ (NSArray*) categoriesForShoppen
{
    return @[
             @"Dienstleistungen",
             @"Bäckereien",
             @"Gastronomie",
             @"Presse & Buch",
             @"Shops",
             @"Gesundheit & Pflege",
             @"Lebensmittel",
             @"Reisebüro",//looks like this is not used?
            ];
}

+ (NSArray*) categoriesForNewsAndEvents
{
    return @[
             @"News & Events"
             ];
}



-(BOOL)isGreenStation{
    NSString* stationId = self.mbId.stringValue;
    return [self isFutureStation] ||
           [@[ @"2514", // Hamburg Hbf
               @"1866", // Frankfurt (Main) Hbf
               @"4234", // München Hbf
               @"3320", // Köln Hbf
               @"6071", // Stuttgart Hbf
               @"1071", // Berlin Hbf
               @"2545", // Hannover Hbf
               @"1401", // Düsseldorf Hbf
               @"527", // Berlin Friedrichstraße
               @"4809", // Berlin Ostkreuz
               @"4593", // Nürnberg Hbf
               @"528", // Berlin Gesundbrunnen
               @"4859", // Berlin Südkreuz
               @"4240", // München Marienplatz
               @"53" // Berlin Alexanderplatz
               ] containsObject:stationId];
}
-(BOOL)isFutureStation{
    NSString* stationId = self.mbId.stringValue;
    BOOL res = [@[ @"27", // Ahrensburg
                               @"2516", // Sternschanze
                               @"6859", // Wolfsburg Hbf
                               @"1059", // Coburg
                               @"1908", // Freising
                               @"5226", // Renningen (noch unklar, wird vll kein Zukunftsbahnhof sein)
                               @"2648", // Heilbronn Hbf
                               @"2498", // Halle (Saale) Hbf
                               @"6692", // Wernigerode
                               @"4280", // Münster Hbf (Anm. Maik: Münster (Westfalen))
                               @"2510", // Haltern am See
                               @"4859", // Berlin Südkreuz
                               @"791", // Berlin Bornholmer Straße
                               @"1077", // Cottbus
                               @"7171", // Offenbach Marktplatz
                               @"2827" // Hofheim (Anm. Maik: Hofheim(Taunus))
                               ] containsObject:stationId];
    return res;
}
-(BOOL)hasChatbot{
    NSString* stationId = self.mbId.stringValue;
    BOOL res = [@[
        @"27", // Ahrensburg
        @"2516", // Sternschanze
        @"6859", // Wolfsburg Hbf
        @"1059", // Coburg
        @"1908", // Freising
        @"5226", // Renningen (noch unklar, wird vll kein Zukunftsbahnhof sein)
        @"2648", // Heilbronn Hbf
        @"2498", // Halle (Saale) Hbf
        @"6692", // Wernigerode
        @"4280", // Münster Hbf (Anm. Maik: Münster (Westfalen))
        @"2510", // Haltern am See
        @"4859", // Berlin Südkreuz
        @"791", // Berlin Bornholmer Straße
        @"1077", // Cottbus
        @"7171", // Offenbach Marktplatz
        @"2827", // Hofheim (Anm. Maik: Hofheim(Taunus))
        
        @"2514", // Hamburg Hbf
        @"1866", // Frankfurt (Main) Hbf
        @"4234", // München Hbf
        @"3320", // Köln Hbf
        @"1071", // Berlin Hbf
        @"3631", // Leipzig Hbf
        @"1401", // Düsseldorf Hbf
        @"2545", // Hannover Hbf
        @"527",  // Berlin Friedrichstraße
        @"4809", // Berlin Ostkreuz
        
        //BAHNHOFLIVE-1740
        //Bahnhöfe BM Bamberg
        @"393",
        @"439",
        @"2818",
        @"1059",
        @"3700",
        @"2784",
        @"3979",
        @"3458",
        @"3427",
        @"4384",
        @"5963",
        @"4444",
        @"3187",
        @"4227",
        @"1427",
        @"5307",
        @"991",
        @"852",
        @"6065",
        @"1009",
        @"5302",
        @"5176",
        @"1442",
        @"4296",
        @"1435",
        @"1479",
        @"6983",
        @"6974",
        @"8056",
        @"1431",
        @"2810",
        @"4658",
        @"3467",
        @"1083",
        @"4645",
        @"5028",
        @"3844",
        @"5989",
        @"5811",
        @"2506",
        @"3896",
        @"431",
        @"5810",
        @"2819",
        @"5158",
        @"2674",
        @"351",
        @"5724",
        @"5166",
        @"8057",
        @"6032",
        @"1270",
        @"4095",
        @"2378",
        @"3980",
        @"2371",
        @"6366",
        @"4167",
        @"1446",
        @"5630",
        @"6244",
        @"5812",
        @"5573",
        @"5835",
        @"648",
        @"4437",
        @"1840",
        @"2564",
        @"5673",
        @"1769",
        @"2984",
        @"6912",
        @"4021",
        @"4436",
        @"1082",
        @"5115",
        @"6755",
        @"3834",
        @"5352",
        @"3976",
        @"3990",
        @"6483",
        @"3306",
        @"186",
        @"5966",
        @"1644",
        @"3994",
        @"5229",
        @"6029",
        @"5622",
        @"5813",
        @"2414",
        @"3188",
        @"6955",
        @"1060",
        @"1828",
        @"3897",
        @"2474",
        @"6941",
        @"5392",
        @"2872",
        @"2761",
        @"3924",
        @"5977",
        @"6331",
        @"5833",

        //Bahnhöfe MB Braunschweig
        @"11",
        @"54",
        @"56",
        @"253",
        @"742",
        @"279",
        @"281",
        @"287",
        @"8081",
        @"326",
        @"328",
        @"8064",
        @"369",
        @"398",
        @"415",
        @"625",
        @"736",
        @"738",
        @"798",
        @"835",
        @"836",
        @"891",
        @"1022",
        @"1069",
        @"1172",
        @"1184",
        @"1448",
        @"1499",
        @"1520",
        @"1577",
        @"1586",
        @"1759",
        @"1886",
        @"1915",
        @"1937",
        @"2107",
        @"2122",
        @"2123",
        @"2129",
        @"2202",
        @"2218",
        @"2334",
        @"2543",
        @"2557",
        @"2565",
        @"2594",
        @"2618",
        @"2677",
        @"2740",
        @"2742",
        @"2765",
        @"2766",
        @"2841",
        @"2889",
        @"3132",
        @"3295",
        @"3354",
        @"3407",
        @"3523",
        @"3582",
        @"3622",
        @"894",
        @"8085",
        @"3760",
        @"4028",
        @"4031",
        @"4229",
        @"4279",
        @"4374",
        @"4581",
        @"4586",
        @"4587",
        @"4746",
        @"4756",
        @"8087",
        @"8086",
        @"4802",
        @"4885",
        @"5384",
        @"5478",
        @"5479",
        @"5480",
        @"5481",
        @"5482",
        @"5483",
        @"5510",
        @"5540",
        @"5579",
        @"8010",
        @"5656",
        @"5681",
        @"5797",
        @"8011",
        @"5958",
        @"5975",
        @"6095",
        @"6257",
        @"6310",
        @"6380",
        @"6397",
        @"6409",
        @"6412",
        @"6440",
        @"6444",
        @"6450",
        @"6452",
        @"6470",
        @"6499",
        @"6574",
        @"8065",
        @"6741",
        @"6833",
        @"6838",
        @"6850",
        @"6859",
        @"6879",
        @"6904",
        
    ] containsObject:stationId];
    return res && [self isChatbotPeriod];
}
-(BOOL)isChatbotPeriod{
    NSDate* start = [self dateForYear:2019 month:11 day:18];
    NSDate* end = [self dateForYear:2020 month:12 day:31+1];
    NSDate* now = [NSDate date];
    BOOL isInPeriod = [now earlierDate:start] == start && [now laterDate:end] == end;
    return isInPeriod;
}
-(NSDate*)dateForYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    [gregorian setLocale:[NSLocale localeWithLocaleIdentifier:@"de_DE"]];
    [gregorian setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Berlin"]];
    NSDateComponents *comps = [gregorian components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear|NSCalendarUnitHour|NSCalendarUnitMinute fromDate:[NSDate date]];
    comps.day = day;
    comps.month = month;
    comps.year = year;
    comps.hour = 0;
    comps.minute = 0;
    return [gregorian dateFromComponents: comps];
}

-(BOOL)hasPickPack{
    return NO;
    /*
    NSString* stationId = self.mbId.stringValue;
    BOOL res = [@[ @"53", // Berlin Alexanderplatz
                   @"1071", // Berlin Hbf
                   @"527", // Berlin Friedrichstraße
                   @"528", // Berlin Gesundbrunnen
                   @"3067", // Berlin Jungfernheide
                   @"4809", // Berlin Ostkreuz
                   @"561", // Berlin-Spandau
                   @"533", // Berlin Zoologischer Garten
                   @"4859", // Berlin Südkreuz
                   @"530", // Berlin Ostbahnhof
    ] containsObject:stationId];
    return res;*/
}

-(BOOL)hasOccupancy{
    return true;//[@"2514" isEqualToString:self.mbId.stringValue];//hamburg
}


-(void)updateStationWithDetails:(MBPTSStationResponse *)details{
    self.stationDetails = details;
    _eva_ids = details.evaIds;
    _category = details.category;
    _position = details.position;
    _travelCenter = details.travelCenter;
    NSNumber* newStadaId = details.stadaIdNumber;
    if(_mbId && ![_mbId isEqualToNumber:newStadaId]){
        NSLog(@"WARNING: STADA ID changed from %@ to %@",_mbId,newStadaId);
    }
    _mbId = newStadaId;
}
-(NSArray *)stationEvaIds{
    //prefer PTS, fallback to rimaps
    if(_eva_ids){
        return _eva_ids;
    }
    if(self.additionalRiMapData){
        NSArray* arr = self.additionalRiMapData.evaNumbers;
        if(arr.count > 0){
            return arr;
        }
    }
    switch(self.mbId.integerValue){
        case STATION_ID_BERLIN_HBF:
            return @[@"8011160",@"8089021",@"8098160"];
        case STATION_ID_FRANKFURT_MAIN_HBF:
            return @[@"8000105", @"8098105"];
        case STATION_ID_HAMBURG_HBF:
            return @[@"8002549", @"8098549"];
        case STATION_ID_MUENCHEN_HBF:
            return @[@"8000261", @"8070193", @"8098261", @"8098262", @"8098263"];
        case STATION_ID_KOELN_HBF:
            return @[ @"8000207" ];
    }
    return nil;
}

-(BOOL)displayStationMap{
    return self.riPois.count > 0 && self.levels.count > 0;
}

-(BOOL)hasShops{
    return self.riPoiCategories.count > 0 || self.einkaufsbahnhofCategories.count > 0;
}

-(RIMapPoi *)poiForPlatform:(NSString *)platformNumber{
    //remove characters (e.g. transform "5A-G" into "5")
    platformNumber = [[platformNumber componentsSeparatedByCharactersInSet:
                            [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
    
    NSString* searchPlatform = [NSString stringWithFormat:@"Gleis %@",platformNumber];
    for(RIMapPoi* poi in self.riPois){
        if([poi.title isEqualToString:searchPlatform]){
            return poi;
        }
    }
    return nil;
}

-(void)setRiPois:(NSArray *)riPois{
    _riPois = riPois;
    self.riPoiCategories = [RIMapPoi generatePXRGroups:_riPois];
}

@end
