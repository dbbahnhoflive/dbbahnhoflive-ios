// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBTrainJourneyRequestManager.h"
#import <AFNetworking/AFNetworking.h>
#import "Constants.h"
#import "NSDictionary+MBDictionary.h"
#import "MBNetworkFactory.h"

@interface MBTrainJourneyRequestManager()
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic,strong) NSDateFormatter* dateFormatter;
@end

#define kRISJourneyBaseURL @"/ris-journeys/v1"


#define DEBUG_MODE NO
//Testdata for "Berlin-Schöneweide", a train that used a different path

@implementation MBTrainJourneyRequestManager

+ (MBTrainJourneyRequestManager*) sharedManager
{
    static MBTrainJourneyRequestManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
        
        sharedManager.dateFormatter = [NSDateFormatter new];
        sharedManager.dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
        sharedManager.dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"DE"];
        sharedManager.dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"Europe/Berlin"];

        sharedManager.sessionManager = [MBNetworkFactory createRISSessionManager];
    });
    return sharedManager;
}

-(NSString*)baseUrl{
    return [[Constants kDBAPI] stringByAppendingString: kRISJourneyBaseURL];
}

+(NSDateFormatter *)dateFormatter{
    return MBTrainJourneyRequestManager.sharedManager.dateFormatter;
}

- (void) loadJourneyForEvent:(Event *)event
                  completionBlock:(void (^)(MBTrainJourney * _Nullable journey))completion
{
    [self loadJourneyForEvent:event previousDay:NO completionBlock:completion];
}

- (void) loadJourneyForEvent:(Event *)event
                 previousDay:(BOOL)fromPreviousDay
                  completionBlock:(void (^)(MBTrainJourney * _Nullable journey))completion
{
    //completion(nil);return;//simulate failure
    //event.journeyID = @"36a450a9-fb46-49ce-b8be-36116f5bf930";//test-fixed-journey-id
    if(event.journeyID.length > 0){
        NSLog(@"use cached journeyID %@",event.journeyID);
        //this event was requested before, use this id
        [self getJourneyForId:event.journeyID
                        event:event
              completionBlock:^(MBTrainJourney * _Nullable journey) {
                completion(journey);
        }];
        return;
    }
    

    //1.) get the journeyID from byrelation API
    [self getJourneyIDsForEvent:event previousDay:fromPreviousDay completionBlock:^(NSArray<NSString *> * _Nullable journeyIDs) {
        if(journeyIDs.count == 0){
            //no journeys found or API error
            completion(nil);
            return;
        }
        if(journeyIDs.count == 1){
            //single match
            [self getJourneyForId:journeyIDs.firstObject
                            event:event
                  completionBlock:^(MBTrainJourney * _Nullable journey) {
                if(journey.dateMismatch && fromPreviousDay == false){
                    [self loadJourneyForEvent:event previousDay:YES completionBlock:completion];
                } else if(!journey.dateMismatch) {
                    completion(journey);
                } else {
                    //2nd request after dateMismatch failed, stop
                    NSLog(@"2nd request with date from yesterday failed, stopping");
                    completion(nil);
                }
            }];
        } else {
            //find correct journey
            NSLog(@"no unique journey found: %lu possible journeys",(unsigned long)journeyIDs.count);
            //use a limit here, e.g. don't request 14 different journeys (THA 9423 von Düsseldorf nach Essen)
            if(journeyIDs.count > 4){
                NSLog(@"Too many IDs, requesting only the first four!!!");
                journeyIDs = [journeyIDs subarrayWithRange:NSMakeRange(0, 4)];
            }
            //iterate over the journeys, stop when there is a match
            NSInteger index = 0;
            [self checkJourneyAtIndex:index ids:journeyIDs event:event completion:^(MBTrainJourney * _Nullable journey){
                if(journey.dateMismatch){
                    [self loadJourneyForEvent:event previousDay:YES completionBlock:completion];
                } else if(journey) {
                    NSLog(@"found journey: %@",journey.journeyID);
                    completion(journey);
                } else {
                    NSLog(@"could not find matching journey");
                    completion(nil);
                }
            }];
        }
    }];
    
}

-(void)checkJourneyAtIndex:(NSInteger)index ids:(NSArray<NSString*>*)journeyIDs event:(Event*)event completion:(void (^)(MBTrainJourney * _Nullable journey))completion{
    NSLog(@"test journey at index %ld",(long)index);
    [self getJourneyForId:journeyIDs[index]
                    event:event
          completionBlock:^(MBTrainJourney * _Nullable journey) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(journey){
                NSLog(@"found matching journey, (dateMismatch=%d), stop here",journey.dateMismatch);
                completion(journey);
            } else {
                if(index+1 < journeyIDs.count){
                    //test next one
                    [self checkJourneyAtIndex:index+1 ids:journeyIDs event:event completion:completion];
                } else {
                    //no more journeys to test
                    completion(nil);
                }
            }
        });
    }];
}


- (void) getJourneyIDsForEvent:(Event*)event
                   previousDay:(BOOL)fromPreviousDay
                  completionBlock:(void (^)(NSArray<NSString*> * _Nullable journeyIDs))completion
{
    Stop* stop = event.stop;
    if(!event){
        NSLog(@"ERROR; stop without event");
        completion(nil);
        return;
    }
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:event.timestamp];
    NSLog(@"load journey for stop %@, from eva %@, Kategorie %@, Fahrtnummer %@, Linie %@, Zeit %@",stop.stopId,stop.evaNumber,stop.transportCategory.transportCategoryType,stop.transportCategory.transportCategoryOriginalNumber, event.lineIdentifier,date);

    NSString* category = stop.transportCategory.transportCategoryType;
    NSString* path = [NSString stringWithFormat:@"%@/byrelation?number=%@",self.baseUrl,stop.transportCategory.transportCategoryOriginalNumber];
    if(category){
        path = [path stringByAppendingFormat:@"&category=%@",category];
    }
    if(event.lineIdentifier.length > 0){
        NSString* line = [event.lineIdentifier stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
        path = [path stringByAppendingFormat:@"&line=%@",line];
    }
    if(fromPreviousDay){
        NSDateFormatter* df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd"];
        [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
        NSString* dateString = [df stringFromDate:[NSDate dateWithTimeIntervalSinceNow:-60*60*24]];
        path = [path stringByAppendingFormat:@"&date=%@",dateString];
    }
    [self.sessionManager GET:path
                  parameters:nil
                     headers:nil
                    progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionTask *operation, id responseObject) {
        //NSLog(@"MBTrainJourney.byrelation: %@",responseObject);
        if([responseObject isKindOfClass:NSDictionary.class]){
            NSDictionary* dict = responseObject;
            NSArray* journeys = [dict db_arrayForKey:@"journeys"];
            //NSLog(@"got %lu journeys",(unsigned long)journeys.count);
            NSMutableArray<NSString*>* journeyIDs = [NSMutableArray arrayWithCapacity:journeys.count];
            for(NSDictionary* journey in journeys){
                if(![journey isKindOfClass:NSDictionary.class]){
                    continue;
                }
                NSString* journeyID = [journey db_stringForKey:@"journeyID"];
                if(journeyID){
                    [journeyIDs addObject:journeyID];
                }
            }
            NSLog(@"got journey IDs %@",journeyIDs);
            completion(journeyIDs);
        } else {
            completion(nil);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error %@", error);
        completion(nil);
    }];
}

- (NSString *)findEvent:(Event *)event withTargetEva:(NSString *)targetEva inEvents:(NSArray *)events {
    NSString* timeScheduleAtOurEva = nil;
    for(NSDictionary* eventDict in events){
        if(![eventDict isKindOfClass:NSDictionary.class]){
            continue;
        }
        NSString* targetType = @"ARRIVAL";
        if(event.departure){
            targetType = @"DEPARTURE";
        }
        NSString* eventType = [eventDict db_stringForKey:@"type"];
        if([eventType isEqualToString:targetType]){
            NSDictionary* station = [eventDict db_dictForKey:@"station"];
            NSString* evaNumber = [station db_stringForKey:@"evaNumber"];
            if(evaNumber.longLongValue == targetEva.longLongValue){//some evas have a "0" at the beginning
                return [eventDict db_stringForKey:@"timeSchedule"];
            }
        }
    }
    return timeScheduleAtOurEva;
}

- (void) getJourneyForId:(NSString*)journeyID event:(Event*)event
                  completionBlock:(void (^)(MBTrainJourney * _Nullable journey))completion
{
    //gets a journey and compares it to the event to check if they match
    [self getJourneyDictForId:journeyID completionBlock:^(NSDictionary * _Nullable dict) {

        //test-fixed-journey-id
        /*MBTrainJourney* trainJourney = [[MBTrainJourney alloc] initWithDict:dict];
        completion(trainJourney);
        return;
        */
        if(!dict){
            completion(nil);
        } else {
            //find the evaNumber (does this journey include the current station?)
            NSString* targetEva = event.stop.evaNumber;
            NSArray* events = [dict db_arrayForKey:@"events"];
            NSString * timeScheduleAtOurEva = [self findEvent:event withTargetEva:targetEva inEvents:events];
            if(timeScheduleAtOurEva){
                //NSLog(@"simulate wrong date here..."); completion(nil,YES); return;
                
                //this train stops at our station and has a planed time
                NSDate* dateIRIS = [NSDate dateWithTimeIntervalSince1970:event.timestamp];
                NSDate* dateJourney = [self.dateFormatter dateFromString:timeScheduleAtOurEva];
                MBTrainJourney* trainJourney = [[MBTrainJourney alloc] initWithDict:dict];
                if([dateIRIS isEqualToDate:dateJourney] || DEBUG_MODE){
                    //YES, we found it!
                    event.journeyID = journeyID;
                    completion(trainJourney);
                    return;
                } else {
                    NSLog(@"wrong dates:\nIRIS %@\nRIS:Journey: %@",dateIRIS,dateJourney);
                    trainJourney.dateMismatch = true;
                    completion(trainJourney);
                    return;
                }
            } else {
                NSLog(@"ERROR: target EvaNumber not found in segments!");
                completion(nil);
            }
        }
    }];
}

- (void)getJourneyDictForId:(NSString*)journeyID
         completionBlock:(void (^)(NSDictionary * _Nullable dict))completion{
    [self.sessionManager GET:[NSString stringWithFormat:@"%@/eventbased/%@",self.baseUrl,journeyID]
                  parameters:nil
                     headers:nil
                    progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionTask *operation, id responseObject) {
        if([responseObject isKindOfClass:NSDictionary.class]){
            NSDictionary* dict = responseObject;
            
            if(DEBUG_MODE){
                NSLog(@"NOTE: DEBUG_MODE IS ENABLED! USING STATIC TEST DATA FROM ANOTHER JOURNEY!");
                dict = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"eventjourney" ofType:@"json"]] options:0 error:nil];
            }
            
            completion(dict);
        } else {
            completion(nil);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error %@", error);
        completion(nil);
    }];
}

//external api to get or refresh a journey with a known journeyID
- (void)loadJourneyForId:(NSString*)journeyID
         completionBlock:(void (^)(MBTrainJourney * _Nullable journey))completion{
    [self getJourneyDictForId:journeyID completionBlock:^(NSDictionary * _Nullable dict) {
        if(dict){
            MBTrainJourney* trainJourney = [[MBTrainJourney alloc] initWithDict:dict];
            completion(trainJourney);
        } else {
            completion(nil);
        }
    }];
}
@end
