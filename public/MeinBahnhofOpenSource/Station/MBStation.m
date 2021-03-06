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
#import "MBPlatformAccessibility.h"

@interface MBStation()

@property (nonatomic, copy) NSArray *eva_ids;
@property (nonatomic, copy) NSArray  *position; //lat,lng
@property (nonatomic, strong) NSMutableArray *platformAccessibiltyData;

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
    
    [MBMarker renderTextIntoIconFor:marker markerIcon:marker.icon titleText:self.title zoomForIconWithText:1];
    marker.icon = marker.iconWithText;
    
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

-(BOOL)hasDirtService{
    int stations[] = {
    22,
    23,
    28,
    80,
    85,
    87,
    108,
    116,
    7719,
    169,
    177,
    187,
    192,
    202,
    7966,
    203,
    207,
    220,
    237,
    251,
    264,
    2886,
    315,
    316,
    332,
    6129,
    334,
    392,
    393,
    430,
    4361,
    450,
    475,
    503,
    504,
    520,
    525,
    6340,
    526,
    2035,
    1071,
    530,
    4809,
    5016,
    4859,
    533,
    534,
    53,
    535,
    536,
    537,
    538,
    527,
    539,
    528,
    540,
    541,
    542,
    543,
    544,
    595,
    545,
    546,
    547,
    548,
    549,
    7720,
    550,
    551,
    552,
    553,
    554,
    532,
    555,
    556,
    557,
    559,
    561,
    563,
    7721,
    565,
    566,
    6723,
    567,
    568,
    571,
    7910,
    591,
    592,
    7726,
    7958,
    622,
    623,
    811,
    8281,
    6792,
    628,
    631,
    639,
    643,
    652,
    655,
    660,
    661,
    688,
    723,
    724,
    763,
    4568,
    767,
    779,
    780,
    782,
    783,
    785,
    791,
    801,
    803,
    814,
    816,
    835,
    840,
    855,
    8251,
    888,
    951,
    963,
    968,
    970,
    972,
    1028,
    1040,
    1056,
    1062,
    8248,
    1077,
    1104,
    1108,
    1126,
    1141,
    1146,
    1180,
    1289,
    1341,
    1343,
    1352,
    1374,
    1390,
    1401,
    1484,
    1491,
    7722,
    1501,
    1507,
    1537,
    1590,
    1610,
    1634,
    1641,
    1645,
    1659,
    1683,
    1690,
    1782,
    1787,
    1793,
    8192,
    1821,
    1866,
    7982,
    1889,
    1893,
    1901,
    1932,
    1944,
    1967,
    1969,
    1973,
    2008,
    2109,
    2120,
    2218,
    529,
    2262,
    2268,
    2288,
    2391,
    2438,
    2447,
    2498,
    2500,
    7772,
    2513,
    2514,
    2517,
    2519,
    2528,
    733,
    2621,
    2545,
    2610,
    7728,
    2622,
    2623,
    2628,
    2632,
    7729,
    2678,
    2681,
    2689,
    2691,
    2708,
    2716,
    2743,
    2747,
    5817,
    2760,
    2767,
    2790,
    2832,
    2866,
    2884,
    2890,
    2900,
    2901,
    2912,
    2923,
    2924,
    2927,
    2928,
    2930,
    2162,
    3821,
    4820,
    2944,
    2961,
    1670,
    3493,
    2998,
    3006,
    3008,
    3012,
    3032,
    7759,
    3067,
    3094,
    3095,
    3096,
    7723,
    3107,
    3127,
    3135,
    3200,
    6660,
    3201,
    3299,
    3318,
    3320,
    3329,
    3343,
    3394,
    3402,
    3420,
    1496,
    3750,
    3463,
    3464,
    3487,
    3491,
    3511,
    7144,
    3611,
    3617,
    3631,
    3658,
    3662,
    104,
    2264,
    4024,
    3668,
    3670,
    3671,
    3673,
    3703,
    7730,
    3746,
    3749,
    3768,
    3801,
    3828,
    915,
    3832,
    3847,
    3856,
    5032,
    3857,
    3871,
    3872,
    3881,
    3891,
    3898,
    3925,
    3942,
    3947,
    3987,
    3997,
    4027,
    4032,
    4053,
    4054,
    4066,
    4076,
    6840,
    7727,
    4079,
    4081,
    4092,
    4120,
    4204,
    4234,
    4241,
    4266,
    4280,
    7655,
    39,
    135,
    4546,
    2771,
    7813,
    8247,
    5928,
    4329,
    7908,
    4382,
    4385,
    4425,
    4492,
    4522,
    4557,
    4566,
    4582,
    167,
    4593,
    4692,
    4722,
    4731,
    4735,
    4739,
    7774,
    4767,
    4768,
    7731,
    4777,
    4778,
    7762,
    890,
    4846,
    4847,
    4848,
    4880,
    5824,
    4854,
    8356,
    4905,
    7662,
    7732,
    4950,
    4965,
    4976,
    4998,
    5012,
    5026,
    5036,
    5070,
    4914,
    5099,
    5100,
    5122,
    5129,
    5145,
    5159,
    5169,
    5213,
    5247,
    5251,
    4080,
    5287,
    5340,
    2879,
    5365,
    5484,
    5496,
    5507,
    5523,
    5537,
    5545,
    5559,
    5563,
    5564,
    5598,
    558,
    5659,
    5665,
    560,
    5684,
    7734,
    5755,
    5763,
    5818,
    5819,
    800,
    5825,
    5839,
    5842,
    2957,
    5844,
    5854,
    5876,
    5896,
    7736,
    5934,
    781,
    997,
    3369,
    5996,
    3030,
    5999,
    6028,
    6042,
    6058,
    6059,
    6060,
    7761,
    6066,
    6071,
    7146,
    6123,
    6164,
    2871,
    6217,
    6251,
    6298,
    6323,
    6335,
    6337,
    6336,
    6428,
    6447,
    6453,
    6454,
    6466,
    6472,
    6537,
    6539,
    8249,
    6550,
    6551,
    8214,
    7756,
    6617,
    6664,
    6683,
    6686,
    6689,
    6706,
    6707,
    6708,
    7760,
    6720,
    6724,
    6731,
    6744,
    6763,
    6771,
    7590,
    5415,
    6807,
    6824,
    6871,
    6898,
    6899,
    6939,
    6940,
    6945,
    6967,
    7755,
    6998,
    7010
    };

    NSInteger currentId = self.mbId.integerValue;
    BOOL stationHasDirtyService = false;
    for(NSInteger i=0; i<(sizeof stations) / (sizeof stations[0]); i++){
        int stationid = stations[i];
        if(currentId == stationid){
            stationHasDirtyService = true;
            break;
        }
    }
    return stationHasDirtyService;
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
    return true;
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
-(BOOL)useOSM{
    //return true;
    BOOL useDB = [
           @[@"3329",
             @"1",
             @"6279",
             @"1528",
             @"1289",
             @"4234",
             @"3723",
             @"393",
             @"527",
             @"528",
             @"4241",
             @"530",
             @"2457",
             @"1690",
             @"6945",
             @"3107",
             @"4648",
             @"3881",
             @"2218",
             @"7982",
             @"1071",
             @"3631",
             @"5169",
             @"4787",
             @"3124",
             @"53",
             @"1973",
             @"3127",
             @"4280",
             @"6323",
             @"3898",
             @"187",
             @"6077",
             @"1343",
             @"1856",
             @"2498",
             @"835",
             @"2628",
             @"1734",
             @"2120",
             @"4169",
             @"1866",
             @"6859",
             @"5451",
             @"2765",
             @"5840",
             @"2513",
             @"2514",
             @"724",
             @"3925",
             @"2518",
             @"855",
             @"6744",
             @"2648",
             @"1374",
             @"3807",
             @"2528",
             @"1634",
             @"3299",
             @"3174",
             @"1126",
             @"2537",
             @"622",
             @"2545",
             @"4593",
             @"5365",
             @"3320",
             @"1401",
             @"4859",
             @"767",
    ] containsObject:self.mbId.stringValue];
    return !useDB;
}

-(void)addPlatformAccessibility:(NSArray<MBPlatformAccessibility *> *)platformList{
    if(!self.platformAccessibiltyData){
        self.platformAccessibiltyData = [NSMutableArray arrayWithCapacity:20];
    }
    [self.platformAccessibiltyData addObjectsFromArray:platformList];
}
-(NSArray<MBPlatformAccessibility *> *)platformAccessibility{
    return self.platformAccessibiltyData;
}

-(void)updateStationWithDetails:(MBPTSStationResponse *)details{
    self.stationDetails = details;
    _category = details.category;
    _travelCenter = details.travelCenter;
    if(!CLLocationCoordinate2DIsValid(self.positionAsLatLng)){
        //only update position if it is missing
        _position = details.position;
    }
    if(self.eva_ids.count == 0){
        //only update eva_ids if they are missing
        _eva_ids = details.evaIds;
    }
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
    
    for(RIMapPoi* poi in self.riPois){
        if([poi.title isEqualToString:platformNumber] && [poi.menusubcat isEqualToString:@"Bahngleise"]){
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
