// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBTutorialManager.h"
#import "MBTutorialView.h"
#import "AppDelegate.h"
#import <UIKit/UIKit.h>
#import "FacilityStatusManager.h"

@interface MBTutorialManager()

@property(nonatomic,strong) NSArray* allTutorials;
@property(nonatomic,strong) NSMutableArray* visibleTutorials;

@end

#define DEBUG_TUTORIAL NO
#define SETTING_STATUS_DICT @"MBTUTORIAL_STATUS"
#define SETTING_USER_DISABLED_TUTORIAL @"MBTutorial.userDisabledTutorials"

@implementation MBTutorialManager

+ (instancetype)singleton
{
    static MBTutorialManager *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[self alloc] init];

        sharedClient.allTutorials = @[
                                      [MBTutorial tutorialWithIdentifier:MBTutorialViewType_00_Hub_Start title:@"DB Bahnhof live" text:@"Neues Design und neue Funktionen. Viel Spaß beim Entdecken." countdown:0],
                                      [MBTutorial tutorialWithIdentifier:MBTutorialViewType_00_Hub_Abfahrt title:@"In der Nähe" text:@"Finden Sie schnell und komfortabel Bahnhöfe und Haltestellen." countdown:4],
                                      [MBTutorial tutorialWithIdentifier:MBTutorialViewType_H1_Live title:@"Live Infos" text:@"Aktuelle Informationen zu Shops, Parkplätzen und mehr (an ausgewählten Bahnhöfen)." countdown:2],
                                      [MBTutorial tutorialWithIdentifier:MBTutorialViewType_H1_Tips title:@"Tipps & Hinweise" text:@"Unter Einstellungen können Sie Tipps & Hinweise deaktivieren." countdown:5],
                                      [MBTutorial tutorialWithIdentifier:MBTutorialViewType_H2_Departure title:@"Verbindungsdetails" text:@"Erhalten Sie alle Details zu Ihrer Verbindung, inkl. aktuellem Wagenreihungsplan." countdown:8],
                                      [MBTutorial tutorialWithIdentifier:MBTutorialViewType_H2_Platform_info title:@"Gegenüberliegende Gleise" text:@"Wählen Sie eine Verbindung aus, um weitere Gleisinformationen zu erhalten." countdown:0 ruleBlock:^BOOL(MBTutorial *t) {
                                          if(![MBTutorialManager previousAppVersionIsSmallerThan:@"3.24.0"]){
                                              //this is either a new installation or a later update (previous is <3.22.0, the version when this feature was added)
                                              return false;
                                          }
                                          if(AppDelegate.appDelegate.selectedStation.platformAccessibility.count == 0){
                                              return false;
                                          }
                                          NSString* const keyDate = @"MBTutorialViewType_H2_Platform_info_Count_Date";
                                          NSString* const keyCount = @"MBTutorialViewType_H2_Platform_info_Count";
                                          return [MBTutorialManager openCountCheckWithKeyDate:keyDate keyCount:keyCount showAgainAfterDay:5];
                                      }],
                                      [MBTutorial tutorialWithIdentifier:MBTutorialViewType_D1_ServiceStores_Details title:@"DB Services" text:@"Sie haben Fragen? Wir helfen Ihnen weiter." countdown:8],
                                      [MBTutorial tutorialWithIdentifier:MBTutorialViewType_D1_Aufzuege title:@"Merkliste erstellen" text:@"Verwalten Sie Ihre relevante Aufzüge. Ganz einfach und übersichtlich." countdown:5],
                                      [MBTutorial tutorialWithIdentifier:MBTutorialViewType_H1_FacilityPush title:@"NEU: Mitteilungen Aufzüge" text:@"Erhalten Sie eine Nachricht, wenn Ihr Aufzug defekt oder wieder in Betrieb ist." countdown:0 ruleBlock:^BOOL(MBTutorial *t) {
                                          if(![MBTutorialManager previousAppVersionIsSmallerThan:@"3.22.0"]){
                                              //this is either a new installation or a later update (previous is <3.22.0, the version when this feature was added)
                                              return false;
                                          }
                                          if(AppDelegate.appDelegate.selectedStation.facilityStatusPOIs.count == 0){
                                              return false;
                                          }
                                          NSString* const keyDate = @"MBTutorialViewType_H1_FacilityPush_Count_Date";
                                          NSString* const keyCount = @"MBTutorialViewType_H1_FacilityPush_Count";
                                          NSString* const keyDisplayCount = @"MBTutorialViewType_H1_FacilityPush_Display_Count";
                                          NSNumber* displayCount = [NSUserDefaults.standardUserDefaults objectForKey:keyDisplayCount];
                                          if(displayCount != nil){
                                              if(displayCount.integerValue >= 3){
                                                  //this message was displayed 3 times, don't show again
                                                  return false;
                                              }
                                          } else {
                                              displayCount = @0;
                                          }
                                          BOOL did5DaysPass = [MBTutorialManager openCountCheckWithKeyDate:keyDate keyCount:keyCount showAgainAfterDay:5];
                                          if(did5DaysPass){
                                              //repeat this process after 5 days...
                                              [NSUserDefaults.standardUserDefaults setObject:NSDate.date forKey:keyDate];
                                              [NSUserDefaults.standardUserDefaults setObject:@1 forKey:keyCount];
                                              [NSUserDefaults.standardUserDefaults setObject:@(displayCount.integerValue+1) forKey:keyDisplayCount];
                                              return true;
                                          }
                                          return false;
                                      }],
                                      [MBTutorial tutorialWithIdentifier:MBTutorialViewType_H1_FacilityPush title:@"NEU: Mitteilungen Aufzüge" text:@"Erhalten Sie eine Nachricht, wenn Ihr Aufzug defekt oder wieder in Betrieb ist." countdown:0 ruleBlock:^BOOL(MBTutorial *t) {
                                          if(![MBTutorialManager previousAppVersionIsSmallerThan:@"3.22.0"]){
                                              //this is either a new installation or a later update (previous is <3.22.0, the version when this feature was added)
                                              return false;
                                          }
                                          if(AppDelegate.appDelegate.selectedStation.facilityStatusPOIs.count == 0){
                                              return false;
                                          }
                                          NSString* const keyDate = @"MBTutorialViewType_H1_FacilityPush_Count_Date";
                                          NSString* const keyCount = @"MBTutorialViewType_H1_FacilityPush_Count";
                                          return [MBTutorialManager openCountCheckWithKeyDate:keyDate keyCount:keyCount showAgainAfterDay:5];
                                      }],
                                      [MBTutorial tutorialWithIdentifier:MBTutorialViewType_D1_FacilityPush title:@"NEU: Mitteilungen Aufzüge" text:@"Aktivieren Sie die Push-Mitteilungen zur Verfügbarkeit gemerkter Aufzüge." countdown:0 ruleBlock:^BOOL(MBTutorial *t){
                                          if(![MBTutorialManager previousAppVersionIsSmallerThan:@"3.22.0"]){
                                              //this is either a new installation or a later update (previous is <3.22.0, the version when this feature was added)
                                              return false;
                                          }
                                          if(FacilityStatusManager.manager.isPushActiveForAtLeastOneFacility){
                                              return false;
                                          }
                                          if(t.closedByUser){
                                              return false;
                                          }
                                          if(AppDelegate.appDelegate.selectedStation.facilityStatusPOIs.count == 0){
                                              return false;
                                          }
                                          return true;
                                      }],
                                      [MBTutorial tutorialWithIdentifier:MBTutorialViewType_Zuglauf_StationLink title:@"So wechseln Sie den Bahnhof" text:@"Wählen Sie einen Halt im Fahrtverlauf, um den Bahnhof zu wechseln." countdown:0 ruleBlock:^BOOL(MBTutorial *t){
                                          if(![MBTutorialManager previousAppVersionIsSmallerThan:@"3.22.0"]){
                                              return false;
                                          }
                                          NSString* const keyDate = @"MBTutorialViewType_Zuglauf_StationLink_Count_Date";
                                          NSString* const keyCount = @"MBTutorialViewType_Zuglauf_StationLink_Count";
                                          return [MBTutorialManager openCountCheckWithKeyDate:keyDate keyCount:keyCount showAgainAfterDay:5];
                                      }],
                                      [MBTutorial tutorialWithIdentifier:MBTutorialViewType_D1_Parking title:@"Parken am Bahnhof" text:@"Informieren Sie sich mit einem Klick über Anfahrtswege, Öffnungszeiten und Preise." countdown:5],
                                      [MBTutorial tutorialWithIdentifier:MBTutorialViewType_F3_Map title:@"Filter" text:@"Nutzen Sie den Filter, um sich für Sie relevante Inhalte anzeigen zu lassen." countdown:10],
                                      [MBTutorial tutorialWithIdentifier:MBTutorialViewType_F3_Map_Departures title:@"Abfahrtstafel am Gleis" text:@"Wählen Sie Ihr Gleis auf der Karte und Sie erhalten die Abfahrtsinfos der nächsten Züge." countdown:0],
                                      [MBTutorial tutorialWithIdentifier:MBTutorialViewType_H1_Search title:@"Neue Suchfunktion" text:@"Finden Sie gezielt Angebote, Services und Informationen an Ihrem Bahnhof." countdown:5],
                                      [MBTutorial tutorialWithIdentifier:MBTutorialViewType_H1_Coupons title:@"Rabatt Coupons" text:@"Alle Angebote finden Sie im Bereich Shoppen & Schlemmen unter Rabatt Coupons." countdown:0],

                                      
                                    ];
        [sharedClient restoreStatus];
        sharedClient.visibleTutorials = [NSMutableArray arrayWithCapacity:3];
        
    });
    return sharedClient;
}

+(BOOL)openCountCheckWithKeyDate:(NSString*)keyDate keyCount:(NSString*)keyCount showAgainAfterDay:(NSInteger)showAgainDay{
    NSUserDefaults* def = NSUserDefaults.standardUserDefaults;
    NSNumber* count = [def objectForKey:keyCount];
    NSDate* lastDate = [def objectForKey:keyDate];
    if(!count){
        //the box is displayed the first time
        [def setObject:NSDate.date forKey:keyDate];
        [def setObject:@1 forKey:keyCount];
        return true;
    }
    if([NSCalendar.currentCalendar isDateInToday:lastDate]){
        //same day, do nothing
        return false;
    } else {
        //the day has changed
        if(count.integerValue == showAgainDay){
            //increase once more, so that the counting stops
            count = @(count.integerValue+1);
            [def setObject:count forKey:keyCount];
            if(FacilityStatusManager.manager.isPushActiveForAtLeastOneFacility){
                return false;
            }
            //opened at 5 days, no facility push active, display again
            return true;
        } else if(count.integerValue > showAgainDay){
            //dont' display after 5th day of usage
            return false;
        } else {
            //<5: store new date and increase count
            count = @(count.integerValue+1);
            [def setObject:count forKey:keyCount];
            [def setObject:NSDate.date forKey:keyDate];
            return false;
        }
    }
}

+(BOOL)previousAppVersionIsSmallerThan:(NSString*)version{
    AppDelegate* app = (AppDelegate*) UIApplication.sharedApplication.delegate;
    NSString* previousVersion = app.previousAppVersion;
    if(previousVersion != nil && ([previousVersion compare:version options:NSNumericSearch] == NSOrderedAscending)){
        return true;
    }
    return false;
}

-(void)hideTutorials{
    MBTutorialView* view = nil;
    while((view = self.visibleTutorials.firstObject)){
        [view removeFromSuperview];
        //hiding visible tutorial is counted as "user ignored", so we reset the counters
        view.tutorial.currentCount = view.tutorial.countdown;
        if(DEBUG_TUTORIAL){
            // NSLog(@"tutorial ignored %lu",(unsigned long)view.tutorial.identifier);
        }
        [self removeTutorial:view.tutorial];
    }
    [self.visibleTutorials removeAllObjects];
    [self storeStatus];
}

-(void)userClosedTutorial:(MBTutorial *)tutorial{
    if(DEBUG_TUTORIAL){
        // NSLog(@"tutorial closed %lu",(unsigned long)tutorial.identifier);
    }
    tutorial.closedByUser = YES;
    [self storeStatus];
    [self removeTutorial:tutorial];
}

-(void)markTutorialAsObsolete:(MBTutorialViewType)type{
    MBTutorial* tutorial = [self tutorialForType:type];
    if(DEBUG_TUTORIAL){
        // NSLog(@"tutorial obsolete %lu",(unsigned long)tutorial.identifier);
    }
    tutorial.markedAsAbsolete = YES;
    [self storeStatus];
    [self removeTutorial:tutorial];
}

-(void)removeTutorial:(MBTutorial*)tutorial{
    MBTutorialView* viewToRemove = nil;
    for(MBTutorialView* view in self.visibleTutorials){
        if(view.tutorial == tutorial){
            viewToRemove = view;
            break;
        }
    }
    if(viewToRemove){
        [viewToRemove removeFromSuperview];
        [self.visibleTutorials removeObject:viewToRemove];
    } else {
        if(DEBUG_TUTORIAL){
            // NSLog(@"WARNING: tutorial not found for remove!");
        }
    }
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

-(void)storeStatus{
    //store fields closedByUser/currentCount for each type
    NSMutableArray* status = [NSMutableArray arrayWithCapacity:self.allTutorials.count];
    for(MBTutorial* tutorial in self.allTutorials){
        NSDictionary* tutStatus = @{ @"identifier":@(tutorial.identifier), @"closedByUser":@(tutorial.closedByUser), @"markedAsAbsolete":@(tutorial.markedAsAbsolete), @"currentCount":@(tutorial.currentCount) };
        [status addObject:tutStatus];
    }
    if(DEBUG_TUTORIAL){
        // NSLog(@"tutorial store status %@",status);
    }
    NSUserDefaults* def = NSUserDefaults.standardUserDefaults;
    [def setObject:status forKey:SETTING_STATUS_DICT];
}
-(void)restoreStatus{
    NSUserDefaults* def = NSUserDefaults.standardUserDefaults;
    NSArray* status = [def objectForKey:SETTING_STATUS_DICT];
    if(status){
        for(NSDictionary* tutStatus in status){
            MBTutorialViewType type = [tutStatus[@"identifier"] intValue];
            MBTutorial* tutorial = [self tutorialForType:type];
            tutorial.closedByUser = [tutStatus[@"closedByUser"] boolValue];
            tutorial.currentCount = [tutStatus[@"currentCount"] integerValue];
            tutorial.markedAsAbsolete = [tutStatus[@"markedAsAbsolete"] boolValue];
            // NSLog(@"tutorial restore %lu, %d, %ld",(unsigned long)tutorial.identifier,tutorial.closedByUser,(long)tutorial.currentCount);
        }
    }
    _userDisabledTutorials = [def boolForKey:SETTING_USER_DISABLED_TUTORIAL];
}

-(MBTutorial*)tutorialForType:(MBTutorialViewType)type{
    for(MBTutorial* tutorial in self.allTutorials){
        if(tutorial.identifier == type){
            return tutorial;
        }
    }
    return nil;
}

-(void)setUserDisabledTutorials:(BOOL)userDisabledTutorials{
    _userDisabledTutorials = userDisabledTutorials;
    NSUserDefaults* def = NSUserDefaults.standardUserDefaults;
    [def setBool:userDisabledTutorials forKey:SETTING_USER_DISABLED_TUTORIAL];
}
-(BOOL)userDidCloseAllTutorials{
    for(MBTutorial* tutorial in self.allTutorials){
        if(!tutorial.closedByUser){
            return NO;
        }
    }
    return YES;
}


-(BOOL)displayTutorialIfNecessary:(MBTutorialViewType)type{
    return [self displayTutorialIfNecessary:type withOffset:0];
}
-(BOOL)displayTutorialIfNecessary:(MBTutorialViewType)type withOffset:(NSInteger)y{
    
    if(self.userDisabledTutorials){
        return false;
    }
    
    MBTutorial* tutorial = [self tutorialForType:type];
    if(tutorial.currentCount > 0){
        if(DEBUG_TUTORIAL){
            // NSLog(@"tutorial decrease count for %lu",(unsigned long)tutorial.identifier);
        }
        tutorial.currentCount--;
        [self storeStatus];
    }
    BOOL displayTutorial = false;
    if(tutorial.markedAsAbsolete){
        return false;
    }
    if(tutorial.ruleBlock){
        if(tutorial.ruleBlock(tutorial)){
            displayTutorial = true;
        }
    } else {
        //implementation without rule block: just use the closedByUser flag and the counter
        displayTutorial = tutorial.currentCount <= 0 && !tutorial.closedByUser;
    }
    if(displayTutorial){
        if(DEBUG_TUTORIAL){
            // NSLog(@"tutorial show %lu",(unsigned long)tutorial.identifier);
        }
        MBTutorialView* view = [[MBTutorialView alloc] initWithTutorial:tutorial];
        view.viewYOffset = y;
        [self.visibleTutorials addObject:view];
        
        //add the view on top of the currently visible viewcontroller
        AppDelegate* app = (AppDelegate*) [UIApplication sharedApplication].delegate;
        UINavigationController* vc = (UINavigationController*) app.window.rootViewController;
        
        CGFloat bottomSafeOffset = vc.view.safeAreaInsets.bottom;        
        view.viewYOffset = y+bottomSafeOffset;
        
        [vc.visibleViewController.view addSubview:view];
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, view);
        [view layoutIfNeeded];
        return true;
    }
    return false;
}

@end
