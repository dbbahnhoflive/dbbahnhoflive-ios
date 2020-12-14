// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "Wagenstand.h"
#import "FahrzeugAusstattung.h"

@interface Wagenstand()

//for IST-API: if this is true the train direction is ->, otherwise its <-
//for SOLL-API: ??
@property(nonatomic) BOOL trainWasReversed;

@end

@implementation Wagenstand

@synthesize additionalText = _additionalText;

-(instancetype)init{
    self = [super init];
    if(self){
        self.objectCreationTime = [NSDate date];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error
{
    if (self = [super initWithDictionary:dictionaryValue error:error]) {
        self.objectCreationTime = [NSDate date];
        
        if(self.subtrains.count == 1 && self.trainNumbers.count > 0){
            //special case: a single train with multiple numbers
            NSString *trainNumber = self.trainNumbers.firstObject;
            NSString *trainType = self.traintypes.firstObject;
            NSString *firstTrainType = [trainType copy];
            for(int i=1; i<self.trainNumbers.count; i++){
                trainNumber = [trainNumber stringByAppendingFormat:@"/%@",self.trainNumbers[i]];
                if(i < self.traintypes.count){
                    if(![self.traintypes[i] isEqualToString:firstTrainType]){
                        trainType = [trainType stringByAppendingFormat:@"/%@",self.traintypes[i]];
                    }
                }
            }
            Train *train = self.subtrains.firstObject;
            train.number = trainNumber;
            train.type = trainType;
        } else {
            //old implementation, uses only last trainNumber for single train case
            for (int i = 0; i < self.trainNumbers.count; i++) {
                NSString *trainNumber = self.trainNumbers[i];
                NSString *trainType = @"";
                if (i < self.traintypes.count) {
                    trainType = self.traintypes[i];
                } else {
                    trainType = [self.traintypes firstObject];
                }
                
                if (i < self.subtrains.count) {
                    Train *train = self.subtrains[i];
                    train.number = trainNumber;
                    train.type = trainType;
                } else {
                    Train *train = [self.subtrains firstObject];
                    train.number = trainNumber;
                    train.type = trainType;
                }
            }
        }
    }
    return self;
}

+ (NSValueTransformer *)waggonsJSONTransformer
{
    return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        NSArray *waggons = [MTLJSONAdapter modelsOfClass:Waggon.class fromJSONArray:value error:error];
        
        if (waggons) {
            return waggons;
        }
        return @[];
        
    } reverseBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        return value;
    }];
}


+ (NSValueTransformer *)subtrainsJSONTransformer
{
    return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        NSArray *trains = [MTLJSONAdapter modelsOfClass:Train.class fromJSONArray:value error:error];
        
        if (trains) {
            return trains;
        }
        return @[];
    } reverseBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        return value;
    }];
}

-(BOOL)isReversed{
    Waggon* firstWaggon = self.waggons.firstObject;
    Waggon* lastWaggon = self.waggons.lastObject;
    if([firstWaggon.sections.firstObject compare:lastWaggon.sections.firstObject] == NSOrderedDescending){
        return YES;
    }
    return NO;
}
-(void)reverse{
    NSLog(@"reversing waggons!");
    _waggons = _waggons.reverseObjectEnumerator.allObjects;
    for(Train* train in _subtrains){
        train.sections = train.sections.reverseObjectEnumerator.allObjects;
    }
    for(Waggon* waggon in _waggons){
        if([waggon isTrainHead] || [waggon isTrainBack]){
            //invert
            if([waggon isTrainHead]){
                waggon.type = @"v";
            } else {
                waggon.type = @"t";
            }
        }
    }
    self.trainWasReversed = YES;
}
-(void)addTrainDirection{
    Waggon* firstWaggon = _waggons.firstObject;
    Waggon* lastWaggon = _waggons.lastObject;
    NSLog(@"addTrainDirection: reversed %d, first %@, last %@",self.trainWasReversed,firstWaggon.type,lastWaggon.type);
    if(self.trainWasReversed){
        if(lastWaggon.isTrainBack){
            lastWaggon.type = @"right";
        } else if(lastWaggon.isTrainBothWays){
            lastWaggon.type = @"s-right";
        }
    } else {
        if(firstWaggon.isTrainHead){
            firstWaggon.type = @"left";
        } else if(firstWaggon.isTrainBothWays){
            firstWaggon.type = @"s-left";
        }
    }
}

- (Train*) destinationForWaggon:(Waggon*)waggon
{
    if(waggon.train){
        return waggon.train;
    }
    //code below can fail if we have two subtrains and the first waggon of the second train is in the same section as the first train, will return first train which is wrong!
    
    
    Train *destinationTrain;
    for (Train *train in self.subtrains) {
        
        destinationTrain = train;
        
        for (NSString *waggonSection in waggon.sections) {
            // check if train contains all waggon sections
            // if so, then this must be the destination of our waggon
            if (![train.sections containsObject:waggonSection]) {
                destinationTrain = nil;
            }
        }
        
        if (destinationTrain) {
            return destinationTrain;
        }
    }
    return nil;
}

- (NSInteger) indexOfWaggonForWaggonNumber:(NSString*)number
{
    for (Waggon *waggon in self.waggons) {
        if ([waggon.number isEqualToString:number]) {
            return [self.waggons indexOfObject:waggon];
        }
    }
    return 0;
}

- (NSString *) additionalText
{
    NSArray *textComponents = [_additionalText componentsSeparatedByString:@"\n"];
    textComponents = [textComponents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];
    return [textComponents componentsJoinedByString:@", "];
}

- (NSArray*) joinedSectionsList;
{
    NSMutableArray *allSections = [NSMutableArray array];
    for (Waggon *waggon in self.waggons) {
        for (NSString *section in waggon.sections) {
            if (![allSections containsObject:section]) {
                [allSections addObject:section];
            }
        }
    }
    
    // make List unique
    return [[NSOrderedSet orderedSetWithArray:allSections] array];
}

- (NSInteger) indexOfWaggonForSection:(NSString*)section
{
    for (Waggon *waggon in self.waggons) {
        if ([[waggon.sections lastObject] isEqualToString:section]) {
            return [self.waggons indexOfObject:waggon];
        }
    }
    return -1;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    
    return @{
             @"days": @"days",
             @"name": @"name",
             @"time": @"time",
             @"traintypes": @"traintypes",
             @"trainNumbers": @"trainNumbers",
             @"additionalText": @"additionalText",
             @"subtrains": @"subtrains",
             @"waggons": @"waggons"
             };
    
}

-(void)parseISTJSON:(NSDictionary*)istFormation{
    NSDictionary* halt = istFormation[@"halt"];
    NSString* abfahrtszeit = halt[@"abfahrtszeit"];
    if(abfahrtszeit.length > @"YYYY-MM-DDT".length){
        abfahrtszeit = [abfahrtszeit substringFromIndex:@"YYYY-MM-DDT".length];//expecting HH:MM after date
    } else {
        abfahrtszeit = @"";
    }
    if (abfahrtszeit.length > 5) {
        abfahrtszeit = [abfahrtszeit substringToIndex:5];
    }
    
    _time = abfahrtszeit;
    _platform = halt[@"gleisbezeichnung"];//is this really the departure platform?
    NSMutableArray* trainTypes = [NSMutableArray arrayWithCapacity:2];
    NSMutableArray* trainNumbers = [NSMutableArray arrayWithCapacity:2];
    
    NSMutableArray* trains = [NSMutableArray arrayWithCapacity:2];
    NSMutableArray* waggons = [NSMutableArray arrayWithCapacity:30];
    
    NSArray* allFahrzeuggruppe = istFormation[@"allFahrzeuggruppe"];
    
    //NOTE: IST returns IC/EC trains in multiple dictionaries inside allFahrzeuggruppe even though
    //      they all have the same destination station. We merge them together here:
    if(allFahrzeuggruppe.count > 0){
        NSMutableArray* mergedFahrzeuggruppe = [NSMutableArray arrayWithCapacity:allFahrzeuggruppe.count];
        NSDictionary* firstTrain = allFahrzeuggruppe.firstObject;
        NSMutableDictionary* firstTrainMutable = [firstTrain mutableCopy];
        [mergedFahrzeuggruppe addObject:firstTrainMutable];
        for(NSInteger i = 1; i<allFahrzeuggruppe.count; i++){
            
            NSString* stationFirstTrain = firstTrainMutable[@"zielbetriebsstellename"];
            NSString* numberFirstTrain = firstTrainMutable[@"verkehrlichezugnummer"];

            NSDictionary* followingTrain = allFahrzeuggruppe[i];
            NSString* stationFollowingTrain = followingTrain[@"zielbetriebsstellename"];
            NSString* numberFollowingTrain = followingTrain[@"verkehrlichezugnummer"];
            if(stationFirstTrain && numberFirstTrain && stationFollowingTrain && numberFollowingTrain &&  [stationFirstTrain isEqualToString:stationFollowingTrain] && [numberFirstTrain isEqualToString:numberFollowingTrain]){
                //same station, same number, merge these
                NSMutableArray* allFahrzeug = [firstTrainMutable[@"allFahrzeug"] mutableCopy];
                NSArray* allFahrzeugSecondTrain = followingTrain[@"allFahrzeug"];
                [allFahrzeug addObjectsFromArray:allFahrzeugSecondTrain];
                firstTrainMutable[@"allFahrzeug"] = allFahrzeug;
                //we added the allFahrzeug, but ignore the train!
            } else {
                //station or number has changed
                firstTrainMutable = [followingTrain mutableCopy];
                [mergedFahrzeuggruppe addObject:firstTrainMutable];                
            }
        }
        allFahrzeuggruppe = mergedFahrzeuggruppe;
    }
    
    //is this train inverted (F-A)?
    NSDictionary* firstTrain = allFahrzeuggruppe.firstObject;
    NSArray* wagonsInFirstTrain = firstTrain[@"allFahrzeug"];
    NSDictionary* firstFahrzeug = wagonsInFirstTrain.firstObject;
    NSString* firstSection = firstFahrzeug[@"fahrzeugsektor"];
    NSDictionary* lastTrain = allFahrzeuggruppe.lastObject;
    NSArray* wagonsInLastTrain = lastTrain[@"allFahrzeug"];
    NSDictionary* lastFahrzeug = wagonsInLastTrain.lastObject;
    NSString* lastSection = lastFahrzeug[@"fahrzeugsektor"];
    BOOL invertLists = NO;
    NSLog(@"sectors from %@-%@",firstSection,lastSection  );
    if([firstSection compare:lastSection] == NSOrderedDescending){
        NSLog(@"need to invert direction");
        invertLists = YES;
        self.trainWasReversed = YES;
    }
    
    NSArray* fahrzeugGruppeList = allFahrzeuggruppe;
    if(invertLists){
        fahrzeugGruppeList = allFahrzeuggruppe.reverseObjectEnumerator.allObjects;
    }
    for(NSDictionary* fahrzeuggruppe in fahrzeugGruppeList){
        Train* train = [[Train alloc] init];
        train.type = istFormation[@"zuggattung"];//looks like we don't have a type for a fahrzeuggruppe...
        NSString* verkehrlichezugnummer = fahrzeuggruppe[@"verkehrlichezugnummer"];
        if(verkehrlichezugnummer.length > 0){
            train.number = verkehrlichezugnummer;
        } else {
            train.number = istFormation[ @"zugnummer" ];
        }
        
        [trainTypes addObject:train.type];
        [trainNumbers addObject:train.number];
        
        train.destination = @{ @"destinationName" : fahrzeuggruppe[@"zielbetriebsstellename"] };
        //missing destinationVia (NSArray with NSString)
        NSMutableSet* sections = [NSMutableSet setWithCapacity:10];
        NSArray* fahrzeugList = fahrzeuggruppe[@"allFahrzeug"];
        if(invertLists){
            fahrzeugList = fahrzeugList.reverseObjectEnumerator.allObjects;
        }
        
        BOOL previousWasWaggon = NO;
        for(NSDictionary* fahrzeug in fahrzeugList){
            [sections addObject: fahrzeug[@"fahrzeugsektor"] ];
            
            Waggon* additionalTrain = nil;
            
            Waggon* waggon = [[Waggon alloc] init];
            waggon.train = train;
            
            waggon.number = fahrzeug[@"wagenordnungsnummer"];
            waggon.sections = @[ fahrzeug[@"fahrzeugsektor"] ];//only a single section on IST-API!
            waggon.length = 2;//or 1?
            NSString* kategorie = fahrzeug[@"kategorie"];
            if([kategorie isEqualToString:@"TRIEBKOPF"]
               || [kategorie isEqualToString:@"TRIEBWAGENBAUREIHE628928"]
               || [kategorie isEqualToString:@"LOK"]
               ){
                
                waggon.type = @"q";//head
                waggon.length = 1;//we only have only have one icon with small size
                if([kategorie isEqualToString:@"LOK"]){
                    waggon.type = @"s";
                }
                previousWasWaggon = NO;
            } else if([kategorie isEqualToString:@"DOPPELSTOCKSTEUERWAGENERSTEKLASSE"]
                      || [kategorie isEqualToString:@"DOPPELSTOCKSTEUERWAGENZWEITEKLASSE"]//MAIK
                      || [kategorie isEqualToString:@"DOPPELSTOCKSTEUERWAGENERSTEZWEITEKLASSE"]
                      || [kategorie isEqualToString:@"STEUERWAGENERSTEKLASSE"]
                      || [kategorie isEqualToString:@"STEUERWAGENZWEITEKLASSE"]
                      || [kategorie isEqualToString:@"STEUERWAGENERSTEZWEITEKLASSE"]){
                //need to split this into 2 objects
                if(!previousWasWaggon){
                    waggon.type = @"q";//head
                    waggon.length = 1;
                    [waggons addObject:waggon];

                } else {
                    waggon.type = @"q";//head
                    
                    waggon.length = 1;
                    additionalTrain = waggon;
                }

                //create second waggon
                waggon = [[Waggon alloc] init];
                waggon.train = train;
                waggon.number = fahrzeug[@"wagenordnungsnummer"];
                waggon.sections = @[ fahrzeug[@"fahrzeugsektor"] ];//only a single section on IST-API!
                waggon.length = 1;

                if([kategorie rangeOfString:@"ERSTEZWEITEKLASSE"].location != NSNotFound){
                    waggon.type = @"3";
                } else {
                    if([kategorie rangeOfString:@"ERSTEKLASSE"].location == NSNotFound){
                        //second class
                        waggon.type = @"2";
                    } else {
                        waggon.type = @"1";
                    }
                }
                previousWasWaggon = YES;
            } else if([kategorie isEqualToString:@"SPEISEWAGEN"]){
                waggon.type = @"a";//Restaurant, first or second class???
                previousWasWaggon = YES;
            } else if([kategorie isEqualToString:@"DOPPELSTOCKWAGENERSTEZWEITEKLASSE"]
                   || [kategorie isEqualToString:@"REISEZUGWAGENERSTEZWEITEKLASSE"]
                   || [kategorie isEqualToString:@"SCHLAFWAGENERSTEZWEITEKLASSE"]//type c?
                   ){
                    waggon.type = @"3";//1.Class + 2.Class
                previousWasWaggon = YES;
            } else if([kategorie isEqualToString:@"DOPPELSTOCKWAGENERSTEKLASSE"]
                      || [kategorie isEqualToString:@"REISEZUGWAGENERSTEKLASSE"]
                      || [kategorie isEqualToString:@"SCHLAFWAGENERSTEKLASSE"]//type c?
                      || [kategorie isEqualToString:@"LIEGEWAGENERSTEKLASSE"]//type c?
                      || [kategorie isEqualToString:@"HALBGEPAECKWAGENERSTEKLASSE"]//type??
                      ){
                waggon.type = @"1";
                previousWasWaggon = YES;
            } else if([kategorie isEqualToString:@"HALBSPEISEWAGENERSTEKLASSE"]){
                waggon.type = @"4";//1.Class + Restaurant
                previousWasWaggon = YES;
            } else if([kategorie isEqualToString:@"HALBSPEISEWAGENZWEITEKLASSE"]){
                waggon.type = @"7";//2.Class + Restaurant
                previousWasWaggon = YES;
            } else if([kategorie isEqualToString:@"HALBGEPAECKWAGENZWEITEKLASSE"]){
                waggon.type = @"6";//2.Class + Luggage
                previousWasWaggon = YES;
            } else if([kategorie isEqualToString:@"GEPAECKWAGEN"]){
                waggon.type = @"8";//luggageCoach??
                previousWasWaggon = YES;
            } else {
                //all other are 2!
                waggon.type = @"2";
                previousWasWaggon = YES;
            }
            
            if([@"GESCHLOSSEN" isEqualToString:fahrzeug[@"status"]] && ![@"TRIEBKOPF" isEqualToString: kategorie]){
                waggon.type = @"8";
                waggon.differentDestination = @"verschlossen";
                previousWasWaggon = YES;
            }
            
            NSArray* allFahrzeugausstattung = fahrzeug[@"allFahrzeugausstattung"];
            NSMutableArray* ausstattungList = [NSMutableArray arrayWithCapacity:allFahrzeugausstattung.count+1];
            NSMutableArray* ausstattungOhneIcon = [NSMutableArray arrayWithCapacity:2];
            for(NSDictionary* ausstattung in allFahrzeugausstattung){
                FahrzeugAusstattung* fa = [FahrzeugAusstattung new];
                fa.ausstattungsart = ausstattung[@"ausstattungsart"];
                fa.anzahl = ausstattung[@"anzahl"];
                fa.bezeichnung = ausstattung[@"bezeichnung"];
                fa.status = ausstattung[@"status"];
                if([fa iconNames].count == 0){
                    [ausstattungOhneIcon addObject:fa];
                } else {
                    [ausstattungList addObject:fa];
                }
            }
            [ausstattungList addObjectsFromArray:ausstattungOhneIcon];
            if([waggon.type isEqualToString:@"a"] || [waggon.type isEqualToString:@"4"] || [waggon.type isEqualToString:@"7"]){
                FahrzeugAusstattung* fa = [FahrzeugAusstattung new];
                fa.symbol = @"p";//bordrestaurant
                [ausstattungList insertObject:fa atIndex:0];
            }
            waggon.fahrzeugausstattung = ausstattungList;
            [waggons addObject:waggon];
            
            if(additionalTrain){
                [waggons addObject:additionalTrain];
                previousWasWaggon = NO;
            }
        }
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES];
        train.sections = [sections sortedArrayUsingDescriptors:@[sort]];
        [trains addObject:train];
    }
    
    Waggon* firstWaggon = waggons.firstObject;
    Waggon* lastWaggon = waggons.lastObject;
    
    //we have some locks marked as q (<=) , that should be v (=>)
    //all trains that have a waggon before should be v
    for(int i=1; i<waggons.count; i++){
        Waggon* waggon = waggons[i];
        if([waggon.type isEqualToString:@"q"]){
            Waggon* prevWaggon = waggons[i-1];
            if(![prevWaggon.type isEqualToString:@"s"] && ![prevWaggon.type isEqualToString:@"v"]){
                waggon.type = @"v";
            }
        }
    }
    
    if(self.trainWasReversed){
        // =>
        if([lastWaggon.type isEqualToString:@"v"]){
            lastWaggon.type = @"right";
        } else if([lastWaggon.type isEqualToString:@"s"]){
            lastWaggon.type = @"s-right";
        }
    } else {
        // <=
        if([firstWaggon.type isEqualToString:@"q"]){
            firstWaggon.type = @"left";
        } else if([firstWaggon.type isEqualToString:@"s"]){
            firstWaggon.type = @"s-left";
        }
    }
    
    
    _traintypes = trainTypes;
    _trainNumbers = trainNumbers;

    _subtrains = trains;
    _waggons = waggons;
}


+(NSString*)makeDateStringForTime:(NSString*)formattedTime
{
    NSMutableString* res = [[NSMutableString alloc] init];
    
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"YYYYMMdd"];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    NSString* time = [formattedTime stringByReplacingOccurrencesOfString:@":" withString:@""];
    if(time.length > 4){
        time = [time substringToIndex:4];
    }
    NSDate* now = [NSDate date];
    [res appendString:[df stringFromDate:now]];
    [res appendString:time];
    return res;
}

+(NSString*)getTrainNumberForWagenstand:(Wagenstand*)wagenstand{
    NSString* trainNumber = wagenstand.trainNumbers.firstObject;
    return trainNumber;
}

+(NSString*)getTrainTypeForWagenstand:(Wagenstand*)wagenstand{
    NSString* trainType = wagenstand.traintypes.firstObject;
    return trainType;
}

+(NSString*)getDateAndTimeForWagenstand:(Wagenstand*)wagenstand
{
    NSString* time = wagenstand.time;
    //NSString* dateAndTime = [self makeDateStringForTime:time];
    
    return time;
}

+(BOOL)isValidTrainTypeForIST:(NSString*) trainType
{
    return [trainType isEqualToString:@"ICE"] || [trainType isEqualToString:@"IC"] || [trainType isEqualToString:@"EC"];
}

@end
