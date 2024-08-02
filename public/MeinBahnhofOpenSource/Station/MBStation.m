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
#import "MBPlatformAccessibility.h"
#import "MBOSMOpeningHoursParser.h"
#import "UIImage+MBImage.h"
#import "RIMapSEV.h"
#import "RIMapConfigItem.h"
#import "MBRISStationsRequestManager.h"

@interface MBStation()

@property (nonatomic, copy) NSArray *eva_ids;
@property (nonatomic, copy) NSArray  *position; //lat,lng
@property (nonatomic, strong) NSMutableArray *platformAccessibiltyData;
@property (nonatomic,strong) NSMutableArray<MBPlatformAccessibility*>* mergedPlatformData;
@end

@implementation MBStation


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
        [self logicTest];
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"dealloc MBStation");
}

#define STATION_ID_BERLIN_HBF 1071
#define STATION_ID_FRANKFURT_MAIN_HBF 1866
#define STATION_ID_HAMBURG_HBF 2514
#define STATION_ID_MUENCHEN_HBF 4234
#define STATION_ID_KOELN_HBF 3320

- (CLLocationCoordinate2D) positionAsLatLng
{
    //prefer RIS:Station, fallback to rimaps
    if(self.position.count == 2){
        return CLLocationCoordinate2DMake([[self.position firstObject] doubleValue], [[self.position lastObject] doubleValue]);
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

    MBMarker *marker = [MBMarker markerWithPosition:position andType:MBMarkerType_STATION];
    if(UIAccessibilityIsVoiceOverRunning()){
        marker.title = self.title;
    }
    marker.icon = [UIImage db_imageNamed:@"DBMapPin"];
    marker.appearAnimation = kGMSMarkerAnimationPop;
    
    [MBMarker renderTextIntoIconFor:marker markerIcon:marker.icon titleText:self.title zoomForIconWithText:1];
    marker.icon = marker.iconWithText;
    
    return marker;
}


-(NSArray*)getFacilityMapMarker{
    NSMutableArray* facilityMarker = [NSMutableArray arrayWithCapacity:self.facilityStatusPOIs.count];
    for (FacilityStatus *facilityStatusPOI in self.facilityStatusPOIs) {
        MBMarker *marker = [MBMarker markerWithPosition:[facilityStatusPOI centerLocation] andType:MBMarkerType_FACILITY];
        if(UIAccessibilityIsVoiceOverRunning()){
            marker.title = facilityStatusPOI.title;
        }
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
-(NSArray<MBMarker*>*)getSEVMapMarker{
    NSMutableArray* sevMarker = [NSMutableArray arrayWithCapacity:self.sevPois.count];
    
    NSString* cat = @"Öffentlicher Nahverkehr";
    NSString* subcat = @"Ersatzverkehr";
    RIMapConfigItem* config = [RIMapPoi configForMenuCat:cat subCat:subcat];
    
    for (RIMapSEV *sev in self.sevPois) {
        if(CLLocationCoordinate2DIsValid(sev.coordinate)){
            MBMarker *marker = [MBMarker markerWithPosition:sev.coordinate andType:MBMarkerType_SEV];
            if(UIAccessibilityIsVoiceOverRunning()){
                marker.title = sev.text;
            }
            marker.userData = @{@"venue": sev};
            marker.category = cat;
            marker.secondaryCategory = subcat;
            marker.zoomLevel = config.zoom.integerValue;
            marker.icon = [UIImage db_imageNamed:config.icon];
            marker.zIndex = 800;
            [sevMarker addObject:marker];
        }
    }
    return sevMarker;
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
    return
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
               @"53", // Berlin Alexanderplatz
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
               @"2827" // Hofheim (Anm. Maik: Hofheim(Taunus))
               ] containsObject:stationId];
}
-(BOOL)hasChatbot{
    return true;
}

-(BOOL)hasSEVStations{
    return self.sevPois.count > 0;
}

//BAHNHOFLIVE-2395
-(void)logicTest{
#if TARGET_IPHONE_SIMULATOR
    NSInteger size = self.adHocBoxStations.count;
    NSLog(@"testing size of adhoc tables, expecting %ld",(long)size);
    /*if(size != self.additionalEvaIdsMapping_StadaToEvas.count){
        NSAssert(false, @"entry missmatch");
    }
    if(size != self.mainEvaIdForStadaAdditions.count){
        NSAssert(false, @"entry missmatch");
    }
    NSDictionary* mainEvas = self.mainEvaIdForStadaAdditions;
    NSDictionary* additionalEva = self.additionalEvaIdsMapping_StadaToEvas;
    for(NSString* number in self.adHocBoxStations){
        if(mainEvas[number] == nil){
            NSAssert(false, @"missing main eva %@",number);
        }
        if(additionalEva[number] == nil){
            NSAssert(false, @"missing additional eva %@",number);
        }
    }*/
    for(NSString* number in self.accompanimentStations){
        if(![self.adHocBoxStations containsObject:number]){
            NSAssert(false, @"all accompaniment stations should have adhoc %@",number);
        }
    }
#endif
}
-(BOOL)hasARTeaser{
    if(self.hasStaticAdHocBox && !UIAccessibilityIsVoiceOverRunning()){
        /*
        NSString* stationId = self.mbId.stringValue;
        NSString* startDateString;
        if([stationId isEqualToString:@"6945"]){
            startDateString = @"2023-05-29 00:00:01 GMT+02:00";
        } else if([stationId isEqualToString:@"4593"]){
            startDateString = @"2023-08-04 00:00:01 GMT+02:00";
        } else {
            return false;
        }
        if([NSUserDefaults.standardUserDefaults boolForKey:@"AktiverErsatzverkehr"]){
            return true;
        }
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
        NSDate* startDate = [dateFormatter dateFromString: startDateString];
        return startDate.timeIntervalSinceNow < 0;
         */
    }
    return false;
}

-(NSArray*)adHocBoxStations{
    //BAHNHOFLIVE-2519
    NSArray* data = self.sevStationsData;
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:data.count];
    for(NSArray* entry in data){
        [res addObject:entry[1]];
    }
    return res;
}

-(void)testSEVStationsDataIntegrity{
    NSLog(@"testSEVStationsDataIntegrity");
    NSMutableString* res = [NSMutableString new];
    for(NSArray* list in self.sevStationsData){
        NSString* name = list[0];
        NSString* stada = list[1];
        //sleep(2);
        [MBRISStationsRequestManager.sharedInstance searchStationByStada:stada success:^(MBStationFromSearch *station) {
            [res appendFormat:@"%@, %@, %@\n",name,stada,station.eva_ids.firstObject];
            if([station.title isEqualToString:name]){
                NSLog(@"MATCH: stada %@ was returned as \"%@\", evaId %@",stada,station.title,station.eva_ids);
                //match
            } else {
                NSLog(@"FAIL: stada %@ was returned as \"%@\" and not \"%@\", evaIds %@",stada,station.title, name, station.eva_ids);
            }
        } failureBlock:^(NSError * error) {
            NSLog(@"FAIL: for %@: %@",name,error);
        }];
    }
    NSLog(@"final list: \n%@",res);
}

-(NSArray<MBStationFromSearch*>*)sevStationsMatchingSearchString:(NSString*)text{
    NSString* inputLowercase = text.lowercaseString;
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:20];
    for(NSArray* list in self.sevStationsData){
        NSString* name = list[0];
        if([name.lowercaseString containsString:inputLowercase]){
            NSString* stada = list[1];
            MBStationFromSearch* s = [[MBStationFromSearch alloc] init];
            s.title = name;
            s.stationId = [NSNumber numberWithLongLong:stada.longLongValue];
            [res addObject:s];
        }
    }
    return res;
}

-(NSArray<NSArray*>*)sevStationsData{
    //BAHNHOFLIVE-2519
    return @[
        //title, StadaID, Wegbegleitung
        @[@"Alsheim", @"66", @true,],
        @[@"Bensheim", @"488", @true,],
        @[@"Bensheim-Auerbach", @"489", @true,],
        @[@"Biblis", @"614", @true,],
        @[@"Bickenbach (Bergstr)", @"618", @true,],
        @[@"Biebesheim", @"619", @true,],
        @[@"Bobenheim", @"716", @true,],
        @[@"Bobstadt", @"721", @true,],
        @[@"Bodenheim", @"739", @true,],
        @[@"Bürstadt", @"1002", @true,],
        @[@"Bürstadt (Ried)", @"7177", @true,],
        @[@"Darmstadt Hbf", @"1126", @true,],
        @[@"Darmstadt Süd", @"1129", @true,],
        @[@"Darmstadt-Eberstadt", @"1131", @true,],
        @[@"Dienheim", @"8252", @true,],
        @[@"Frankenthal Hbf", @"1848", @true,],
        @[@"Frankenthal Süd", @"8210", @true,],
        @[@"Frankfurt am Main Flughafen Fernbahnhof", @"7982", @true,],
        @[@"Frankfurt (Main) Flughafen Regionalbahnhof", @"1849", @true,],
        @[@"Frankfurt (Main) Hbf", @"1866", @true,],
        @[@"Frankfurt am Main Stadion", @"1854", @true,],
        @[@"Frankfurt am Main Gateway Gardens", @"8268", @true,],
        @[@"Frankfurt (Main) Niederrad", @"1876", @true,],
        @[@"Gernsheim", @"2097", @true,],
        @[@"Groß Gerau", @"2299", @true,],
        @[@"Groß Gerau-Dornberg", @"2300", @true,],
        @[@"Groß Gerau-Dornheim", @"1278", @true,],
        @[@"Groß Rohrheim", @"2316", @true,],
        @[@"Guntersblum", @"2419", @true,],
        @[@"Hähnlein-Alsbach", @"2471", @true,],
        @[@"Heddesheim/Hirschberg", @"2362", @true,],
        @[@"Hemsbach", @"2684", @true,],
        @[@"Heppenheim (Bergstr)", @"2693", @true,],
        @[@"Hofheim (Ried)", @"2826", @true,],
        @[@"Ladenburg", @"3490", @true,],
        @[@"Lampertheim", @"3500", @true,],
        @[@"Langen (Hess)", @"3524", @true,],
        @[@"Laudenbach (Bergstr)", @"3578", @true,],
        @[@"Lorsch", @"3786", @true,],
        @[@"Ludwigshafen (Rhein) Hbf", @"3837", @true,],
        @[@"Ludwigshafen (Rhein) Mitte", @"7385", @true,],
        @[@"Ludwigshafen-Oggersheim", @"3839", @true,],
        @[@"Mainz Hbf", @"3898", @true,],
        @[@"Mainz Römisches Theater", @"3900", @true,],
        @[@"Mainz-Laubenheim", @"3905", @true,],
        @[@"Mannheim-Handelshafen", @"3929", @false,],
        @[@"Mannheim Hbf", @"3925", @true,],
        @[@"Mannheim-Käfertal", @"3930", @false,],
        @[@"Mannheim-Luzenberg", @"3931", @true,],
        @[@"Mannheim-Neckarstadt", @"3933", @true,],
        @[@"Mannheim-Waldhof", @"3936", @true,],
        @[@"Mettenheim", @"4082", @true,],
        @[@"Mörfelden", @"4174", @true,],
        @[@"Nackenheim", @"4293", @true,],
        @[@"Neu Isenburg", @"4351", @true,],
        @[@"Nierstein", @"4551", @true,],
        @[@"Oppenheim", @"4772", @true,],
        @[@"Osthofen", @"4808", @true,],
        @[@"Pfungstadt", @"8264", @true,],
        @[@"Riedrode", @"5272", @true,],
        @[@"Riedstadt-Goddelau", @"2161", @true,],
        @[@"Riedstadt-Wolfskehlen", @"3608", @true,],
        @[@"Stockstadt (Rhein)", @"6035", @true,],
        @[@"Weinheim-Sulzbach", @"8290", @true,],
        @[@"Walldorf (Hess)", @"6503", @true,],
        @[@"Weinheim (Bergstr) Hbf", @"6622", @true,],
        @[@"Weinheim-Lützelsachsen", @"3873", @true,],
        @[@"Wiesloch-Walldorf", @"6759", @false,],
        @[@"Worms Hbf", @"6887", @true,],
        @[@"Zeppelinheim", @"6999", @true,],
        @[@"Zwingenberg (Bergstr)", @"7075", @true,],
    ];
}
-(NSArray*)accompanimentStationsData{
    NSArray* data = self.sevStationsData;
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:data.count];
    for(NSArray* entry in data){
        if(((NSNumber*)entry.lastObject).boolValue){
            [res addObject:entry];
        }
    }
    return res;
}
-(NSArray<NSString*>*)accompanimentStationsTitles{
    NSArray* data = self.accompanimentStationsData;
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:data.count];
    for(NSArray* entry in data){
        [res addObject:entry.firstObject];
    }
    [res sortUsingComparator:^NSComparisonResult(NSString*  _Nonnull obj1, NSString*  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    return res;
}
-(NSArray*)accompanimentStations{
    NSArray* data = self.accompanimentStationsData;
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:data.count];
    for(NSArray* entry in data){
        [res addObject:entry[1]];
    }
    return res;
}
-(NSDictionary*)additionalEvaIdsMapping_StadaToEvas{
    //stadaId -> additional evaids
    return @{
        /*@"6945" : @"8089299",
        @"6946" : @"220219",
        @"6808" : @"8071200",
        @"2206" : @[@"8071316", @"8071317"],
        @"4720" : @"820199",
        @"3973" : @"467422",
        @"5400" : @"462702",
        @"1181" : @"467125",
        @"927"  : @"8071313",
        @"3212" : @"465514",
        @"3001" : @"461619",
        @"3968" : @"683142",
        @"4443" : @"683174",
        @"8195" : @"679173",
        @"1591" : @"460530",
        @"2466" : @[@"8071318",@"8071319"],
        @"5060" : @"205271",
        @"5841" : @"683449",
        @"1988" : @"676317",
        @"1991" : @"677263",
        @"1984" : @"682635",
        @"4593" : @"8071247",
        @"3970" : @"8071323",
        @"1676" : @[@"8071314",@"8071315"],
        @"13"   : @"682886",
        @"7961" : @"468705",
        @"6775" : @"460395",
        @"3569" : @"8071322",
        @"2558" : @"678496",
        @"3556" : @[@"8071320", @"8071321"],
        @"5102" : @"460390",
*/
    };
}
-(NSDictionary<NSString*,NSString*>*)mainEvaIdForStadaAdditions{
    //stadaId->main evaId
    return @{
        /*@"6945" : @"8000260",
        @"6946" : @"8006582",
        @"6808" : @"8006488",
        @"2206" : @"8002333",
        @"4720" : @"8000818",
        @"3973" : @"8003881",
        @"5400" : @"8005198",
        @"1181" : @"8001421",
        @"927"  : @"8001225",
        @"3212" : @"8000479",
        @"3001" : @"8003081",
        @"3968" : @"8003876",
        @"4443" : @"8004323",
        @"8195" : @"8004336",
        @"1591" : @"8001783",
        @"2466" : @"8002517",
        @"5060" : @"8004901",
        @"5841" : @"8005557",
        @"1988" : @"8002152",
        @"1991" : @"8002155",
        @"1984" : @"8000114",
        @"4593" : @"8000284",
        @"3970" : @"8003878",
        @"1676" : @"8001877",
        @"13" :   @"8000420",
        @"7961" : @"8007856",
        @"6775" : @"8006448",
        @"3569" : @"8003567",
        @"2558" : @"8002596",
        @"3556" : @"8003552",
        @"5102" : @"8004923",*/
    };
}
-(NSString*)isAdditionalEvaId_MappedToMainEva:(NSString*)evaId{
    for(NSString* stada in self.additionalEvaIdsMapping_StadaToEvas.allKeys){
        id item = self.additionalEvaIdsMapping_StadaToEvas[stada];
        if([item isKindOfClass:NSArray.class]){
            NSArray* list = (NSArray*)item;
            for(NSString* eva in list){
                if([self evaIsIdentical:eva toEva:evaId]){
                    return self.mainEvaIdForStadaAdditions[stada];
                }
            }
        } else {
            NSString* eva = item;
            if([self evaIsIdentical:eva toEva:evaId]){
                return self.mainEvaIdForStadaAdditions[stada];
            }
        }
    }
    return nil;
}
-(NSArray<NSString*>*)additionalEvasForStationId:(NSString*)stationId{
    id item = self.additionalEvaIdsMapping_StadaToEvas[stationId];
    if(item){
        if([item isKindOfClass:NSArray.class]){
            return item;
        } else {
            return @[item];
        }
    }
    return nil;
}

-(BOOL)evaIsIdentical:(NSString*)eva1 toEva:(NSString*)eva2{
    return eva1.longLongValue == eva2.longLongValue;
}

-(BOOL)hasStaticAdHocBox{
    //BAHNHOFLIVE-2519
    NSString* stationId = self.mbId.stringValue;
    return [self hasStaticAdHocBox:stationId];
}
-(BOOL)hasStaticAdHocBox:(NSString*)stationId{
    BOOL isAffectedStation =
           [self.adHocBoxStations containsObject:stationId];
    if(isAffectedStation){
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
        NSDate* startDate = [dateFormatter dateFromString: @"2024-07-07 23:59:59 GMT+02:00"];
        BOOL afterStartDate = startDate.timeIntervalSinceNow < 0;//we are after the start date
        if([NSUserDefaults.standardUserDefaults boolForKey:@"AktiverErsatzverkehr"] || [NSUserDefaults.standardUserDefaults boolForKey:@"VorErsatzverkehr"]){
            return true;
        }
        if(afterStartDate){
            NSDate* endDate = [dateFormatter dateFromString: @"2024-12-14 23:59:59 GMT+02:00"];
            return endDate.timeIntervalSinceNow > 0;
        }
    }
    return false;
}
-(BOOL)hasAccompanimentService{
    NSString* stationId = self.mbId.stringValue;
    BOOL isAffectedStation = [self.accompanimentStations containsObject:stationId];
    if(isAffectedStation){
        if([NSUserDefaults.standardUserDefaults boolForKey:@"VorErsatzverkehr"]){
            return true;
        }
        if([NSUserDefaults.standardUserDefaults boolForKey:@"AktiverErsatzverkehr"]){
            return true;
        }
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
        NSDate* startDate = [dateFormatter dateFromString: @"2024-07-08 00:00:01 GMT+02:00"];
        BOOL afterStartDate = startDate.timeIntervalSinceNow < 0;//we are after the start date
        if(afterStartDate){
            NSDate* endDate = [dateFormatter dateFromString: @"2024-12-14 23:59:59 GMT+02:00"];
            return endDate.timeIntervalSinceNow > 0;
        }
    }
    return false;
}
-(BOOL)hasAccompanimentServiceActive{
    //BAHNHOFLIVE-2519
    BOOL isAffectedStation = self.hasAccompanimentService;
    if(isAffectedStation){
        if([NSUserDefaults.standardUserDefaults boolForKey:@"AktiverErsatzverkehr"]){
            return true;
        }
        if([NSUserDefaults.standardUserDefaults boolForKey:@"VorErsatzverkehr"]){
            return false;
        }
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
        
        NSDate* startDate = [dateFormatter dateFromString: @"2024-07-15 00:00:01 GMT+02:00"];
        BOOL afterStartDate = startDate.timeIntervalSinceNow < 0;//we are after the start date
        if(afterStartDate){
            NSDate* endDate = [dateFormatter dateFromString: @"2024-12-14 23:59:59 GMT+02:00"];
            return endDate.timeIntervalSinceNow > 0;
        }
    }
    return false;
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


-(BOOL)hasOccupancy{
    return false;//[@"2514" isEqualToString:self.mbId.stringValue];//hamburg
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

+(BOOL)stationShouldBeLoadedAsOPNV:(NSString *)stationId{
    return [@[@"5274", @"5530", @"6192", @"519", @"6762", @"4424", @"8309", @"424", @"2698", @"4399", @"6235"] containsObject:stationId];//BAHNHOFLIVE-2094
}

-(void)updateEvaIds:(NSArray<NSString *> *)evaIds{
    self.eva_ids = evaIds;
}

-(void)updateStationWithDetails:(MBStationDetails *)details{
    self.stationDetails = details;
    _travelCenter = details.nearestTravelCenter;
    if(!CLLocationCoordinate2DIsValid(self.positionAsLatLng) && CLLocationCoordinate2DIsValid(details.coordinate)){
        //only update position if it is missing
        _position = @[ @(details.coordinate.latitude), @(details.coordinate.longitude) ];
    }
}

-(void)parseOpeningTimesWithCompletion:(void (^)(void))completion{
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    NSString* times = self.stationDetails.dbInfoOSMTimes;
    //testdata:
    //times = @"Mo-Su 00:00-24:00;PH 00:00-24:00";
    //times = @"Mo-Su 10:00-12:00,15:00-18:00; Di 21:00-02:00";
    //times = @"Mo-Sa 10:00-20:00; Tu off";
    //times = @"Mo-Sa 08:00-13:00,14:00-17:00 || \"by appointment\"";
    //times = @"Tu,Do-Fr 10:00-13:00,15:00-18:00; Tu 12:00-14:00,15:00-01:01; Mo 12:00-13:00 open \"nur an Vollmond\", Mo 18:00-18:05; Su 00:00-24:00; PH 10:00-10:05";
    [MBOSMOpeningHoursParser.sharedInstance parseOSM:times forStation:self completion:^(MBOSMOpeningWeek * _Nullable week) {
        //NSLog(@"parsed DB_Information times %@",week);
        self.stationDetails.dbInfoOpeningTimesOSM = week;
        dispatch_group_leave(group);
    }];
    
    dispatch_group_enter(group);
    times = self.stationDetails.localServiceOSMTimes;
    [MBOSMOpeningHoursParser.sharedInstance parseOSM:times forStation:self completion:^(MBOSMOpeningWeek * _Nullable week) {
        //NSLog(@"parsed DB_Information times %@",week);
        self.stationDetails.localServiceOpeningTimesOSM = week;
        dispatch_group_leave(group);
    }];

    
    times = self.travelCenter.openingHoursOSMString;
    if(times.length > 0){
        dispatch_group_enter(group);
        [MBOSMOpeningHoursParser.sharedInstance parseOSM:times forStation:self completion:^(MBOSMOpeningWeek * _Nullable week) {
            //NSLog(@"parsed Travelcenter times %@",week);
            self.travelCenter.openingTimesOSM = week;
            dispatch_group_leave(group);
        }];
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        completion();
    });
}

-(NSArray *)stationEvaIds{
    //prefer RIS:Station, fallback to rimaps
    if(_eva_ids){
        /*
        if([self hasStaticAdHocBox]){
            NSArray* additional = [self additionalEvasForStationId:self.mbId.stringValue];
            if(additional.count > 0){
                //add these evaIds to the result if they are not already present
                NSMutableArray* res = [NSMutableArray arrayWithCapacity:_eva_ids.count+additional.count];
                [res addObjectsFromArray:_eva_ids];
                for(NSString* eva in additional){
                    if(![res containsObject:eva]){
                        [res addObject:eva];
                    }
                }
                return res;
            }
        }*/
        return _eva_ids;
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
    return self.riPoiCategories.count > 0;
}

-(void)setRiPois:(NSArray *)riPois{
    _riPois = riPois;
    self.riPoiCategories = [RIMapPoi generatePXRGroups:_riPois];
}


#pragma mark Platform Data

-(void)addPlatformAccessibility:(NSArray<MBPlatformAccessibility *> *)platformList{
    if(!self.platformAccessibiltyData){
        self.platformAccessibiltyData = [NSMutableArray arrayWithCapacity:20];
    }
    [self.platformAccessibiltyData addObjectsFromArray:platformList];
}
-(NSArray<MBPlatformAccessibility *> *)platformAccessibility{
    return self.platformAccessibiltyData;
}
-(NSArray<MBPlatformAccessibility*>*)platformForTrackInfo{
    if(self.mergedPlatformData){
        return self.mergedPlatformData;
    }
    NSMutableArray<MBPlatformAccessibility*>* tracksToShow = [NSMutableArray arrayWithCapacity:self.platformAccessibility.count];
    BOOL filterOnParentPlatforms = true;
    if(filterOnParentPlatforms){
        //filter on main tracks (those that don't have a parent!)
        for(MBPlatformAccessibility* p in self.platformAccessibility){
            if(p.parentPlatform.length == 0){
                [tracksToShow addObject:p];
            }
        }
    }
    NSMutableDictionary<NSString*,MBPlatformAccessibility*>* platformDict = [NSMutableDictionary dictionaryWithCapacity:tracksToShow.count];
    NSMutableArray* keys = [NSMutableArray arrayWithCapacity:tracksToShow.count];
    for(MBPlatformAccessibility* p in tracksToShow){
        if(!platformDict[p.name] || platformDict[p.name].platformSetWithNameAndLinked.count < p.linkedPlatforms.count+1 ){
            p.platformSetWithNameAndLinked = [[NSSet setWithArray:p.linkedPlatforms] setByAddingObject:p.name];
            platformDict[p.name] = p;
            if(![keys containsObject:p.name]){
                [keys addObject:p.name];
            }
        }
    }
    
    //create groups with identical platformSetWithNameAndLinked
    //NSLog(@"create groups from %@",platformDict);
    NSMutableArray<NSMutableArray<MBPlatformAccessibility*>*>* groups = [NSMutableArray arrayWithCapacity:platformDict.count];
    for(NSString* key in keys){
        MBPlatformAccessibility* p = platformDict[key];
        //NSLog(@"outer loop: %@",p);
        NSMutableArray<MBPlatformAccessibility*>* found = nil;
        for(NSMutableArray<MBPlatformAccessibility*>* list in groups){
            for(MBPlatformAccessibility* p2 in list){
                if([p2.platformSetWithNameAndLinked isEqualToSet:p.platformSetWithNameAndLinked]){
                    found = list;
                    break;
                }
            }
            if(found){
                break;
            }
        }
        if(found){
            [found addObject:p];
        } else {
            NSMutableArray<MBPlatformAccessibility*>* newGroup = [NSMutableArray arrayWithCapacity:10];
            [newGroup addObject:p];
            [groups addObject:newGroup];
        }
        //NSLog(@"result: %@",groups);
    }
    //create a flat list, using only the first item from each group and adding all the other items in linkedMBPlatformAccessibility
    NSMutableArray<MBPlatformAccessibility*>* res = [NSMutableArray arrayWithCapacity:30];
    for(NSMutableArray<MBPlatformAccessibility*>* list in groups){
        [MBPlatformAccessibility sortArray:list];
        [res addObject:list.firstObject];
        NSMutableArray<MBPlatformAccessibility*>* linkedList = [NSMutableArray arrayWithCapacity:list.count];
        [linkedList addObjectsFromArray:[list subarrayWithRange:NSMakeRange(1, list.count-1)]];
        [MBPlatformAccessibility sortArray:linkedList];
        list.firstObject.linkedMBPlatformAccessibility = linkedList;
    }
    //update the linkedMBPlatformAccessibility param in the other tracks
    for(MBPlatformAccessibility* p in res){
        for(MBPlatformAccessibility* linked in p.linkedMBPlatformAccessibility){
            NSMutableArray<MBPlatformAccessibility*>* updatedLinkList = [NSMutableArray arrayWithCapacity:p.linkedMBPlatformAccessibility.count];
            [updatedLinkList addObjectsFromArray:p.linkedMBPlatformAccessibility];
            [updatedLinkList addObject:p];
            [updatedLinkList removeObject:linked];
            linked.linkedMBPlatformAccessibility = updatedLinkList;
        }
    }
    
    [MBPlatformAccessibility sortArray:res];
    self.mergedPlatformData = res;
    return res;
}
/*
-(void)cleanupLinkedPlatforms:(NSArray<MBPlatformAccessibility*>*)list{
    for(NSInteger i=0; i<list.count; i++){
        MBPlatformAccessibility* p = list[i];
        NSMutableArray* linkedCopy = p.linkedPlatforms.mutableCopy;
        for(int k=0; k<linkedCopy.count; k++){
            //every linked platform must also be a track that has THIS track as linked (link must be in both directions!)
            NSString* linkedTrack = linkedCopy[k];
            BOOL foundMatch = [self findTrack:linkedTrack withLinked:p.name inList:list];
            if(!foundMatch){
                NSLog(@"removing %@ from %@ because it is not linked in the other direction",linkedTrack,p.name);
                [linkedCopy removeObjectAtIndex:k];
                k--;
                //since we removed something we start all over again in the main loop
                i = -1;
            }
        }
        [linkedCopy sortUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
            NSInteger n1 = obj1.integerValue;
            NSInteger n2 = obj2.integerValue;
            if(n1 == n2){
                return [obj1 compare:obj2 options:NSCaseInsensitiveSearch];
            } else if(n1 < n2) {
                return NSOrderedAscending;
            } else {
                return NSOrderedDescending;
            }
        }];
        p.linkedPlatforms = linkedCopy;
    }
}
-(BOOL)findTrack:(NSString*)track withLinked:(NSString*)linked inList:(NSArray<MBPlatformAccessibility*>*)list{
    for(MBPlatformAccessibility* p in list){
        if([p.name isEqualToString:track]){
            for(NSString* link in p.linkedPlatforms){
                if([link isEqualToString:linked]){
                    return true;
                }
            }
            break;
        }
    }
    return false;
}


-(void)filterDuplicates:(NSMutableArray<MBPlatformAccessibility*>*)list{
    //a duplicate is an identical SET of trackname+linked tracks
    for(NSInteger i=0; i<list.count; i++){
        MBPlatformAccessibility* p = list[i];
        NSSet* set = [self setListForTracks:p];
        //check if there is another identical set
        for(NSInteger k=0; k<list.count; k++){
            MBPlatformAccessibility* p2 = list[k];
            if(p2 != p){
                NSSet* set2 = [self setListForTracks:p2];
                if([set isEqualToSet:set2]){
                    [list removeObjectAtIndex:k];
                    k--;
                }
            }
        }
    }
}
-(NSSet*)setListForTracks:(MBPlatformAccessibility*)p{
    NSMutableSet* set = [[NSMutableSet alloc] init];
    [set addObject:p.name];
    [set addObjectsFromArray:p.linkedPlatforms];
    return set;
}*/

-(MBPlatformAccessibility*)platformAccessibilityForPlatform:(NSString*)platform{
    for(MBPlatformAccessibility* p in self.platformAccessibiltyData){
        if([p.name isEqualToString:platform]){
            return p;
        }
    }
    return nil;
}
-(NSString*)linkedPlatformForPlatform:(NSString*)platform{
    if(!self.mergedPlatformData){
        //ensure that we have the merged track data
        [self platformForTrackInfo];
    }
    MBPlatformAccessibility* p = [self platformAccessibilityForPlatform:platform];
    if(p.linkedMBPlatformAccessibility.count == 1){
        return p.linkedMBPlatformAccessibility.firstObject.name;
    }
//    if(p.linkedPlatforms.count == 1){
//        return p.linkedPlatforms.firstObject;
//    }
    return nil;
}
-(NSArray<NSString*>*)linkedPlatformsForPlatform:(NSString*)platform{
    if(!self.mergedPlatformData){
        //ensure that we have the merged track data
        [self platformForTrackInfo];
    }
    MBPlatformAccessibility* p = [self platformAccessibilityForPlatform:platform];
//    return p.linkedPlatforms;
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:p.linkedMBPlatformAccessibility.count];
    for(MBPlatformAccessibility* link in p.linkedMBPlatformAccessibility){
        [res addObject:link.name];
    }
    return res;
}
-(BOOL)platformIsHeadPlatform:(NSString*)platform{
    MBPlatformAccessibility* p = [self platformAccessibilityForPlatform:platform];
    if(p){
        return p.headPlatform;
    }
    return false;
}

-(void)addLevelInformationToPlatformAccessibility{
    //collect the information for "Informationen zu den Gleisen vor Ort":
    NSArray* list = self.platformAccessibiltyData;
    for(MBPlatformAccessibility* p in list){
        NSString* levelTrack = [self levelForPlatform:p.name];
        p.level = levelTrack;
    }
    //The code below assumes that linked platforms (in both directions) are always on the same level:
    
    //some platform pois may be missing, but if another platform has this platform as linked AND it has a level, then we can use that level for this platform
    for(MBPlatformAccessibility* p in list){
        if(p.level == nil){
            for(MBPlatformAccessibility* p2 in list){
                if(p2 != p && p2.level != nil && [p2.linkedPlatforms containsObject:p.name]){
                    p.level = p2.level;
                    break;
                }
            }
        }
    }
    //finally, if the track itself is not used in a linked list, but it contains tracks in its linked lists that are known, then use that level
    for(MBPlatformAccessibility* p in list){
        if(p.level == nil){
            for(NSString* pLinked in p.linkedPlatforms){
                NSString* levelTrack = [self levelForPlatform:pLinked];
                if(levelTrack){
                    p.level = levelTrack;
                    break;
                }
            }
        }
    }
}


-(RIMapPoi *)poiForPlatform:(NSString *)platformNumber{
    for(RIMapPoi* poi in self.riPois){
        if([poi.title isEqualToString:platformNumber] && [poi.menusubcat isEqualToString:@"Bahngleise"]){
            return poi;
        }
    }
    return nil;
}

-(NSString*)levelForPlatform:(NSString*)platform{
    RIMapPoi* poi = [self poiForPlatform:platform];
    if(poi && poi.levelcode.length > 0){
        if(UIAccessibilityIsVoiceOverRunning()){
            return [RIMapPoi levelCodeToDisplayString:poi.levelcode];
        }
        return [RIMapPoi levelCodeToDisplayStringShort:poi.levelcode];
    }
    return nil;
}

+(BOOL)displayPlaformInfo{
    return false;
}



@end
