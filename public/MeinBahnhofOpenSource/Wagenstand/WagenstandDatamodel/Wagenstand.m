// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "Wagenstand.h"
#import "FahrzeugAusstattung.h"
#import "NSDictionary+MBDictionary.h"

@interface Wagenstand()

//for IST-API: if this is true the train direction is ->, otherwise its <-
@property(nonatomic) BOOL trainWasReversed;

@end

@implementation Wagenstand

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
    NSArray *textComponents = [self.additionalText componentsSeparatedByString:@"\n"];
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


-(void)parseRISTransport:(NSDictionary*)risTransport{
    NSDictionary* platform = [risTransport db_dictForKey:@"platform"];
    _platform = [platform db_stringForKey:@"platform"];
    
    NSMutableArray* trainTypes = [NSMutableArray arrayWithCapacity:2];
    NSMutableArray* trainNumbers = [NSMutableArray arrayWithCapacity:2];
    
    NSMutableArray* trains = [NSMutableArray arrayWithCapacity:2];
    NSMutableArray* waggons = [NSMutableArray arrayWithCapacity:30];

    NSArray* groups = [risTransport db_arrayForKey:@"groups"];
    //NOTE: IST returns IC/EC trains in multiple dictionaries inside allFahrzeuggruppe even though
    //      they all have the same destination station. We merge them together here:
    if(groups.count > 0){
        NSMutableArray* mergedFahrzeuggruppe = [NSMutableArray arrayWithCapacity:groups.count];
        NSDictionary* firstTrain = groups.firstObject;
        NSMutableDictionary* firstTrainMutable = [firstTrain mutableCopy];
        [mergedFahrzeuggruppe addObject:firstTrainMutable];
        for(NSInteger i = 1; i<groups.count; i++){

            NSDictionary* destinationFirstTrain = [firstTrainMutable db_dictForKey:@"destination"];
            NSNumber* startJourneyNumber = [[firstTrainMutable db_dictForKey:@"journeyRelation"] db_numberForKey:@"startJourneyNumber"];

            NSDictionary* followingTrain = groups[i];
            NSDictionary* destinationFollowingTrain = [followingTrain db_dictForKey:@"destination"];
            NSNumber* startJourneyNumberFollowingTrain = [[followingTrain db_dictForKey:@"journeyRelation"] db_numberForKey:@"startJourneyNumber"];

            if(destinationFirstTrain.count > 0 && destinationFollowingTrain.count > 0 && [destinationFirstTrain isEqualToDictionary:destinationFollowingTrain] && [startJourneyNumber isEqualToNumber:startJourneyNumberFollowingTrain]){
                //same destination, merge these
                NSMutableArray* allFahrzeug = [firstTrainMutable[@"vehicles"] mutableCopy];
                NSArray* allFahrzeugSecondTrain = followingTrain[@"vehicles"];
                [allFahrzeug addObjectsFromArray:allFahrzeugSecondTrain];
                firstTrainMutable[@"vehicles"] = allFahrzeug;
                //we added the vehicles, but ignore the train!
            } else {
                //station or number has changed
                firstTrainMutable = [followingTrain mutableCopy];
                [mergedFahrzeuggruppe addObject:firstTrainMutable];
            }
        }
        groups = mergedFahrzeuggruppe;
    }
    
    //is this train inverted (F-A)?
    BOOL invertLists = NO;
    NSDictionary* firstgroup = groups.firstObject;
    NSDictionary* lastgroup = groups.lastObject;
    NSArray* firstvehicles = [firstgroup db_arrayForKey:@"vehicles"];
    NSArray* lastvehicles = [lastgroup db_arrayForKey:@"vehicles"];
    NSDictionary* firstvehicle = firstvehicles.firstObject;
    NSDictionary* lastvehicle = lastvehicles.lastObject;
    NSDictionary* platformPositionFirst = [firstvehicle db_dictForKey:@"platformPosition"];
    NSDictionary* platformPositionLast = [lastvehicle db_dictForKey:@"platformPosition"];
    NSString* firstSection = [platformPositionFirst db_stringForKey:@"sector"];
    NSString* lastSection = [platformPositionLast db_stringForKey:@"sector"];;
    NSLog(@"sectors from %@-%@",firstSection,lastSection  );
    if([firstSection compare:lastSection] == NSOrderedDescending){
        NSLog(@"need to invert direction");
        invertLists = YES;
        self.trainWasReversed = YES;
        groups = groups.reverseObjectEnumerator.allObjects;
    }

    for(NSDictionary* group in groups){
        NSDictionary* journeyRelation = [group db_dictForKey:@"journeyRelation"];
        Train* train = [[Train alloc] init];
        train.type = [journeyRelation db_stringForKey:@"startCategory"];
        train.number = [journeyRelation db_numberForKey:@"startJourneyNumber"].stringValue;
        
        [trainTypes addObject:train.type];
        [trainNumbers addObject:train.number];

        NSDictionary* destination = [group db_dictForKey:@"destination"];
        train.destination = [destination db_stringForKey:@"name"];
        
        NSMutableSet* sections = [NSMutableSet setWithCapacity:10];
        
        NSArray* vehicles = [group db_arrayForKey:@"vehicles"];
        if(invertLists){
            vehicles = vehicles.reverseObjectEnumerator.allObjects;
        }
        BOOL previousWasWaggon = NO;
        for(NSDictionary* vehicle in vehicles){
            Waggon* additionalTrain = nil;
            Waggon* waggon = [[Waggon alloc] init];
            waggon.train = train;
            
            NSDictionary* platformPosition = [vehicle db_dictForKey:@"platformPosition"];
            NSString* sector = [platformPosition db_stringForKey:@"sector"];
            if(sector == nil){
                sector = @"";
            }
            waggon.sections = @[ sector ];
            waggon.number = [vehicle db_numberForKey:@"wagonIdentificationNumber"].stringValue;
            [sections addObject:sector];

            waggon.length = 2;
            waggon.type = @"2";
            NSDictionary* type = [vehicle db_dictForKey:@"type"];
            NSString* category = [type db_stringForKey:@"category"];
            if(   [category isEqualToString:@"POWERCAR"]
               || [category isEqualToString:@"LOCOMOTIVE"]
               ){
                waggon.length = 1;//we only have only have one icon with small size
                waggon.type = @"q";//head
                if([category isEqualToString:@"LOCOMOTIVE"]){
                    waggon.type = @"s";
                }
                previousWasWaggon = NO;
            } else if([category isEqualToString:@"CONTROLCAR_FIRST_CLASS"]
                      || [category isEqualToString:@"CONTROLCAR_ECONOMY_CLASS"]
                      || [category isEqualToString:@"CONTROLCAR_FIRST_ECONOMY_CLASS"]
                      || [category isEqualToString:@"DOUBLECONTROLCAR_ECONOMY_CLASS"]
                      || [category isEqualToString:@"DOUBLECONTROLCAR_FIRST_ECONOMY_CLASS"]
                      || [category isEqualToString:@"DOUBLEDECK_CONTROLCAR_FIRST_ECONOMOY_CLASS"] //Typo in v2.
                      || [category isEqualToString:@"DOUBLEDECK_CONTROLCAR_FIRST_ECONOMY_CLASS"] //for future fixes
                      || [category isEqualToString:@"DOUBLEDECK_CONTROLCAR_FIRST_CLASS"]
                      || [category isEqualToString:@"DOUBLEDECK_CONTROLCAR_ECONOMY_CLASS"]
                      ){
                //need to split this into 2 objects: this waggon is the controlcar and we add another passenger car
                waggon.type = @"q";//head
                waggon.length = 1;
                if(!previousWasWaggon){
                    [waggons addObject:waggon];
                } else {
                    additionalTrain = waggon;//added after the waggon!
                }
                
                Waggon* previousWaggon = waggon;

                //create second waggon
                waggon = [[Waggon alloc] init];
                waggon.train = train;
                waggon.number = previousWaggon.number;
                waggon.sections = previousWaggon.sections;
                waggon.length = 1;

                if([category rangeOfString:@"FIRST_ECONOMY"].location != NSNotFound
                   || [category rangeOfString:@"FIRST_ECONOMOY"].location != NSNotFound){
                    waggon.type = @"3";
                } else {
                    if([category rangeOfString:@"FIRST_CLASS"].location == NSNotFound){
                        //second class
                        waggon.type = @"2";
                    } else {
                        waggon.type = @"1";
                    }
                }
                previousWasWaggon = YES;
            } else if([category isEqualToString:@"DININGCAR"]){
                waggon.type = @"a";//Restaurant, first or second class???
                previousWasWaggon = YES;
            } else if([category isEqualToString:@"DOUBLEDECK_FIRST_ECONOMY_CLASS"]
                   || [category isEqualToString:@"PASSENGERCARRIAGE_FIRST_ECONOMY_CLASS"]
                   || [category isEqualToString:@"SLEEPER_FIRST_ECONOMY_CLASS"]//type c?
                   ){
                    waggon.type = @"3";//1.Class + 2.Class
                previousWasWaggon = YES;
            } else if([category isEqualToString:@"DOUBLEDECK_FIRST_CLASS"]
                      || [category isEqualToString:@"PASSENGERCARRIAGE_FIRST_CLASS"]
                      || [category isEqualToString:@"SLEEPER_FIRST_CLASS"]//type c?
                      || [category isEqualToString:@"COUCHETTE_FIRST_CLASS"]//type c?
                      ){
                waggon.type = @"1";
                previousWasWaggon = YES;
            } else if([category isEqualToString:@"HALFDININGCAR_FIRST_CLASS"]){
                waggon.type = @"4";//1.Class + Restaurant
                previousWasWaggon = YES;
            } else if([category isEqualToString:@"HALFDININGCAR_ECONOMY_CLASS"]){
                waggon.type = @"7";//2.Class + Restaurant
                previousWasWaggon = YES;
//            } else if([category isEqualToString:@"HALBGEPAECKWAGENZWEITEKLASSE"]){//???
//                waggon.type = @"6";//2.Class + Luggage
//                previousWasWaggon = YES;
            } else if([category isEqualToString:@"BAGGAGECAR"]){
                waggon.type = @"8";//luggageCoach??
                previousWasWaggon = YES;
            } else {
                //all other are 2!
                waggon.type = @"2";
                previousWasWaggon = YES;
            }
            
            NSString* status = [vehicle db_stringForKey:@"status"];
            if([status isEqualToString:@"CLOSED"]){
                waggon.type = @"8";
                waggon.differentDestination = @"verschlossen";
            }

            //parse "fahrzeugaustattung"
            NSArray* amenities = [vehicle db_arrayForKey:@"amenities"];
            NSMutableArray* ausstattungList = [NSMutableArray arrayWithCapacity:5];
            NSMutableArray* ausstattungOhneIcon = [NSMutableArray arrayWithCapacity:2];
            for(NSDictionary* ausstattung in amenities){
                FahrzeugAusstattung* fa = [FahrzeugAusstattung new];
                fa.ausstattungsart = ausstattung[@"type"];
                fa.anzahl = [ausstattung db_numberForKey:@"amount"].stringValue;
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


+(NSString*)dateRequestStringForTimestamp:(NSTimeInterval)timestamp
{
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd"];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    return [df stringFromDate:date];
}

+(NSString*)getTrainNumberForWagenstand:(Wagenstand*)wagenstand{
    NSString* trainNumber = wagenstand.trainNumbers.firstObject;
    return trainNumber;
}

+(NSString*)getTrainTypeForWagenstand:(Wagenstand*)wagenstand{
    NSString* trainType = wagenstand.traintypes.firstObject;
    return trainType;
}



@end
