// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "FacilityStatusManager.h"
#import "AppDelegate.h"
#import "MBUIViewController.h"
#import "MBStationSearchViewController.h"
#import "MBRootContainerViewController.h"
#import "MBTutorialManager.h"
#import "MBStationNavigationViewController.h"
#import "Constants.h"
#import "MBPushManager.h"

@import UserNotifications;

@interface FacilityStatusManager()

@property(nonatomic,strong) NSMutableSet* storedFavoriteEquipments;
@property(nonatomic,strong) NSMutableSet* enabledEquipmentsForPush;
@property(nonatomic,strong) NSMutableDictionary* stationNameForStationnumber;
@property(nonatomic) BOOL globalPush;

@property(nonatomic,strong) UIAlertController* lastPushAlertView;

@end

NSString * const kFacilityStatusBaseUrl = @"https://apis.deutschebahn.com/db-api-marketplace/apis/fasta/v2/";

#define SETTING_FACILITY_GLOBAL_PUSH @"facility_globalPush"
#define SETTING_FACILITY_STORED_EQUIP @"facility_storedFavoriteEquipments"
#define SETTING_FACILITY_STORED_EQUIP_PUSH @"facility_enabledEquipmentsForPush_v2"
#define SETTING_FACILITY_STORED_STATIONNAMES @"facility_stationNameForStationnumber"

@implementation FacilityStatusManager

+ (instancetype)client
{
    static FacilityStatusManager *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *baseUrl = [NSURL URLWithString:kFacilityStatusBaseUrl];
        sharedClient = [[self alloc] initWithBaseURL:baseUrl];
        
        [sharedClient.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [sharedClient.requestSerializer setValue:[Constants dbFastaKey] forHTTPHeaderField:@"DB-Api-Key"];
        [sharedClient.requestSerializer setValue:[Constants dbFastaClient] forHTTPHeaderField:@"DB-Client-Id"];

        [sharedClient restoreSettings];
        
    });
    return sharedClient;
}

- (NSURLSessionTask *)requestFacilityStatus:(NSNumber*)stationId
                                 success:(void (^)(NSArray<FacilityStatus*> *facilityStatusItems))successBlock
                                 failureBlock:(void (^)(NSError *bhfError))failure
{
    NSString *endPoint = [NSString stringWithFormat:@"stations/%@", stationId];
    // NSLog(@"endPoint %@",endPoint);

    return [self GET:endPoint parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        //
    } success:^(NSURLSessionTask *operation, id responseObject) {
        NSError *error;
        NSArray *facilityStatusItems = [MTLJSONAdapter modelsOfClass:FacilityStatus.class
                                                       fromJSONArray:[responseObject objectForKey:@"facilities"]
                                                               error:&error];
        
        if (facilityStatusItems && facilityStatusItems.count > 0) {
            NSPredicate *filteredByElevator = [NSPredicate predicateWithFormat:@"type == %d", FacilityTypeElevator];
            facilityStatusItems = [facilityStatusItems filteredArrayUsingPredicate:filteredByElevator];
            
        }
        
        NSMutableArray* finalFacilities = [NSMutableArray arrayWithCapacity:20];
        for(FacilityStatus* status in facilityStatusItems){
            if(status.geoCoordinateX == nil || status.geoCoordinateY == nil || (status.shortDescription && [status.shortDescription compare:@"Nicht Reisendenrelevant" options:NSCaseInsensitiveSearch] == NSOrderedSame)){
                
            } else {
                [finalFacilities addObject:status];
            }
        }
        
        if (!error) {
            //sort items by their state but keep the server sorting for same state
            NSMutableArray* disabledFacility = [NSMutableArray arrayWithCapacity:5];
            NSMutableArray* unknownFacility = [NSMutableArray arrayWithCapacity:5];
            NSMutableArray* activeFacility = [NSMutableArray arrayWithCapacity:finalFacilities.count];
            for(FacilityStatus* f in finalFacilities){
                if(f.state == FacilityStateInactive){
                    [disabledFacility addObject:f];
                } else if(f.state == FacilityStateUnknown){
                    [disabledFacility addObject:f];
                } else {
                    [activeFacility addObject:f];
                }
            }
            NSMutableArray* sortedList = [NSMutableArray arrayWithCapacity:finalFacilities.count];
            [sortedList addObjectsFromArray:disabledFacility];
            [sortedList addObjectsFromArray:unknownFacility];
            [sortedList addObjectsFromArray:activeFacility];

            successBlock(sortedList);
        } else {        
            failure([error copy]);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        //NSData* data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        //NSLog(@"data: %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        failure(error);
    }];
    
}

- (NSURLSessionTask *)requestFacilityStatusForFacilities:(NSSet<NSString*>*)equipmentNumbers
                                                 success:(void (^)(NSArray<FacilityStatus*> *facilityStatusItems))success
                                            failureBlock:(void (^)(NSError *bhfError))failure
{
    //this is the FASTA implementation which can fetch multiple equipments status in a single request
    if(equipmentNumbers.count == 0){
        success(@[]);
        return nil;
    }
    
    
    NSDictionary *parameters = nil;
    
    NSMutableString* endPoint = [[NSMutableString alloc] initWithString:@"facilities?equipmentnumbers="];
    for(NSString* equipment in equipmentNumbers){
        [endPoint appendString:equipment];
        [endPoint appendString:@","];
    }
    // NSLog(@"endPoint %@",endPoint);
    
    return [self GET:endPoint parameters:parameters headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        //
    } success:^(NSURLSessionTask *operation, id responseObject) {
        NSError *error;
        NSArray *facilityStatusItems = [MTLJSONAdapter modelsOfClass:FacilityStatus.class fromJSONArray:responseObject error:&error];
        
        if (facilityStatusItems && facilityStatusItems.count > 0) {
            NSPredicate *filteredByElevator = [NSPredicate predicateWithFormat:@"type == %d", 1];
            facilityStatusItems = [facilityStatusItems filteredArrayUsingPredicate:filteredByElevator];
        }
        
        NSMutableArray* finalFacilities = [NSMutableArray arrayWithCapacity:20];
        for(FacilityStatus* status in facilityStatusItems){
            if(status.geoCoordinateX == nil || status.geoCoordinateY == nil){
                
            } else {
                [finalFacilities addObject:status];
            }
        }
        
        if (!error) {
            success(finalFacilities);
        } else {
            failure([error copy]);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        //NSData* data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        //NSLog(@"data: %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        failure(error);
    }];
    
}

-(UIAlertController *)alertForPushNotActive{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Hinweis" message:@"Mitteilungen für diese App müssen in den Systemeinstellungen zugelassen werden." preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Abbrechen" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Einstellungen" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:^(BOOL success) {
        }];
    }]];
    return alert;
}


#pragma mark handling of push and favorites

-(void)restoreSettings
{
    NSUserDefaults* def = NSUserDefaults.standardUserDefaults;

    if([def objectForKey:SETTING_FACILITY_GLOBAL_PUSH]){
        self.globalPush = [def boolForKey:SETTING_FACILITY_GLOBAL_PUSH];
        self.storedFavoriteEquipments = [[NSMutableSet alloc] initWithArray:[def objectForKey:SETTING_FACILITY_STORED_EQUIP]];
        self.enabledEquipmentsForPush = [[NSMutableSet alloc] initWithArray:[def objectForKey:SETTING_FACILITY_STORED_EQUIP_PUSH]];
        self.stationNameForStationnumber = [[def objectForKey:SETTING_FACILITY_STORED_STATIONNAMES] mutableCopy];
    } else {
        //use defaults
        self.globalPush = YES;
        self.storedFavoriteEquipments = [NSMutableSet setWithCapacity:10];
        self.enabledEquipmentsForPush = [NSMutableSet setWithCapacity:10];
        self.stationNameForStationnumber = [NSMutableDictionary dictionaryWithCapacity:10];
    }
}

-(NSString*)stationNameForStationNumber:(NSString*)stationNumber
{
    return self.stationNameForStationnumber[stationNumber];
}

-(void)storeSettings
{
    NSUserDefaults* def = NSUserDefaults.standardUserDefaults;
    
    [def setBool:self.globalPush forKey:SETTING_FACILITY_GLOBAL_PUSH];
    [def setObject:[self.storedFavoriteEquipments allObjects] forKey:SETTING_FACILITY_STORED_EQUIP];
    [def setObject:[self.enabledEquipmentsForPush allObjects] forKey:SETTING_FACILITY_STORED_EQUIP_PUSH];
    [def setObject:self.stationNameForStationnumber forKey:SETTING_FACILITY_STORED_STATIONNAMES];
    
}

-(void)disablePushForFacility:(NSString*)equipmentNumber completion:(void (^)(BOOL success,NSError *))completion
{
    [self.enabledEquipmentsForPush removeObject:equipmentNumber];
    [self unsubscribeForEquipment:equipmentNumber completion:completion];
    [self storeSettings];
}

-(void)enablePushForFacility:(NSString*)equipmentNumber completion:(void (^)(BOOL success,NSError *))completion
{
    // NSLog(@"enable push for %@ in %@,%@",equipmentNumber,stationNumber,stationName);
    [self.enabledEquipmentsForPush addObject:equipmentNumber];
    [self subscribeForEquipment:equipmentNumber completion:completion];
    [self storeSettings];
}
 
-(void)setGlobalPushActive:(BOOL)active completion:(void (^)(NSError *))completion
{
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    __block NSError* gotError = nil;
    BOOL changed = self.globalPush != active;
    if(changed){
        if(active){
            self.globalPush = active;
            //we don't turn global push off when it's disabled until the end of this method
        }
        if(active){
            for(NSString* equipment in self.enabledEquipmentsForPush){
                dispatch_group_enter(group);
                [self subscribeForEquipment:equipment completion:^(BOOL success,NSError * error) {
                    if(error){
                        gotError = error;
                    }
                    dispatch_group_leave(group);
                }];
            }
        } else {
            for(NSString* equipment in self.enabledEquipmentsForPush){
                dispatch_group_enter(group);
                [self unsubscribeForEquipment:equipment completion:^(BOOL success,NSError * error) {
                    if(error){
                        gotError = error;
                    }
                    dispatch_group_leave(group);
                }];
            }
        }
        self.globalPush = active;
        [self storeSettings];
    }
    dispatch_group_leave(group);
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        completion(gotError);
    });
}
 
-(BOOL)isGlobalPushActive
{
    return self.globalPush;
}

-(BOOL)isSystemPushActive{
    return AppDelegate.appDelegate.hasEnabledPushServices;
}

-(BOOL)isPushActiveForAtLeastOneFacility{
    return self.enabledEquipmentsForPush.count > 0;
}

 -(BOOL)isPushActiveForFacility:(NSString*)equipmentNumber
{
    return [self.enabledEquipmentsForPush containsObject:equipmentNumber];
}
-(BOOL)isFavoriteFacility:(NSString*)equipmentNumber
{
   return [self.storedFavoriteEquipments containsObject:equipmentNumber];
}

-(void)addToFavorites:(NSString*)equipmentNumber stationNumber:(NSString*)stationNumber stationName:(NSString*)stationName{
    if(stationName == nil){
        stationName = [self stationNameForStationNumber:stationNumber];
        if(!stationName){
            stationName = @"";
        }
    }
    
    [[MBTutorialManager singleton] markTutorialAsObsolete:MBTutorialViewType_D1_Aufzuege];
    [self.stationNameForStationnumber setObject:stationName forKey:stationNumber];
    if(self.storedFavoriteEquipments.count >= 100){
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Hinweis" message:@"Es können nur maximal 100 Aufzüge in der Merkliste gespeichert werden." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Abbrechen" style:UIAlertActionStyleCancel handler:nil]];
        AppDelegate* app = (AppDelegate*) UIApplication.sharedApplication.delegate;
        [app.navigationController presentViewController:alert animated:true completion:nil];
    } else {
        [self.storedFavoriteEquipments addObject:equipmentNumber];
    }
    [self storeSettings];
}

-(void)removeFromFavorites:(NSString*)equipmentNumber
{
    if([self.enabledEquipmentsForPush containsObject:equipmentNumber]){
        [self.enabledEquipmentsForPush removeObject:equipmentNumber];
        [self unsubscribeForEquipment:equipmentNumber completion:nil];
    }
    [self.storedFavoriteEquipments removeObject:equipmentNumber];
    
    [self storeSettings];
}
 
-(NSSet<NSString*>*)storedFavorites
{
    return [self.storedFavoriteEquipments copy];
}

-(void)removeAll{
    for(NSString* equipment in self.enabledEquipmentsForPush){
        [self unsubscribeForEquipment:equipment completion:nil];
    }
    
    [self.enabledEquipmentsForPush removeAllObjects];
    [self.storedFavoriteEquipments removeAllObjects];
    [self storeSettings];
}

#pragma mark firebase

-(void)subscribeForEquipment:(NSString*)equipmentNumber completion:(void (^)(BOOL success,NSError *))completion
 {
     if(Constants.usePushServices && self.globalPush){
         NSLog(@"subscribe to firebase topic %@",equipmentNumber);
          //equipmentNumber = @"10007917";
          [MBPushManager.client subscribeToTopic:[NSString stringWithFormat:@"%@%@",PUSH_FACILITY_TOPIC_PREFIX,equipmentNumber] completion:^(NSError * _Nullable error) {
              NSLog(@"subscribeToTopic %@: %@",equipmentNumber,error);
              if(completion){
                  completion(true,error);
              }
          }];//@"/topics/F%@" ??
     } else {
         if(completion){
             completion(false,nil);
         }
     }
}
 
-(void)unsubscribeForEquipment:(NSString*)equipmentNumber completion:(void (^)(BOOL success,NSError *))completion
{
    if(Constants.usePushServices && self.globalPush){
        NSLog(@"unsubscribe from firebase topic %@",equipmentNumber);
        //equipmentNumber = @"10007917";
        [MBPushManager.client unsubscribeFromTopic:[NSString stringWithFormat:@"%@%@",PUSH_FACILITY_TOPIC_PREFIX,equipmentNumber] completion:^(NSError * _Nullable error) {
            NSLog(@"unsubscribeFromTopic %@: %@",equipmentNumber,error);
            if(completion){
                completion(true,error);
            }
        }];
    } else {
        if(completion){
            completion(false,nil);
        }
    }
}



-(void)handleRemoteNotification:(NSDictionary *)userInfo{
    NSDictionary* propertiesDict = userInfo;
    
    if (!propertiesDict) {
        // NSLog(@"propertiesDict is nil");
        return;
    }
    
    NSNumber* facilityNumber = [propertiesDict objectForKey:@"facilityEquipmentNumber"];
    if(!facilityNumber){
        NSLog(@"failure, missing facilityEquipmentNumber in userInfo %@",userInfo);
        return;
    }
    if(![self isGlobalPushActive]){
        NSLog(@"global push is not active, ignore push");
        return;
    } else if([self isPushActiveForFacility:facilityNumber.description]){
        NSLog(@"got push for a registered facility");
    } else {
        NSLog(@"got push for an unregistered facility! unsubscribe it and ignore push");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self unsubscribeForEquipment:facilityNumber.description completion:nil];
        });
        return;
    }
    
    //now fetch values and check data
    NSString* stationName = [propertiesDict objectForKey:@"stationName"];
    NSNumber* stationNumber = [propertiesDict objectForKey:@"stationNumber"];
    NSString* state = [propertiesDict objectForKey:@"facilityState"];
    NSString* message = [propertiesDict objectForKey:@"message"];
    if(!message){
        NSLog(@"failure, missing message in userInfo %@",userInfo);
        return;
    }
    if(!stationName || stationName == (id)[NSNull null]){
        NSLog(@"failure, missing stationName in userInfo %@",userInfo);
        return;
    }
    
    if(state == (id)[NSNull null]){
        NSLog(@"failure, missing state in userInfo %@",userInfo);
        return;
    }
    if(!stationNumber){
        NSLog(@"failure, missing stationNumber in userInfo %@",userInfo);
        return;
    }
    
    FacilityState newState = FacilityStateUnknown;
    if([state isEqualToString:@"ACTIVE"]){
        newState = FacilityStateActive;
    } else if([state isEqualToString:@"INACTIVE"]) {
        newState = FacilityStateInactive;
    }
    //update data model
    // NSLog(@"update facility %@ with state %@",facilityNumber,state);
    AppDelegate* app = (AppDelegate*) [UIApplication sharedApplication].delegate;
    MBStationSearchViewController* vc = (MBStationSearchViewController*) app.viewController;
    NSArray* facilities = vc.stationMapController.station.facilityStatusPOIs;
    BOOL needsUIUpdate = NO;
    for(FacilityStatus* status in facilities){
        if(status.equipmentNumber.longLongValue == facilityNumber.longLongValue){
            if(status.state != newState){
                status.state = newState;
                needsUIUpdate = YES;
            }
            break;
        }
    }
    //update UI
    if(needsUIUpdate){
        [vc.stationMapController updateFacilityUI];        
    }
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        // NSLog(@"Notification received by running app");
        if(self.lastPushAlertView){
            [self.lastPushAlertView dismissViewControllerAnimated:NO completion:nil];
        }
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Bahnhof live" message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Schließen" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            self.lastPushAlertView = nil;
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Öffnen" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.lastPushAlertView = nil;
            [self openFacilityStatusForStationNumber:stationNumber stationTitle:stationName];
        }]];
        UIViewController* vc = app.window.rootViewController;
        if([vc isKindOfClass:[UINavigationController class]]){
            vc = ((UINavigationController*)vc).visibleViewController;
        }
        [vc presentViewController:alert animated:YES completion:nil];
        self.lastPushAlertView = alert;
    } else {
        NSLog(@"App received Notification in background");
    }
}


-(void)openFacilityStatusForStationNumber:(NSNumber*)stationNumber stationTitle:(NSString*)stationTitle
{
    // NSLog(@"openFacilityStatusForStationNumber: %@ stationTitle: %@",stationNumber, stationTitle);
    AppDelegate* app = (AppDelegate*) [UIApplication sharedApplication].delegate;
    // NSLog(@"selectedStation in app: %@",app.selectedStation);
    
    if([app.selectedStation.mbId longLongValue] == [stationNumber longLongValue]
       && ![app.navigationController.topViewController isKindOfClass:[MBStationSearchViewController class]]){
        //we already are in this station
        MBStationSearchViewController* vc = (MBStationSearchViewController*) app.viewController;
        [vc.stationMapController showFacilities];
    } else {
        // NSLog(@"must open another station OR did display search controller!");
        [MBRootContainerViewController.currentlyVisibleInstance goBackToSearchAnimated:false];
        MBStationSearchViewController* vc = (MBStationSearchViewController*) app.viewController;
        [vc openStationAndShowFacility:@{ @"title":stationTitle, @"id": [NSNumber numberWithLongLong:[stationNumber longLongValue]] }];
    }
}

-(void)openFacilityStatusWithLocalNotification:(NSDictionary *)userInfo
{
    NSDictionary* propertiesDict = userInfo;
    [self openFacilityStatusForStationNumber:[propertiesDict objectForKey:@"stationNumber"] stationTitle:[propertiesDict objectForKey:@"stationName"]];
}

#pragma mark Debug and test methods
-(void)removeDebugPushes{
    [self registerDebugFacilities:false];
}
-(void)registerDebugPushes{
#ifdef DEBUG
    [self.stationNameForStationnumber addEntriesFromDictionary:@{
        @"1071" : @"Berlin Hbf",
        @"1289" : @"Dortmund Hbf",
        @"1343" : @"Dresden Hbf",
        @"1401" : @"Düsseldorf Hbf",
        @"1866" : @"Frankfurt(Main)Hbf",
        @"2514" : @"Hamburg Hbf",
        @"2517" : @"Hamburg-Altona",
        @"3174" : @"Kiel Hbf",
        @"3229" : @"Hamburg Klein Flottbek",
        @"3320" : @"Köln Hbf",
        @"3378" : @"Hamburg Kornweg(Klein Borstel)",
        @"4234" : @"München Hbf",
        @"4809" : @"Berlin Ostkreuz",
        @"4859" : @"Berlin Südkreuz",
        @"530"  : @"Berlin Ostbahnhof",
        @"5451" : @"Saarbrücken Hbf",
        @"6071" : @"Stuttgart Hbf",
        @"8314" : @"Hamburg Elbbrücken",
        @"855"  : @"Bremen Hbf",
    }];
    [self registerDebugFacilities:true];
#endif
}
-(void)registerDebugFacilities:(BOOL)active{
#ifdef DEBUG
    long ids[] = {
        10490981,
        10503244,
        10500157,
        10482243,
        10500158,
        10314752,
        10561326,
        10563637,
        10561327,
        10563638,
        10499260,
        10776764,
        10499261,
        10500168,
        10499262,
        10504602,
        10449075,
        10491002,
        10569817,
        10316250,
        10060095,
        10316251,
        10316245,
        10316246,
        10316254,
        10316332,
        10804989,
        10316256,
        10316334,
        10315222,
        10315223,
        10315224,
        10464407,
        10464408,
        10315225,
        10470423,
        10122518,
        10299484,
        10315228,
        10315229,
        10028022,
        10318901,
        10408331,
        10185526,
        10409032,
        10318903,
        10804843,
        10028019,
        10801910,
        10121792,
        10015810,
        10028028,
        10020397,
        10015811,
        10779734,
        10015805,
        10015812,
        10801913,
        10015806,
        10015813,
        10315352,
        10015807,
        10801908,
        10315353,
        10801909,
        10020626,
        10315354,
        10015809,
        10315355,
        10315425,
        10020635,
        10315426,
        10020993,
        10020636,
        10448345,
        10020629,
        10020637,
        10314789,
        10309362,
        10309360,
        10378153,
        10238960,
        10085129,
        10085128,
        10085130,
        10087991,
        10378152,
        10378151,
        10378150,
        10484324,
        10484325,
        10613486,
        10097636,
        10348886,
        10500961,
        10500962,
        10500963,
        10500964,
        10014098,
        10436485,
    };
    [self.storedFavoriteEquipments removeAllObjects];
    [self.enabledEquipmentsForPush removeAllObjects];
    for(NSInteger i=0; i<(sizeof ids) / (sizeof ids[0]); i++){
        long fId = ids[i];
        
        for(NSInteger k=0; k<(sizeof ids) / (sizeof ids[0]); k++){
            long fId2 = ids[k];
            if(k != i){
                if(fId == fId2){
                    NSLog(@"ERROR: ID duplicate: %ld",fId);
                    NSAssert(false, @"duplicated id %ld",fId);
                }
            }
        }
        NSString* idString = [NSString stringWithFormat:@"%ld",fId];
        if(active){
            [self.storedFavoriteEquipments addObject:idString];
            [self enablePushForFacility:idString completion:nil];
        } else {
            [self disablePushForFacility:idString completion:nil];
        }
    }
#endif
}
-(void)validateTopics{
    NSSet* subcribedTo = MBPushManager.client.debugSubscribedTopics;
    NSSet* localList = self.enabledEquipmentsForPush;
    NSMutableSet* localListTopics = [NSMutableSet setWithCapacity:localList.count];
    for(NSString* value in localList){
        [localListTopics addObject:[NSString stringWithFormat:@"%@%@",PUSH_FACILITY_TOPIC_PREFIX,value]];
    }
    if([localListTopics isEqualToSet:subcribedTo]){
        NSLog(@"validation passed");
    } else {
        NSAssert(false, @"List in FacilityStatusManager\n%@\ndiffers from list in MBPushManager:\nvs. %@",localListTopics,subcribedTo);
    }
}


@end
