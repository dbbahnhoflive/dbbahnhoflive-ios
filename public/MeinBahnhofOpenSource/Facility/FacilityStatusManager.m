// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "FacilityStatusManager.h"
#import "AppDelegate.h"
#import "MBUIViewController.h"
#import "MBStationSearchViewController.h"
#import "MBRootContainerViewController.h"
//#import <Firebase/Firebase.h>
#import "MBTutorialManager.h"
#import "MBStationNavigationViewController.h"
#import "Constants.h"

@interface FacilityStatusManager()

@property(nonatomic,strong) NSMutableSet* storedFavoriteEquipments;
@property(nonatomic,strong) NSMutableSet* enabledEquipmentsForPush;
@property(nonatomic,strong) NSMutableDictionary* stationNameForStationnumber;
@property(nonatomic) BOOL globalPush;

@property(nonatomic,strong) UIAlertController* lastPushAlertView;

@end

NSString * const kFacilityStatusBaseUrl = @"https://apis.deutschebahn.com/db-api-marketplace/apis/fasta/v2/";


@implementation FacilityStatusManager

+ (instancetype)client
{
    static FacilityStatusManager *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *baseUrl = [NSURL URLWithString:kFacilityStatusBaseUrl];
        sharedClient = [[self alloc] initWithBaseURL:baseUrl];
        
        [sharedClient.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [sharedClient.requestSerializer setValue:[Constants dbFastaKey] forHTTPHeaderField:@"db-api-key"];
        [sharedClient.requestSerializer setValue:[Constants dbFastaClient] forHTTPHeaderField:@"db-client-id"];

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
            NSPredicate *filteredByElevator = [NSPredicate predicateWithFormat:@"type == %d", ELEVATOR];
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
            successBlock(finalFacilities);
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


#pragma mark handling of push and favorites

-(void)restoreSettings
{
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];

    if([def objectForKey:@"facility_globalPush"]){
        self.globalPush = [def boolForKey:@"facility_globalPush"];
        self.storedFavoriteEquipments = [[NSMutableSet alloc] initWithArray:[def objectForKey:@"facility_storedFavoriteEquipments"]];
        self.enabledEquipmentsForPush = [[NSMutableSet alloc] initWithArray:[def objectForKey:@"facility_enabledEquipmentsForPush"]];
        self.stationNameForStationnumber = [[def objectForKey:@"facility_stationNameForStationnumber"] mutableCopy];
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
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
    
    [def setBool:self.globalPush forKey:@"facility_globalPush"];
    [def setObject:[self.storedFavoriteEquipments allObjects] forKey:@"facility_storedFavoriteEquipments"];
    [def setObject:[self.enabledEquipmentsForPush allObjects] forKey:@"facility_enabledEquipmentsForPush"];
    [def setObject:self.stationNameForStationnumber forKey:@"facility_stationNameForStationnumber"];
    
    [def synchronize];
}

-(void)disablePushForFacility:(NSString*)equipmentNumber
{
    [self.enabledEquipmentsForPush removeObject:equipmentNumber];
    if(self.globalPush){
        [self unsubscribeForEquipment:equipmentNumber];
    }//else: should already be unsubscribed!
    [self storeSettings];
}

-(void)enablePushForFacility:(NSString*)equipmentNumber stationNumber:(NSString*)stationNumber stationName:(NSString*)stationName
{
    if(stationName == nil){
        stationName = [self stationNameForStationNumber:stationNumber];
        if(!stationName){
            stationName = @"";
        }
    }
    
    [[MBTutorialManager singleton] markTutorialAsObsolete:MBTutorialViewType_D1_Aufzuege];
    
    // NSLog(@"enable push for %@ in %@,%@",equipmentNumber,stationNumber,stationName);
    [self setGlobalPushActive:YES];
    [self.stationNameForStationnumber setObject:stationName forKey:stationNumber];
    [self.enabledEquipmentsForPush addObject:equipmentNumber];
    [self.storedFavoriteEquipments addObject:equipmentNumber];
    [self subscribeForEquipment:equipmentNumber];
    [self storeSettings];
}
 
-(void)setGlobalPushActive:(BOOL)active
{
    BOOL changed = self.globalPush != active;
    self.globalPush = active;
    if(changed){
        if(active){
            for(NSString* equipment in self.enabledEquipmentsForPush){
                [self subscribeForEquipment:equipment];
            }
        } else {
            for(NSString* equipment in self.enabledEquipmentsForPush){
                [self unsubscribeForEquipment:equipment];
            }
            [self.enabledEquipmentsForPush removeAllObjects];
        }
    }
    [self storeSettings];
    
    if(changed){
        [[NSNotificationCenter defaultCenter] postNotificationName:kFacilityStatusManagerGlobalPushChangedNotification object:nil userInfo:nil];
    }
}
 
-(BOOL)isGlobalPushActive
{
    return self.globalPush;
}

 -(BOOL)isPushActiveForFacility:(NSString*)equipmentNumber
{
    return [self.enabledEquipmentsForPush containsObject:equipmentNumber];
}
-(BOOL)isFavoriteFacility:(NSString*)equipmentNumber
{
   return [self.storedFavoriteEquipments containsObject:equipmentNumber];
}

-(void)removeFromFavorites:(NSString*)equipmentNumber
{
    if([self.enabledEquipmentsForPush containsObject:equipmentNumber]){
        [self.enabledEquipmentsForPush removeObject:equipmentNumber];
        if(self.globalPush){
            [self unsubscribeForEquipment:equipmentNumber];
        }
    }
    [self.storedFavoriteEquipments removeObject:equipmentNumber];
    
    [self storeSettings];
}
 
-(NSSet*)storedFavorites
{
    return [self.storedFavoriteEquipments copy];
}

-(void)removeAll{
    [self.enabledEquipmentsForPush removeAllObjects];
    [self.storedFavoriteEquipments removeAllObjects];
    [self storeSettings];
}

#pragma mark firebase

-(void)subscribeForEquipment:(NSString*)equipmentNumber
 {
    //NSLog(@"subscribe to firebase topic %@",equipmentNumber);
    //FIRMessaging* messaging = [FIRMessaging messaging];
    //[messaging subscribeToTopic:[NSString stringWithFormat:@"/topics/F%@",equipmentNumber]];
}
 
-(void)unsubscribeForEquipment:(NSString*)equipmentNumber
{
    //NSLog(@"unsubscribe from firebase topic %@",equipmentNumber);
    //FIRMessaging* messaging = [FIRMessaging messaging];
    //[messaging unsubscribeFromTopic:[NSString stringWithFormat:@"/topics/F%@",equipmentNumber]];
}


-(NSDictionary*)propertiesFromPushData:(NSDictionary*)userInfo
{
    NSString* properties = [userInfo objectForKey:@"properties"];
    
    if(![properties isKindOfClass:[NSString class]]){
        // NSLog(@"failure, expected string for key properties in userInfo %@",userInfo);
        return @{};
    }
    //json is encoded in a string:
    
    NSError *JSONConversionError;
    NSDictionary* propertiesDict = [NSJSONSerialization JSONObjectWithData:[properties dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&JSONConversionError];
    
    if (JSONConversionError) {
        // NSLog(@"JSONConversionError %@", JSONConversionError);
    }
    
    return propertiesDict;
}

-(void)handleRemoteNotification:(NSDictionary *)userInfo{
    NSDictionary* propertiesDict = [self propertiesFromPushData:userInfo];
    
    if (!propertiesDict) {
        // NSLog(@"propertiesDict is nil");
        return;
    }
    
    NSNumber* facilityNumber = [propertiesDict objectForKey:@"facilityEquipmentNumber"];
    if(!facilityNumber){
        // NSLog(@"failure, missing facilityEquipmentNumber in userInfo %@",userInfo);
        return;
    }
    if(![self isGlobalPushActive]){
        // NSLog(@"global push is not active, ignore push");
        return;
    } else if([self isPushActiveForFacility:facilityNumber.description]){
        // NSLog(@"got push for a registered facility");
    } else {
        // NSLog(@"got push for an unregistered facility! unsubscribe it and ignore push");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self unsubscribeForEquipment:facilityNumber.description];
        });
        return;
    }
    
    //now fetch values and check data
    NSString* stationName = [propertiesDict objectForKey:@"stationName"];
    NSNumber* stationNumber = [propertiesDict objectForKey:@"stationNumber"];
    NSString* description = [propertiesDict objectForKey:@"facilityDescription"];
    NSString* type = [propertiesDict objectForKey:@"facilityType"];
    NSString* state = [propertiesDict objectForKey:@"facilityState"];
    if(!stationName || stationName == (id)[NSNull null]){
        // NSLog(@"failure, missing stationName in userInfo %@",userInfo);
        return;
    }
    
    if (description == (id)[NSNull null]) {
        description = @"";
        //NSLog(@"failure, missing facilityDescription in userInfo %@",userInfo);
        //return;
    }
    
    if(state == (id)[NSNull null]){
        // NSLog(@"failure, missing state in userInfo %@",userInfo);
        return;
    }
    if(!stationNumber){
        // NSLog(@"failure, missing stationNumber in userInfo %@",userInfo);
        return;
    }
    
    BOOL isActive = [state isEqualToString:@"ACTIVE"];
    //update data model
    // NSLog(@"update facility %@ with state %@",facilityNumber,state);
    AppDelegate* app = (AppDelegate*) [UIApplication sharedApplication].delegate;
    MBStationSearchViewController* vc = (MBStationSearchViewController*) app.viewController;
    NSArray* facilities = vc.stationMapController.station.facilityStatusPOIs;
    BOOL needsUIUpdate = NO;
    for(FacilityStatus* status in facilities){
        if(status.equipmentNumber.longLongValue == facilityNumber.longLongValue){
            enum State newState = isActive ? ACTIVE : INACTIVE;
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
    
    NSString *facilityType = [type isEqualToString:@"ELEVATOR"] ? @"Aufzug" : @"Fahrtreppe";
    
    //construct message
    NSString* message = [NSString stringWithFormat:@"Statusänderung: %@\n%@ zu %@ %@", stationName, facilityType, description, (isActive ? @"in Betrieb" : @"außer Betrieb")];
    
    if (!description) {
        message = [NSString stringWithFormat:@"Statusänderung: %@\n%@ %@", stationName, facilityType, (isActive ? @"in Betrieb" : @"außer Betrieb")];
    }
    

    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        // NSLog(@"Notification received by running app");
        if(self.lastPushAlertView){
            [self.lastPushAlertView dismissViewControllerAnimated:NO completion:nil];
        }
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Bahnhof live" message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Öffnen" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self openFacilityStatusForStationNumber:stationNumber stationTitle:stationName];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Schließen" style:UIAlertActionStyleCancel handler:nil]];
        UIViewController* vc = app.window.rootViewController;
        if([vc isKindOfClass:[UINavigationController class]]){
            vc = ((UINavigationController*)vc).visibleViewController;
        }
        [vc presentViewController:alert animated:YES completion:nil];
        self.lastPushAlertView = alert;
    } else {
        // NSLog(@"App received Notification in background, create local notif and present it");
        /*//TODO code needs to be refactored to UNNotificationFramework but currently push for facilities it not used
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = message;
        notification.userInfo = userInfo;
        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
         */
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
        // NSLog(@"we are in this station!");
        [vc showFacilityForStation];
    } else {
        // NSLog(@"must open another station OR did display search controller!");
        [app.navigationController popToRootViewControllerAnimated:NO];
        MBStationSearchViewController* vc = (MBStationSearchViewController*) app.viewController;
        [vc openStationAndShowFacility:@{ @"title":stationTitle, @"id": [NSNumber numberWithLongLong:[stationNumber longLongValue]] }];
    }
}

-(void)openFacilityStatusWithLocalNotification:(NSDictionary *)userInfo
{
    NSDictionary* propertiesDict = [self propertiesFromPushData:userInfo];
    [self openFacilityStatusForStationNumber:[propertiesDict objectForKey:@"stationNumber"] stationTitle:[propertiesDict objectForKey:@"stationName"]];
}

@end
