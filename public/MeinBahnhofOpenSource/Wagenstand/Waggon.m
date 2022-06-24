// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "Waggon.h"
#import "FahrzeugAusstattung.h"
#import "MBUIHelper.h"

@interface Waggon()

@property(nonatomic,strong) NSMutableArray* symbolTagViews;

@end

@implementation Waggon 

+ (NSValueTransformer *)typeJSONTransformer
{
    return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        NSString *type = value;
        type = [type stringByReplacingOccurrencesOfString:@".Kl" withString:@""];
        type = [type stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        return type;
    } reverseBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        return value;
    }];
}

+ (NSValueTransformer *)symbolsJSONTransformer
{
    return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        NSString *symbols = value;
        NSInteger noOfSymbols = symbols.length;
        
        if (noOfSymbols == 0) {
            return @[];
        }
        
        NSMutableArray *characters = [[NSMutableArray alloc] initWithCapacity:noOfSymbols];
        for (int i=0; i < noOfSymbols; i++) {
            NSString *ichar  = [NSString stringWithFormat:@"%c", [symbols characterAtIndex:i]];
            [characters addObject:ichar];
        }
        
        return characters;
    } reverseBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        return value;
    }];
}

+ (NSValueTransformer *)waggonJSONTransformer
{
    return [NSValueTransformer valueTransformerForName:MTLBooleanValueTransformerName];
}

+ (NSDictionary*) JSONKeyPathsByPropertyKey
{
    return @{
             @"differentDestination": @"differentDestination",
             @"length": @"length",
             @"number": @"number",
             @"position": @"position",
             @"sections": @"sections",
             @"symbols": @"symbols",
             @"type": @"type",
             @"waggon": @"waggon"
             };
}

-(NSArray *)fahrzeugausstattung{
    if(_fahrzeugausstattung)
        return _fahrzeugausstattung;
    if(self.symbols.count > 0){
        NSMutableArray* aus = [NSMutableArray arrayWithCapacity:self.symbols.count];
        for(NSString* s in self.symbols){
            FahrzeugAusstattung* fa = [FahrzeugAusstattung new];
            fa.symbol = s;
            [aus addObject:fa];
        }
        return aus;
    }
    return nil;
}

# pragma -
# pragma Computed Properties
- (UIColor *) colorForType;
{
    NSDictionary *colors = @{@"1": [UIColor db_firstClass],
                             @"3": [UIColor db_firstClass], // 1.Class + 2.Class
                             @"4": [UIColor db_firstClass], // 1.Class + Restaurant
                             @"i": [UIColor db_firstClass], // Regio 1.Class + 2.Class

                             @"2": [UIColor db_secondClass],
                             @"5": [UIColor db_secondClass],
                             @"6": [UIColor db_secondClass], // 2.Class + Luggage
                             @"7": [UIColor db_secondClass], // 2.Class + Restaurant
                             @"h": [UIColor db_secondClass],

                             @"8": [UIColor db_luggageCoach],
                             @"9": [UIColor db_luggageCoach],
                             
                             @"a": [UIColor db_restaurant],
                             @"b": [UIColor db_restaurant],
                             @"e": [UIColor db_restaurant],

                             @"c": [UIColor db_sleepingCoach],
                             @"g": [UIColor db_sleepingCoach],

                             };
    
    UIColor *matchingColor = [UIColor db_fallback];
    
    if (self.type) {
        matchingColor = colors[self.type];
    }
    
    if (!matchingColor) {
        matchingColor = [UIColor db_fallback];
    }
    
    return matchingColor;
}


-(UIColor*) secondaryColor
{
    NSDictionary *colors = @{
                             @"3": [UIColor db_secondClass], // 1.Class + 2.Class
                             @"4": [UIColor db_restaurant], // 1.Class + Restaurant
                             @"i": [UIColor db_secondClass], // Regio 1.Class + 2.Class
                             @"6": [UIColor db_luggageCoach], // 2.Class + Luggage
                             @"7": [UIColor db_restaurant], // 2.Class + Restaurant
                             };
    
    return colors[self.type];
}

- (BOOL) waggonHasMultipleClasses
{
    NSArray *typesWithMultipleColors = @[
                             @"3", // 1.Class + 2.Class
                             @"4", // 1.Class + Restaurant
                             @"i", // Regio 1.Class + 2.Class
                             @"6", // 2.Class + Luggage
                             @"7", // 2.Class + Restaurant
                             ];
    
    return [typesWithMultipleColors containsObject:self.type];
}


+ (NSString*)descriptionForSymbol:(NSString*)symbol
{
    NSDictionary *description = @{
                                  @"A": @"Bordbistro",
                                  @"B": @"Lufthansa",
                                  @"C": @"bahn.comfort",
                                  @"D": @"Snack Point (Imbiss)",
                                  @"E": @"Ruhebereich",
                                  @"F": @"Familienbereich",
                                  @"G": @"Club",
                                  @"H": @"Office",
                                  @"I": @"Silence",
                                  @"J": @"Traveller",
                                  @"a": @"ic:kurier",
                                  @"b": @"Autotransport",
                                  @"c": @"Telefon",
                                  @"d": @"Post",
                                  @"e": @"Rollstuhlgerecht",
                                  @"f": @"Nichtraucher",
                                  @"g": @"Raucher",
                                  @"h": @"Fahrrad-Beförderung",
                                  @"k": @"Großraumwagen",
                                  @"l": @"Schlafwagen",
                                  @"m": @"Liegewagen",
                                  @"n": @"Plätze für mobilitätseingeschränkte Menschen",
                                  @"o": @"Kleinkindabteil",
                                  @"p": @"Bordrestaurant",
                                  @"w": @"Rezeption",
                                  @"x": @"Liegesesselwagen",
                                  @"y": @"Schlafabteile Deluxe",
                                  @"{": @"Ski-Abteil",
                                  @"}": @"Gruppenreservierungen"
                                  };
    
    return description[symbol];
}

- (BOOL) isRestaurant
{
    if(_fahrzeugausstattung){
        for(FahrzeugAusstattung* fa in _fahrzeugausstattung){
            if([fa.symbol isEqualToString:@"p"]){
                return YES;
            }
        }
    }
    
    if ([self.symbols containsObject:@"p"]) {
        return YES;
    }
    return NO;
}

// type s is a train that points in both directions (Regio-Train)

-(BOOL)isTrainHeadWithDirection{
    return [self.type isEqualToString:@"left"];
}
-(BOOL)isTrainBackWithDirection{
    return [self.type isEqualToString:@"right"];
}
-(BOOL)isTrainBothWithLeft{
    return [self.type isEqualToString:@"s-left"];
}
-(BOOL)isTrainBothWithRight{
    return [self.type isEqualToString:@"s-right"];
}

- (BOOL) isTrainHead
{
    if ([self.type isEqualToString:@"q"]
        || [self.type isEqualToString:@"t"]
        || [self.type isEqualToString:@"Ü"]
        || [self.type isEqualToString:@"left"]) {
        return YES;
    }
    return NO;
}

- (BOOL) isTrainBack;
{
    if ([self.type isEqualToString:@"v"]
        || [self.type isEqualToString:@"r"]
        || [self.type isEqualToString:@"Ä"]
        || [self.type isEqualToString:@"right"]) {
        return YES;
    }
    return NO;
}

- (BOOL) isTrainBothWays
{
    return [self.type isEqualToString:@"s"] || [self.type isEqualToString:@"s-left"] || [self.type isEqualToString:@"s-right"];
}

- (NSString*)classOfWaggon;
{
    NSDictionary *classes = @{@"1": @"1",
                             @"2": @"2",
                             @"3": @"1",
                             @"4": @"1",
                             @"5": @"2",
                             @"6": @"2",
                             @"7": @"2",
                             @"8": @"",
                             @"9": @"",
                             @"a": @"1",
                             @"b": @"1",
                             @"c": @"",
                             @"e": @"1",
                             @"g": @"",
                             @"h": @"2",
                             @"i": @"1",
                             };
    if (!self.type) {
        return @"";
    }
    
    return classes[self.type];
}

- (CGFloat) heightOfCell
{
    if (self.isTrainBack || self.isTrainHead) {
        return 160.f;
    }
    
    if (self.length == 1) {
        return 120.f;
    } else if (self.length == 2) {
        return 160.f;
    }
    return 0.f;
}

- (BOOL) bottomHalfCell
{
    if (self.length == 0 && [self.number isEqualToString:@""]) {
        return YES;
    }
    return NO;
}


-(NSArray*)setupTagViewsForWidth:(CGFloat)width{
    if(self.symbolTagViews.count > 0){
        [self setupTagViewsY:width];
        return self.symbolTagViews;
    }
    self.symbolTagViews = [NSMutableArray arrayWithCapacity:self.fahrzeugausstattung.count];
    for(FahrzeugAusstattung* ausstattung in self.fahrzeugausstattung){
        if([ausstattung displayEntry]){
            SymbolTagView *tagView = [[SymbolTagView alloc] initWithFrame:CGRectMake(0, 0, width, 20)];
            if([ausstattung isOldAPI]){
                tagView.symbolCode = ausstattung.symbol;
            } else {
                tagView.symbolIcons = [ausstattung iconNames];
            }
            tagView.symbolDescription = [ausstattung displayText];
            [self.symbolTagViews addObject:tagView];
        }
    }
    [self setupTagViewsY:width];
    return self.symbolTagViews;
}
-(void)setupTagViewsY:(CGFloat)width{
    CGFloat offset = 10;
    for (int i = 0; i < self.symbolTagViews.count; i++) {
        SymbolTagView *tagView = self.symbolTagViews[i];
        [tagView resizeForWidth:width];
        tagView.y = offset;
        tagView.x = 0;
        offset += tagView.frame.size.height + 10;
    }
}


@end
