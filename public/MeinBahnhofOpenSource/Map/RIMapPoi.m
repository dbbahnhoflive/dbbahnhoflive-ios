// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "RIMapPoi.h"
#import "POIFilterItem.h"
#import "RIMapConfigItem.h"
#import "MBMarker.h"
#import "RIMapFilterCategory.h"
#import "MBMapViewController.h"

#import "MBPXRShopCategory.h"
#import "MBUIHelper.h"

@interface RIMapPoi()

@property(nonatomic,strong) RIMapConfigItem* configForThisPoi;

@end

@implementation RIMapPoi

static NSArray* weekdays = nil;

static NSArray* iconAndZoomConfig = nil;
static NSArray* filterConfig = nil;
static NSDictionary* levelCodeToNumber = nil;

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"idNum": @"id",
             @"src_layer": @"src_layer",
             @"levelcode": @"levelcode",
             @"type": @"type",
             @"category": @"category",
             @"name": @"name",
             @"displname":@"displname",
             @"displmap":@"displmap",
             @"detail":@"detail",
             @"menucat": @"menucat",
             @"menusubcat": @"menusubcat",
             @"display_x" : @"display_x",
             @"display_y" : @"display_y",
             @"day_1": @"day_1",
             @"day_2": @"day_2",
             @"day_3": @"day_3",
             @"day_4": @"day_4",
             @"time_1": @"time_1",
             @"time_2": @"time_2",
             @"time_3": @"time_3",
             @"time_4": @"time_4",
             @"bbox": @"bbox",
             @"phone": @"phone",
             @"email": @"email",
             @"website": @"website",
             @"tags": @"tags",
             };
}

//currently not used!
+(NSArray*)filterMarker:(NSArray*)marker forLevel:(NSString*)levelString andZoomLevel:(NSInteger)zoom{
    levelString = [levelString lowercaseString];
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:marker.count];
    for(RIMapPoi* poi in marker){
        if([[poi lowCaseLevelCode] isEqualToString:levelString] && zoom >= [poi mapZoomLevel]){
            [res addObject:poi];
        }
    }
    return res;
}

+(NSNumber*)levelcodeToNumber:(NSString*)levelcode{
    if([levelcode isEqualToString:@"L0"])
        return @0;
    if(!levelCodeToNumber){
        levelCodeToNumber = @{ @"B4":@-4, @"B3":@-3, @"B2":@-2, @"B1":@-1, @"L0":@0, @"L1":@1, @"L2":@2, @"L3":@3, @"L4":@4 };
    }
    NSNumber* res= ((NSNumber*)levelCodeToNumber[levelcode]);
    if(!res){
        return @0;
    }
    return res;
}

-(void)getFilterTitle:(NSString**)filterTitle andSubTitle:(NSString**)filterSubTitle{
    RIMapConfigItem* config = [self configForThisPoi];
    [RIMapPoi getFilterTitle:filterTitle subtitle:filterSubTitle forPOI:self forItem:config];
}

-(MBMarker*)mapMarker{
    MBMarker *marker = [MBMarker markerWithPosition:[self center] andType:RIMAPPOI];
    marker.userData = @{@"venue": self, @"level":[RIMapPoi levelcodeToNumber:self.levelcode]/*, @"isSelectable": [NSNumber numberWithBool:isSelectable]*/};
    if(UIAccessibilityIsVoiceOverRunning()){
        marker.title = self.name;
    }
    NSString* filterTitle = nil;
    NSString* filterSubTitle = nil;
    RIMapConfigItem* config = [self configForThisPoi];
    [RIMapPoi getFilterTitle:&filterTitle subtitle:&filterSubTitle forPOI:self forItem:config];
    //marker.title = self.displname;
    marker.category = filterTitle;
    marker.secondaryCategory = filterSubTitle;
    UIImage* markerIcon = [self iconImageForFlyout:NO];
    marker.icon = markerIcon;
    if(markerIcon && config.showLabelAtZoom){
        //NSLog(@"create icon with text for %@",self.displname);
        //create an icon that contains the title table
        NSString* titleText = self.detail ? self.detail : self.title;
        NSInteger zoomForIconWithText = config.showLabelAtZoom.integerValue;
        
        [MBMarker renderTextIntoIconFor:marker markerIcon:markerIcon titleText:titleText zoomForIconWithText:zoomForIconWithText];
    }
    
    marker.zIndex = 750;
    marker.riMapPoi = self;
    marker.zoomLevel = config.zoom.integerValue;
    return marker;
}

-(BOOL)hasOpeningInfo{
    return (self.openingTimes.count > 0)
    || (self.day_1.length > 0 && self.time_1.length > 0); //old api
}
-(BOOL)isTrack{
    return
       [self.type isEqualToString:@"PLATFROM"] //naming in new api (with typo!)
    || [self.type isEqualToString:@"PLATFORM"] //naming in new api (without typo)
    || [self.type isEqualToString:@"Track"]; //naming in old api
}

-(NSString *)allOpenTimes{
    NSMutableString* res = [[NSMutableString alloc] init];
    
    if(self.openingTimes.count > 0){
        for(RIMapPoiOpenTime* ot in self.openingTimes){
            if(res.length > 0){
                [res appendString:@"\n"];
            }
            [res appendString:ot.daysDisplayString];
            [res appendString:@": "];
            [res appendString:ot.openTimesString];
        }
        return res;
    }
    
    //old api:
    if(self.day_1.length > 0){
        if(self.time_1.length > 0){
            [res appendString:self.day_1];
            [res appendString:@": "];
            [res appendString:self.time_1];
        }
    }
    if(self.day_2.length > 0){
        if(self.time_2.length > 0){
            if(res.length > 0){
                [res appendString:@"\n"];
            }
            [res appendString:self.day_2];
            [res appendString:@": "];
            [res appendString:self.time_2];
        }
    }
    if(self.day_3.length > 0){
        if(self.time_3.length > 0){
            if(res.length > 0){
                [res appendString:@"\n"];
            }
            [res appendString:self.day_3];
            [res appendString:@": "];
            [res appendString:self.time_3];
        }
    }
    if(self.day_4.length > 0){
        if(self.time_4.length > 0){
            if(res.length > 0){
                [res appendString:@"\n"];
            }
            [res appendString:self.day_4];
            [res appendString:@": "];
            [res appendString:self.time_4];
        }
    }
    return res;
}

-(BOOL)isOpen{
    return [self isOpenTime] >= 0;
}
-(NSTimeInterval)isOpenTime{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    [gregorian setLocale:[NSLocale localeWithLocaleIdentifier:@"de_DE"]];
    [gregorian setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Berlin"]];
    
    NSDateComponents *comps = [gregorian components:NSCalendarUnitWeekday|NSCalendarUnitHour|NSCalendarUnitMinute fromDate:[NSDate date]];
    NSInteger weekday = [comps weekday]-2;
    if(weekday < 0){
        weekday = 6;
    }
    NSString* currentWeekday = nil;
    if(!weekdays){
        weekdays = @[@"Montag",@"Dienstag",@"Mittwoch",@"Donnerstag",@"Freitag",@"Samstag",@"Sonntag"];
    }
    currentWeekday = weekdays[weekday];
    NSInteger currentHour = [comps hour];
    NSInteger currentMinutesFrom = [comps minute];

    //NSLog(@"compare %@,%ld:%ld with %@",currentWeekday,(long)currentHour,(long)currentMinutesFrom, self);
    
    if(self.openingTimes.count > 0){
        //find the day:
        for(RIMapPoiOpenTime* ot in self.openingTimes){
            if([ot.days containsObject:currentWeekday]){
                //find the time
                for(NSString* openTime in ot.openTimes){
                    NSTimeInterval time = [self isHour:currentHour minute:currentMinutesFrom inRange:openTime];
                    if(time >= 0){
                        return time;
                    }
                }
            }
        }
    }

    //old api
    
    //try to find the day
    if([self isDay:currentWeekday inRange:self.day_1]){
        NSTimeInterval time = [self isHour:currentHour minute:currentMinutesFrom inRange:self.time_1];
        if(time >= 0){
            return time;
        }
    }
    if([self isDay:currentWeekday inRange:self.day_2]){
        NSTimeInterval time = [self isHour:currentHour minute:currentMinutesFrom inRange:self.time_2];
        if(time >= 0){
            return time;
        }
    }
    if([self isDay:currentWeekday inRange:self.day_3]){
        NSTimeInterval time = [self isHour:currentHour minute:currentMinutesFrom inRange:self.time_3];
        if(time >= 0){
            return time;
        }
    }
    if([self isDay:currentWeekday inRange:self.day_4]){
        NSTimeInterval time = [self isHour:currentHour minute:currentMinutesFrom inRange:self.time_4];
        if(time >= 0){
            return time;
        }
    }
    return -1;
}

-(BOOL)isDay:(NSString*)weekday inRange:(NSString*)rangeString{
    if([rangeString isEqualToString:weekday]){
        return YES;
    }
    NSArray* days = [rangeString componentsSeparatedByString:@"-"];
    if(days.count == 2){
        NSString* day1 = days.firstObject;
        NSString* day2 = days.lastObject;
        NSInteger indexDay = [weekdays indexOfObject:weekday];
        NSInteger day1Index = [weekdays indexOfObject:day1];
        NSInteger day2Index = [weekdays indexOfObject:day2];
        return indexDay >= day1Index && indexDay <= day2Index;
    }
    return NO;
}
-(NSTimeInterval)isHour:(NSInteger)hour minute:(NSInteger)minute inRange:(NSString*)timeRange{
    NSArray* times = [timeRange componentsSeparatedByString:@"-"];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    // hours format kk for 1..24
    [dateFormat setDateFormat:@"kk:mm"];
    NSString* timeOne = times.firstObject;
    NSString* timeTwo = times.lastObject;
    if(timeOne.length > 5){
        timeOne = [timeOne substringToIndex:5];
    }
    if(timeTwo.length > 5){
        timeTwo = [timeTwo substringToIndex:5];
    }

    NSDate *dateOne=[dateFormat dateFromString:timeOne ];
    NSDate *dateTwo=[dateFormat dateFromString:timeTwo ];
    if(dateOne.timeIntervalSinceReferenceDate == dateTwo.timeIntervalSinceReferenceDate){
        return 24*60*60;
    }
    BOOL invert = NO;
    if([dateOne timeIntervalSinceReferenceDate] > [dateTwo timeIntervalSinceReferenceDate]){
        invert = YES;
        NSDate* tmp = dateOne;
        dateOne = dateTwo;
        dateTwo = tmp;
    }
    NSDate *date = [dateFormat dateFromString:[NSString stringWithFormat:@"%2ld:%2ld",(long)hour,(long)minute]];
    
    NSTimeInterval now =[date timeIntervalSinceReferenceDate];
    if(now >= [dateOne timeIntervalSinceReferenceDate] && now <= [dateTwo timeIntervalSinceReferenceDate]){
        if(invert){
            return -1;
        } else {
            return [dateTwo timeIntervalSinceReferenceDate]-now;
        }
    } else {
        if(invert){
            if(now > [dateOne timeIntervalSinceReferenceDate]){
                return [dateOne timeIntervalSinceReferenceDate]+24*60*60-now;
            }
            return [dateOne timeIntervalSinceReferenceDate]-now;
        } else {
            return -1;
        }
    }
}

/*-(NSString *)description{
    return [[super description] stringByAppendingFormat:@"<-isOpen=%d",[self isOpen] ];
}*/

-(NSString*)lowCaseLevelCode{
    return [self.levelcode lowercaseString];
}

-(NSString *)title{
    if(self.displname){
        return self.displname;
    }
    return @"";
}


-(CLLocationCoordinate2D)center{
    CLLocationCoordinate2D coord = kCLLocationCoordinate2DInvalid;
    if(self.display_x.integerValue != 0 && self.display_y.integerValue != 0){
        coord = CLLocationCoordinate2DMake(self.display_y.doubleValue, self.display_x.doubleValue);
    }
    if(CLLocationCoordinate2DIsValid(coord)){
        return coord;
    }
    if(_bbox.count == 4){
        // fallback to bbox center?
        
        double minlat = fmin(((NSNumber*)_bbox[3]).doubleValue, ((NSNumber*)_bbox[1]).doubleValue);
        double minlng = fmin(((NSNumber*)_bbox[2]).doubleValue, ((NSNumber*)_bbox[0]).doubleValue);
        double maxlat = fmax(((NSNumber*)_bbox[3]).doubleValue, ((NSNumber*)_bbox[1]).doubleValue);
        double maxlng = fmax(((NSNumber*)_bbox[2]).doubleValue, ((NSNumber*)_bbox[0]).doubleValue);
        
        CLLocationDegrees lat = minlat+(maxlat-minlat)/2.0;
        CLLocationDegrees lng = minlng+(maxlng-minlng)/2.0;
        
        coord = CLLocationCoordinate2DMake(lat, lng);
    }
    if(CLLocationCoordinate2DIsValid(coord)){
        return coord;
    }
    return kCLLocationCoordinate2DInvalid;
}

-(NSInteger)mapZoomLevel{
    RIMapConfigItem* dict = [self configForThisPoi];
    NSNumber* num = dict.zoom;
    return num.integerValue;
}

-(BOOL)isValid{
    BOOL res = [self isKnownPOI] && self.displname.length > 0 && (CLLocationCoordinate2DIsValid([self center]));
    /*
    if(!res && [self isKnownPOI]){
        NSLog(@"ignoring a known POI, name or center missing: %@",self);
    }
    */
    return res;
}

-(BOOL)isKnownPOI{
    return [self configForThisPoi] != nil;
}
-(BOOL)isDBInfoPOI{
    return [self.menusubcat isEqualToString:@"DB Information"];
}

+(void)getFilterTitle:(NSString**)titleOut subtitle:(NSString**)subtitleOut forPOI:(RIMapPoi*)poi forItem:(RIMapConfigItem*)item{
    
    NSArray* filterItems = [RIMapPoi filterConfig];
    for(RIMapFilterCategory* filterDict in filterItems){
        NSString* filterTitle = filterDict.appcat;
        NSArray* filterItemDicts = filterDict.items;
        for(RIMapFilterEntry* filterItemDict in filterItemDicts){
            NSString* title = filterItemDict.title;
            NSString* menucat = filterItemDict.menucat;
            NSString* menusubcat = filterItemDict.menusubcat;
            RIMapConfigItem* config = [RIMapPoi configForMenuCat:menucat subCat:menusubcat];
            if(config){
                if(config == item){
                    *titleOut = filterTitle;
                    *subtitleOut = title;
                    return;
                }
            }
        }
    }
}
+(NSArray*)createFilterItems{
    //return NSArray with POIFilterItem
    NSArray* filterItems = [RIMapPoi filterConfig];
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:filterItems.count];
    for(RIMapFilterCategory* filterDict in filterItems){
        NSString* filterTitle = filterDict.appcat;
        POIFilterItem* filterItem = [[POIFilterItem alloc] initWithTitle:filterTitle andIconKey:nil];
        NSArray* filterItemDicts = filterDict.items;
        NSMutableArray* subitems = [NSMutableArray arrayWithCapacity:10];
        for(RIMapFilterEntry* filterItemDict in filterItemDicts){
            NSString* title = filterItemDict.title;
            NSString* menucat = filterItemDict.menucat;
            NSString* menusubcat = filterItemDict.menusubcat;
            RIMapConfigItem* config = [RIMapPoi configForMenuCat:menucat subCat:menusubcat];
            if(config){
                NSString* filename = [self filenameForIcon:config.icon small:YES];
                
                POIFilterItem* filterSubItem = [[POIFilterItem alloc] initWithTitle:title andIconKey:filename];
                [subitems addObject:filterSubItem];
            } else {
                // NSLog(@"WARN: no config found for filter config! Filter: %@",filterDict);
            }
        }
        filterItem.subItems = subitems;
        [res addObject:filterItem];
    }
    return res;
}

+(NSString*)filenameForIcon:(NSString*)icon small:(BOOL)small{
    NSString* filename = [icon lowercaseString];
    filename = [@"rimap_" stringByAppendingString:filename];
    if(!small){
        filename = [filename stringByAppendingString:@"_grau"];
    }
    return filename;
}

-(RIMapConfigItem*)configForThisPoi{
    if(!_configForThisPoi){
        if(self.menusubcat){
            RIMapConfigItem* dict = [RIMapPoi configForMenuCat:self.menucat subCat:self.menusubcat];
            self.configForThisPoi = dict;
        }
    }
    return _configForThisPoi;
}

-(UIImage*)iconImageForFlyout:(BOOL)forFlyout{
    NSString* filename = [self iconNameForFlyout:forFlyout];
    UIImage* img = [UIImage db_imageNamed:filename];
    if(img == nil){
        //NSLog(@"missing image for menusubcat %@, file %@ and %@",_menusubcat,filename,dict);
        return nil;
    } else {
        //NSLog(@"image for %@ found: %@",self,filename);
        return img;
    }
}
-(NSString*)iconNameForFlyout:(BOOL)forFlyout{
    RIMapConfigItem* dict = [self configForThisPoi];
    if(dict){
        NSString* filename = dict.icon;
        if([self.menusubcat isEqualToString:@"Bahngleise"]){
            //append the number
            filename = [filename stringByAppendingString:self.name];
        } else if([self.menusubcat isEqualToString:@"Abschnittswürfel"]){
            //append the section
            filename = [filename stringByAppendingString:self.name];
        }
        filename = [RIMapPoi filenameForIcon:filename small:!forFlyout];
        return filename;
    }
    return nil;
}

+(RIMapConfigItem*)configForMenuCat:(NSString*)cat subCat:(NSString*)subcat{
    for(RIMapConfigItem* dict in [RIMapPoi iconAndZoomConfig]){
        if([dict.menucat isEqualToString:cat] && [dict.menusubcat isEqualToString:subcat]){
            return dict;
        }
    }
    return nil;
}

+(NSArray*)iconAndZoomConfig{
    if(iconAndZoomConfig == nil){
        NSArray* array = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"mapconfig.json" ofType:nil]] options:0 error:nil];
        iconAndZoomConfig = [MTLJSONAdapter modelsOfClass:RIMapConfigItem.class
                                       fromJSONArray:array
                                               error:nil];

    }
    return iconAndZoomConfig;
}
+(NSArray*)filterConfig{
    if(filterConfig == nil){
        NSArray* array = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"filterconfig.json" ofType:nil]] options:0 error:nil];
        filterConfig = [MTLJSONAdapter modelsOfClass:RIMapFilterCategory.class
                                        fromJSONArray:array
                                                error:nil];

    }
    return filterConfig;
}

+(NSString*)levelCodeToDisplayString:(NSString*)levelCode{
    if([levelCode compare:@"b4" options:NSCaseInsensitiveSearch] == NSOrderedSame){
        return @"4. Untergeschoss";
    }
    if([levelCode compare:@"b3" options:NSCaseInsensitiveSearch] == NSOrderedSame){
        return @"3. Untergeschoss";
    }
    if([levelCode compare:@"b2" options:NSCaseInsensitiveSearch] == NSOrderedSame){
        return @"2. Untergeschoss";
    }
    if([levelCode compare:@"b1" options:NSCaseInsensitiveSearch] == NSOrderedSame){
        return @"1. Untergeschoss";
    }
    if([levelCode compare:@"l0" options:NSCaseInsensitiveSearch] == NSOrderedSame){
        return @"Erdgeschoss";
    }
    if([levelCode compare:@"l1" options:NSCaseInsensitiveSearch] == NSOrderedSame){
        return @"1. Obergeschoss";
    }
    if([levelCode compare:@"l2" options:NSCaseInsensitiveSearch] == NSOrderedSame){
        return @"2. Obergeschoss";
    }
    if([levelCode compare:@"l3" options:NSCaseInsensitiveSearch] == NSOrderedSame){
        return @"3. Obergeschoss";
    }
    if([levelCode compare:@"l4" options:NSCaseInsensitiveSearch] == NSOrderedSame){
        return @"4. Obergeschoss";
    }
    return @"";
}


#define FAV_CAT_LEBENSMITTEL @"Lebensmittel"
#define FAV_CAT_GASTRO @"Gastronomie"
#define FAV_CAT_BAECKER @"Bäckereien"
#define FAV_CAT_SHOP @"Shops"
#define FAV_CAT_GESUNDHEIT @"Gesundheit & Pflege"
#define FAV_CAT_DIENSTLEISTUNG @"Dienstleistungen"
#define FAV_CAT_PRESSE @"Presse & Buch"
+(NSArray*)mapShopCategoryToFilterPresets:(NSString*)shopCategory{
    return @[ PRESET_SHOPPING ];
    /* //disabled category filtering due to many shops that show up in different categories
    if([shopCategory isEqualToString:FAV_CAT_LEBENSMITTEL]){
        return @[ PRESET_SHOPCAT_GROCERIES ];
    } else if([shopCategory isEqualToString:FAV_CAT_GASTRO]){
        return @[ PRESET_SHOPCAT_GASTRO ];
    } else if([shopCategory isEqualToString:FAV_CAT_BAECKER]){
        return @[ PRESET_SHOPCAT_BACKERY ];
    } else if([shopCategory isEqualToString:FAV_CAT_SHOP]){
        return @[ PRESET_SHOPCAT_SHOP ];
    } else if([shopCategory isEqualToString:FAV_CAT_GESUNDHEIT]){
        return @[ PRESET_SHOPCAT_HEALTH ];
    } else if([shopCategory isEqualToString:FAV_CAT_DIENSTLEISTUNG]){
        return @[ PRESET_SHOPCAT_SERVICES ];
    } else if([shopCategory isEqualToString:FAV_CAT_PRESSE]){
        return @[ PRESET_SHOPCAT_PRESS ];
    }
    return nil;*/
}

/*
- (BOOL) isShoppingPOI
{
    NSArray *shoppingCategories = @[@"Restaurants",
                                    @"Press",
                                    @"Food",
                                    @"Fashion and Accessories",
                                    @"Services",
                                    @"Health",
                                    @"Deutsche Bahn Services"];
    return [shoppingCategories containsObject:self.type];
}*/

+(NSString*)mapPXRToShopCategory:(RIMapPoi*)poi{
    //map the categories and subcategories used by PXR (see mapconfig.json) to the favendo categories
    
    NSDictionary* mapping = nil;
    if([poi.menucat isEqualToString:@"Gastronomie & Lebensmittel"]){
        mapping = @{
                    @"Lebensmittel": FAV_CAT_LEBENSMITTEL,
                    @"Restaurant": FAV_CAT_GASTRO,
                    @"Café": FAV_CAT_GASTRO,
                    @"Fast Food": FAV_CAT_GASTRO,
                    @"Bäckerei": FAV_CAT_BAECKER,
                    @"Supermarkt": FAV_CAT_LEBENSMITTEL,
                    @"Gaststätte": FAV_CAT_GASTRO,
                    };
        NSString* cat = mapping[poi.menusubcat];
        if(cat){
            return cat;
        } else {
            return FAV_CAT_LEBENSMITTEL;
        }
    } else if([poi.menucat isEqualToString:@"Einkaufen"]){
        mapping = @{
                    @"Einkaufen": FAV_CAT_SHOP,
                    @"Gesundheit": FAV_CAT_GESUNDHEIT,
                    @"Blumen": FAV_CAT_DIENSTLEISTUNG,
                    @"Presse": FAV_CAT_PRESSE,
                    @"Mode": FAV_CAT_SHOP,
                    @"Apotheke": FAV_CAT_GESUNDHEIT,
                    };
        NSString* cat = mapping[poi.menusubcat];
        if(cat){
            return cat;
        } else {
            return FAV_CAT_SHOP;
        }
    } else if([poi.menucat isEqualToString:@"Dienstleistungen"]){
        return FAV_CAT_DIENSTLEISTUNG;
    } else if([poi.menucat isEqualToString:@"Tickets & Reiseauskunft"]){
        if([poi.menusubcat isEqualToString:@"Fahrkarten"]){
            return nil;//don't list tickets in the "Dienstleistungen" sections
        }
        return FAV_CAT_DIENSTLEISTUNG;
    } else {
        return nil;
    }
}


+(NSArray<MBPXRShopCategory*>*)generatePXRGroups:(NSArray<RIMapPoi*>*)pois{
    NSMutableDictionary* catsForTitle = [NSMutableDictionary dictionaryWithCapacity:8];
    for(RIMapPoi* poi in pois){
        
        if ([poi.title isEqualToString:@"Fahrkartenautomat"]) {
            continue;
        }
        
        NSString* favCat = [RIMapPoi mapPXRToShopCategory:poi];
        if(favCat){
            MBPXRShopCategory* shopCat = catsForTitle[favCat];
            if(!shopCat){
                shopCat = [MBPXRShopCategory new];
                shopCat.title = favCat;
                shopCat.items = [NSMutableArray arrayWithCapacity:10];
                [catsForTitle setObject:shopCat forKey:favCat];
            }
            [shopCat.items addObject:poi];
        }
    }
    
    NSMutableArray* categoriesSorted = [NSMutableArray arrayWithCapacity:catsForTitle.count];
    for(NSString* catTitle in [MBStation categoriesForShoppen]){
        id shopCat = catsForTitle[catTitle];
        if(shopCat){
            [categoriesSorted addObject:shopCat];
        }
    }
    
    return categoriesSorted;
}

@end
