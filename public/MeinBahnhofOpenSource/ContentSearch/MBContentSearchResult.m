// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBContentSearchResult.h"
#import "MBMapViewController.h"
#import "UIImage+MBImage.h"

@interface MBContentSearchResult()

@property(nonatomic,strong) NSString* displayTitle;

@property(nonatomic,strong) NSString* keywordString;//something like "Bahnhofsinformation Info & Services Mobiler Service"

//used for linking into the detail page
@property(nonatomic) BOOL isChatBotSearch;
@property(nonatomic) BOOL isServiceNumberSearch;

@end

@implementation MBContentSearchResult

-(NSString *)iconName{
    if([self isTextSearch]){
        return @"app_lupe";
    }
    if(self.stop){
        return @"app_abfahrt_ankunft";
    }
    if(self.platformSearch){
        if([UIImage db_imageNamed:[@"rimap_gleis_" stringByAppendingString:self.platformSearch]]){
            return [@"rimap_gleis_" stringByAppendingString:self.platformSearch];
        }
        return @"rimap_gleis_1";
    }
    if(self.poi){
        return [self.poi iconNameForFlyout:YES];
    }
    if(self.poiCat){
        return [MBPXRShopCategory categoryNameForCatTitle:self.poiCat.title];
    }
    if(self.opnvLineIdentifier){
        switch(self.opnvCat){
            case HAFASProductCategoryS:
                return @"app_sbahn_klein";
            case HAFASProductCategoryBUS:
                return @"app_bus_klein";
            case HAFASProductCategoryTRAM:
                return @"app_tram_klein";
            case HAFASProductCategoryU:
                return @"app_ubahn_klein";
            case HAFASProductCategorySHIP:
                return @"app_faehre_klein";
            default:
                return @"app_haltestelle";
        }
    }
    
    if(self.keywordString.length > 0){
        NSDictionary* iconMap = @{
                                   CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_LOUNGE: @"bahnhofsausstattung_lounge",
                                   CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_LOCKER: @"bahnhofsausstattung_schließfaecher",
                                   CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_DBINFO: @"bahnhofsausstattung_db_info",
                                   CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_TRAVELCENTER: @"bahnhofsausstattung_db_reisezentrum",
                                   CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_WIFI: @"rimap_wlan_grau",
                                   CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_PARKING: @"bahnhofsausstattung_parkplatz",
                                   CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_TRAVELNECESSITIES: @"bahnhofsausstattung_reisebedarf",
                                   CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_WC: @"bahnhofsausstattung_wc",
                                   CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_BIKEPARK: @"bahnhofsausstattung_fahrradstellplatz",
                                   CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_TAXI: @"bahnhofsausstattung_taxi",
                                   CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE_CARRENTAL: @"bahnhofsausstattung_mietwagen",
                                   CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_MISSION: @"rimap_bahnhofsmission_grau",
                                   CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_TRAVELCENTER: @"bahnhofsausstattung_db_reisezentrum",
                                   CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_LOUNGE: @"app_db_lounge",
                                   CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_3S: @"app_3s",
                                   CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_LOSTANDFOUND: @"app_fundservice",
                                   CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_MOBILE_SERVICE:@"app_mobiler_service",
                                   CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_DBINFO:@"app_information",
                                   CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_MOBILITY_SERVICE: @"app_mobilitaetservice",
                                   CONTENT_SEARCH_KEY_STATIONINFO_WIFI: @"rimap_wlan_grau",
                                   CONTENT_SEARCH_KEY_STATIONINFO_ACCESSIBILITY: @"IconBarrierFree",
                                   CONTENT_SEARCH_KEY_STATIONINFO_ELEVATOR: @"app_aufzug",
                                   CONTENT_SEARCH_KEY_STATIONINFO_PARKING: @"rimap_parkplatz_grau",
                                   CONTENT_SEARCH_KEY_STATIONINFO_SEV: @"sev_bus",
                                   CONTENT_SEARCH_KEY_STATIONINFO_SEV_ACCOMPANIMENT: @"sev_bus",
                                   CONTENT_SEARCH_KEY_STATIONINFO_LOCKER: @"rimap_schliessfach_grau",
                                   CONTENT_SEARCH_KEY_MAP: @"app_karte_dunkelgrau",
                                   CONTENT_SEARCH_KEY_SETTINGS: @"app_einstellung",
                                   CONTENT_SEARCH_KEY_FEEDBACK: @"app_dialog",
                                   CONTENT_SEARCH_KEY_SHOP_AND_EAT: @"app_shop",
                                   CONTENT_SEARCH_KEY_SHOP_OPEN: @"app_shop",

                                   };

        if([iconMap objectForKey:self.keywordString]){
            return [iconMap objectForKey:self.keywordString];
        }
        
        if([self.keywordString hasPrefix:CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE]){
            return @"app_bahnhofinfo";
        }
        if([self.keywordString hasPrefix:CONTENT_SEARCH_KEY_STATIONINFO]){
            if([self isStationInfoPhoneSearch]){
                return @"app_service_rufnummern";
            }
            if([self isParkingSearch]){
                return @"bahnhofsausstattung_parkplatz";
            }
            if([self isSteplessAccessSearch]){
                return @"app_zugang_wege";
            }
            if([self isWifiSearch]){
                return @"rimap_wlan_grau";
            }
            if([self isElevatorSearch]){
                return @"app_aufzug";
            }
            return @"app_info";
        }
        if([self.keywordString hasPrefix:@"Abfahrt"] || [self.keywordString hasPrefix:@"Ankunft"] || [self.keywordString hasPrefix:CONTENT_SEARCH_KEY_TRAINORDER] || [self.keywordString hasPrefix:CONTENT_SEARCH_KEY_TRAVELPRODUCT] || [self isOPNVOverviewSearch]){
            return @"app_abfahrt_ankunft";
        }
    }
    return @"";
}

+(MBContentSearchResult *)searchResultForChatbot{
    MBContentSearchResult* res = [MBContentSearchResult new];
    res.searchText = @"Chatbot";
    res.displayTitle = @"Chatbot";
    res.keywordString = CONTENT_SEARCH_KEY_STATIONFINO_SERVICES_CHATBOT;
    res.isChatBotSearch = YES;
    return res;
}

+(MBContentSearchResult *)searchResultForServiceNumbers{
    MBContentSearchResult* res = [MBContentSearchResult new];
    res.searchText = @"Rufnummern";
    res.displayTitle = @"Rufnummern";
    res.keywordString = CONTENT_SEARCH_KEY_STATIONINFO_SERVICES;
    res.isServiceNumberSearch = YES;
    return res;
}
+(MBContentSearchResult*)searchResultWithSearchText:(NSString*)searchText{
    MBContentSearchResult* res = [MBContentSearchResult new];
    res.searchText = searchText;
    res.displayTitle = searchText;
    return res;
}

+(MBContentSearchResult *)searchResultWithStop:(Stop *)stop departure:(BOOL)departure{
    MBContentSearchResult* res = [MBContentSearchResult new];
    res.stop = stop;
    res.departure = departure;
    Event* event = [stop eventForDeparture:departure];
    NSString* line = [stop formattedTransportType:event.lineIdentifier];
    NSString* formatString = @"%@ %@ / %@ %@";
    if(UIAccessibilityIsVoiceOverRunning()){
        formatString = @"%@ %@ Uhr, %@ %@";
        //if([line hasPrefix:@"ICE"]){
        //    line = [@"I C E" stringByAppendingString:[line substringFromIndex:3]];
        //}
    }
    res.displayTitle = [NSString stringWithFormat:formatString,departure?@"Ab":@"An", event.formattedTime, line, event.actualStation];
    return res;
}

+(MBContentSearchResult *)searchResultWithKeywords:(NSString *)key{
    MBContentSearchResult* res = [MBContentSearchResult new];
    res.keywordString = key;
    //display only the last part of some keys
    
    NSString* infoServicesWithSpace = [CONTENT_SEARCH_KEY_STATIONINFO_SERVICES stringByAppendingString:@" "];
    NSString* infrastructureWithSpace = [CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE stringByAppendingString:@" "];
    NSString* infoWithSpace = [CONTENT_SEARCH_KEY_STATIONINFO stringByAppendingString:@" "];
    
    if([key hasPrefix:infrastructureWithSpace]){
        res.displayTitle = [key substringFromIndex:infrastructureWithSpace.length];
    } else if([key hasPrefix:infoServicesWithSpace]){
        res.displayTitle = [key substringFromIndex:infoServicesWithSpace.length];
    } else if([key hasPrefix:infoWithSpace]){
        res.displayTitle = [key substringFromIndex:infoWithSpace.length];
    } else {
        res.displayTitle = key;
    }
    
    if([key isEqualToString:CONTENT_SEARCH_KEY_DEPARTURES] || [res isWagenreihung]){
        res.departure = YES;
    } else if([key isEqualToString:CONTENT_SEARCH_KEY_ARRIVALS]){
        res.departure = NO;
    }
    
    return res;
}
+(MBContentSearchResult *)searchResultWithPOI:(RIMapPoi*)poi inCat:(nonnull MBPXRShopCategory *)cat{
    MBContentSearchResult* res = [MBContentSearchResult new];
    res.poi = poi;
    res.poiCat = cat;
    res.displayTitle = poi.title;
    if(!poi){
        res.displayTitle = cat.title;
    }
    return res;
}
+(MBContentSearchResult *)searchResultWithPlatform:(NSString *)platform{
    MBContentSearchResult* res = [MBContentSearchResult new];
    res.platformSearch = platform;
    res.departure = YES;
    res.displayTitle = [NSString stringWithFormat:@"Gleis %@",platform];
    return res;
}
+(MBContentSearchResult *)searchResultWithOPNV:(NSString *)lineIdentifier category:(HAFASProductCategory)category line:(NSString*)line{
    MBContentSearchResult* res = [MBContentSearchResult new];
    res.displayTitle = lineIdentifier;
    res.opnvLineIdentifier = lineIdentifier;
    res.opnvCat = category;
    res.opnvLine = line;
    res.departure = YES;
    return res;
}
+(MBContentSearchResult *)searchResultWithCoupon:(MBNews*)couponNews{
    MBContentSearchResult* res = [MBContentSearchResult new];
    res.displayTitle = couponNews.title;
    res.couponItem = couponNews;
    return res;
}

-(BOOL)isTextSearch{
    return self.searchText != nil;
}

-(BOOL)isTimetableSearch{
    return self.stop != nil || [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_DEPARTURES] || [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_ARRIVALS] || [self isWagenreihung] || [self isPlatformSearch] || [self isOPNVSearch];
}
-(BOOL)isPlatformSearch{
    return self.platformSearch != nil;
}
-(BOOL)isOPNVSearch{
    return self.opnvLineIdentifier != nil;
}

-(HAFASProductCategory)hafasProductForKeyword{
    if(self.keywordString){
        if([self.keywordString isEqualToString:CONTENT_SEARCH_KEY_TRAVELPRODUCT_U_TRAIN]){
            return HAFASProductCategoryU;
        } else if([self.keywordString isEqualToString:CONTENT_SEARCH_KEY_TRAVELPRODUCT_S_TRAIN]){
            return HAFASProductCategoryS;
        } else if([self.keywordString isEqualToString:CONTENT_SEARCH_KEY_TRAVELPRODUCT_TRAM]){
            return HAFASProductCategoryTRAM;
        } else if([self.keywordString isEqualToString:CONTENT_SEARCH_KEY_TRAVELPRODUCT_BUS]){
            return HAFASProductCategoryBUS;
        } else if([self.keywordString isEqualToString:CONTENT_SEARCH_KEY_TRAVELPRODUCT_FERRY]){
            return HAFASProductCategorySHIP;
        }
    }
    return HAFASProductCategoryNONE;
}

-(BOOL)isWagenreihung{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_TRAINORDER];
}
-(BOOL)isShopSearch{
    if(self.couponItem){
        return YES;
    }
    return self.poi != nil || self.poiCat != nil || [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_SHOP_AND_EAT];
}
-(BOOL)isMapSearch{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_MAP];
}
-(BOOL)isSettingSearch{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_SETTINGS];
}
-(BOOL)isFeedbackSearch{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_FEEDBACK];
}
-(BOOL)isOPNVOverviewSearch{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_OPNV];
}
-(BOOL)isStationFeatureSearch{
    return [self.keywordString hasPrefix:CONTENT_SEARCH_KEY_STATION_INFRASTRUCTURE];
}
-(BOOL)isStationInfoSearch{
    return [self.keywordString hasPrefix:CONTENT_SEARCH_KEY_STATIONINFO];
}
-(BOOL)isLocalServiceDBInfo{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_DBINFO];
}
-(BOOL)isLocalServiceMobileService{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_MOBILE_SERVICE];
}
-(BOOL)isLocalMission{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_MISSION];
}
-(BOOL)isLocalTravelCenter{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_TRAVELCENTER];
}
-(BOOL)isLocalLounge{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_LOUNGE];
}
-(BOOL)isStationInfoLocalServicesSearch{
    return [self isLocalServiceDBInfo]
    || [self isLocalServiceMobileService]
    || [self isLocalMission]
    || [self isLocalTravelCenter]
    || [self isLocalLounge];
}

-(BOOL)isStationInfoPhoneSearch{
    return [self isStationInfoPhoneMobility]
    || [self isStationInfoPhone3S]
    || [self isStationInfoPhoneLostservice]
    || self.isChatBotSearch
    || self.isServiceNumberSearch;
}
-(BOOL)isStationInfoPhoneMobility{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_MOBILITY_SERVICE];
}
-(BOOL)isStationInfoPhone3S{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_3S];
}
-(BOOL)isStationInfoPhoneLostservice{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_LOSTANDFOUND];
}
-(BOOL)isParkingSearch{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_STATIONINFO_PARKING];
}
-(BOOL)isSteplessAccessSearch{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_STATIONINFO_ACCESSIBILITY];
}
-(BOOL)isWifiSearch{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_STATIONINFO_WIFI];
}
-(BOOL)isSEVSearch{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_STATIONINFO_SEV];
}
-(BOOL)isSEVAccompanimentSearch{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_STATIONINFO_SEV_ACCOMPANIMENT];
}
-(BOOL)isLockerSearch{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_STATIONINFO_LOCKER];
}
-(BOOL)isNextAppSearch{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_STATIONINFO_NEXT];
}

-(BOOL)isElevatorSearch{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_STATIONINFO_ELEVATOR];
}
-(BOOL)isShopOpenSearch{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_SHOP_OPEN];
}

-(NSComparisonResult)compare:(MBContentSearchResult *)other{
    if(self.stop && other.stop){
        Event* event = [self.stop eventForDeparture:self.departure];
        Event* eventOther = [other.stop eventForDeparture:other.departure];
        if(event.timestamp < eventOther.timestamp){
            return NSOrderedAscending;
        } else if(event.timestamp > eventOther.timestamp){
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    } else {
        return [self.title compare:other.title];
    }
}

-(NSString *)title{
    return self.displayTitle;
}

@end
