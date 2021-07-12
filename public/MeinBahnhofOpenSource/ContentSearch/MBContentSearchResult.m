// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBContentSearchResult.h"

@interface MBContentSearchResult()

@property(nonatomic,strong) NSString* displayTitle;

@property(nonatomic,strong) NSString* keywordString;//something like "Bahnhofsinformation Info & Services Mobiler Service"

//used for linking into the detail page
@property(nonatomic) BOOL isChatBotSearch;
@property(nonatomic) BOOL isPickpackSearch;
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
        return [MBEinkaufsbahnhofCategory categoryNameForCatTitle:self.poiCat.title];
    }
    if(self.store || self.storeCat){
        return self.storeCat.iconFilename;
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
        NSDictionary* iconMap = @{ @"Bahnhofsausstattung Stufenfreier Zugang" : @"bahnhofsausstattung_stufenfreier_zugang",
                                   @"Bahnhofsausstattung WC": @"bahnhofsausstattung_wc",
                                   @"Bahnhofsausstattung DB Lounge": @"bahnhofsausstattung_lounge",
                                   @"Bahnhofsausstattung Schließfächer": @"bahnhofsausstattung_schließfaecher",
                                   @"Bahnhofsausstattung DB Info": @"bahnhofsausstattung_db_info",
                                   @"Bahnhofsausstattung DB Reisezentrum": @"bahnhofsausstattung_db_reisezentrum",
                                   @"Bahnhofsausstattung Reisebedarf": @"bahnhofsausstattung_reisebedarf",
                                   @"Bahnhofsausstattung Parkplätze": @"bahnhofsausstattung_parkplatz",
                                   @"Bahnhofsausstattung Fahrradstellplatz": @"bahnhofsausstattung_fahrradstellplatz",
                                   @"Bahnhofsausstattung Taxistand": @"bahnhofsausstattung_taxi",
                                   @"Bahnhofsausstattung Mietwagen": @"bahnhofsausstattung_mietwagen",
                                   @"Bahnhofsausstattung WLAN": @"rimap_wlan_grau",
                                   @"Karte": @"app_karte_dunkelgrau",
                                   @"Einstellungen": @"app_einstellung",
                                   @"Feedback": @"app_dialog",
                                   @"Shoppen & Schlemmen":@"app_shop",
                                   @"Geöffnet":@"app_shop",
                                   CONTENT_SEARCH_KEY_STATIONINFO_INFOSERVICE_DBINFO:@"app_information",
                                   @"Bahnhofsinformation Info & Services Mobiler Service":@"app_mobiler_service",
                                   @"Bahnhofsinformation Info & Services Bahnhofsmission": @"rimap_bahnhofsmission_grau",
                                   @"Bahnhofsinformation Info & Services DB Reisezentrum": @"bahnhofsausstattung_db_reisezentrum",
                                   @"Bahnhofsinformation Info & Services DB Lounge": @"app_db_lounge",
                                   @"Bahnhofsinformation Info & Services Mobilitätsservice": @"app_mobilitaetservice",
                                   @"Bahnhofsinformation Info & Services 3-S-Zentrale": @"app_3s",
                                   @"Bahnhofsinformation Info & Services Fundservice": @"app_fundservice",
                                   @"Bahnhofsinformation WLAN": @"rimap_wlan_grau",
                                   @"Bahnhofsinformation Zugang & Wege": @"IconBarrierFree",
                                   @"Bahnhofsinformation Barrierefreiheit": @"IconBarrierFree",
                                   @"Bahnhofsinformation Aufzüge": @"app_aufzug",
                                   @"Bahnhofsinformation Parkplätze": @"rimap_parkplatz_grau",
                                   };

        if([iconMap objectForKey:self.keywordString]){
            return [iconMap objectForKey:self.keywordString];
        }
        
        if([self.keywordString hasPrefix:@"Bahnhofsausstattung"]){
            return @"app_bahnhofinfo";
        }
        if([self.keywordString hasPrefix:@"Bahnhofsinformation"]){
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
        if([self.keywordString hasPrefix:@"Abfahrt"] || [self.keywordString hasPrefix:@"Ankunft"] || [self.keywordString hasPrefix:@"Wagenreihung"] || [self.keywordString hasPrefix:@"Verkehrsmittel"] || [self.keywordString hasPrefix:@"ÖPNV Anschluss"]){
            return @"app_abfahrt_ankunft";
        }
    }
    return @"";
}

+(MBContentSearchResult *)searchResultForChatbot{
    MBContentSearchResult* res = [MBContentSearchResult new];
    res.searchText = @"Chatbot";
    res.displayTitle = @"Chatbot";
    res.keywordString = @"Bahnhofsinformation Info & Services Chatbot";
    res.isChatBotSearch = YES;
    return res;
}
+(MBContentSearchResult *)searchResultForPickpack{
    MBContentSearchResult* res = [MBContentSearchResult new];
    res.searchText = @"pickpack";
    res.displayTitle = @"pickpack";
    res.keywordString = @"Shoppen & Schlemmen";
    res.isPickpackSearch = YES;
    return res;
}
+(MBContentSearchResult *)searchResultForServiceNumbers{
    MBContentSearchResult* res = [MBContentSearchResult new];
    res.searchText = @"Rufnummern";
    res.displayTitle = @"Rufnummern";
    res.keywordString = @"Bahnhofsinformation Info & Services";
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
    if([key hasPrefix:@"Bahnhofsausstattung "]){
        res.displayTitle = [key substringFromIndex:@"Bahnhofsausstattung ".length];
    } else if([key hasPrefix:@"Bahnhofsinformation Info & Services "]){
        res.displayTitle = [key substringFromIndex:@"Bahnhofsinformation Info & Services ".length];
    } else if([key hasPrefix:@"Bahnhofsinformation "]){
        res.displayTitle = [key substringFromIndex:@"Bahnhofsinformation ".length];
    } else {
        res.displayTitle = key;
    }
    
    if([key isEqualToString:@"Abfahrtstafel"] || [key isEqualToString:@"Wagenreihung"]){
        res.departure = YES;
    } else if([key isEqualToString:@"Ankunftstafel"]){
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
+(MBContentSearchResult *)searchResultWithStore:(MBEinkaufsbahnhofStore *)store inCat:(nonnull MBEinkaufsbahnhofCategory *)cat{
    MBContentSearchResult* res = [MBContentSearchResult new];
    res.store = store;
    res.storeCat = cat;
    res.displayTitle = store.name;
    if(!store){
        res.displayTitle = cat.name;
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
    return self.stop != nil || [self.keywordString isEqualToString:@"Abfahrtstafel"] || [self.keywordString isEqualToString:@"Ankunftstafel"] || [self isWagenreihung] || [self isPlatformSearch] || [self isOPNVSearch];
}
-(BOOL)isPlatformSearch{
    return self.platformSearch != nil;
}
-(BOOL)isOPNVSearch{
    return self.opnvLineIdentifier != nil;
}

-(HAFASProductCategory)hafasProductForKeyword{
    if(self.keywordString){
        if([self.keywordString isEqualToString:@"Verkehrsmittel Ubahn"]){
            return HAFASProductCategoryU;
        } else if([self.keywordString isEqualToString:@"Verkehrsmittel S-Bahn"]){
            return HAFASProductCategoryS;
        } else if([self.keywordString isEqualToString:@"Verkehrsmittel Tram"]){
            return HAFASProductCategoryTRAM;
        } else if([self.keywordString isEqualToString:@"Verkehrsmittel Bus"]){
            return HAFASProductCategoryBUS;
        } else if([self.keywordString isEqualToString:@"Verkehrsmittel Fähre"]){
            return HAFASProductCategorySHIP;
        }
    }
    return HAFASProductCategoryNONE;
}

-(BOOL)isWagenreihung{
    return [self.keywordString isEqualToString:@"Wagenreihung"];
}
-(BOOL)isShopSearch{
    if(self.isPickpackSearch){
        return YES;
    }
    if(self.couponItem){
        return YES;
    }
    return self.poi != nil || self.store != nil || self.poiCat != nil || self.storeCat != nil || [self.keywordString isEqualToString:@"Shoppen & Schlemmen"];
}
-(BOOL)isMapSearch{
    return [self.keywordString isEqualToString:@"Karte"];
}
-(BOOL)isSettingSearch{
    return [self.keywordString isEqualToString:@"Einstellungen"];
}
-(BOOL)isFeedbackSearch{
    return [self.keywordString isEqualToString:@"Feedback"];
}
-(BOOL)isOPNVOverviewSearch{
    return [self.keywordString isEqualToString:@"ÖPNV Anschluss"];
}
-(BOOL)isStationFeatureSearch{
    return [self.keywordString hasPrefix:@"Bahnhofsausstattung"];
}
-(BOOL)isStationInfoSearch{
    return [self.keywordString hasPrefix:@"Bahnhofsinformation"];
}
-(BOOL)isLocalServiceDBInfo{
    return [self.keywordString isEqualToString:CONTENT_SEARCH_KEY_STATIONINFO_INFOSERVICE_DBINFO];
}
-(BOOL)isLocalServiceMobileService{
    return [self.keywordString isEqualToString:@"Bahnhofsinformation Info & Services Mobiler Service"];
}
-(BOOL)isLocalMission{
    return [self.keywordString isEqualToString:@"Bahnhofsinformation Info & Services Bahnhofsmission"];
}
-(BOOL)isLocalTravelCenter{
    return [self.keywordString isEqualToString:@"Bahnhofsinformation Info & Services DB Reisezentrum"];
}
-(BOOL)isLocalLounge{
    return [self.keywordString isEqualToString:@"Bahnhofsinformation Info & Services DB Lounge"];
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
    return [self.keywordString isEqualToString:@"Bahnhofsinformation Info & Services Mobilitätsservice"];
}
-(BOOL)isStationInfoPhone3S{
    return [self.keywordString isEqualToString:@"Bahnhofsinformation Info & Services 3-S-Zentrale"];
}
-(BOOL)isStationInfoPhoneLostservice{
    return [self.keywordString isEqualToString:@"Bahnhofsinformation Info & Services Fundservice"];
}
-(BOOL)isParkingSearch{
    return [self.keywordString isEqualToString:@"Bahnhofsinformation Parkplätze"];
}
-(BOOL)isSteplessAccessSearch{
    return [self.keywordString isEqualToString:@"Bahnhofsinformation Barrierefreiheit"];
}
-(BOOL)isWifiSearch{
    return [self.keywordString isEqualToString:@"Bahnhofsinformation WLAN"];
}
-(BOOL)isElevatorSearch{
    return [self.keywordString isEqualToString:@"Bahnhofsinformation Aufzüge"];
}
-(BOOL)isShopOpenSearch{
    return [self.keywordString isEqualToString:@"Geöffnet"];
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
