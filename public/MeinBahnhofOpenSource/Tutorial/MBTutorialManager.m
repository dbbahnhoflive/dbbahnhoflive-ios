// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBTutorialManager.h"
#import "MBTutorialView.h"
#import "AppDelegate.h"
#import <UIKit/UIKit.h>

@interface MBTutorialManager()

@property(nonatomic,strong) NSArray* allTutorials;
@property(nonatomic,strong) NSMutableArray* visibleTutorials;

@end

#define DEBUG_TUTORIAL NO

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
                                      [MBTutorial tutorialWithIdentifier:MBTutorialViewType_D1_ServiceStores_Details title:@"DB Services" text:@"Sie haben Fragen? Wir helfen Ihnen weiter." countdown:8],
                                      [MBTutorial tutorialWithIdentifier:MBTutorialViewType_D1_Aufzuege title:@"Merkliste erstellen" text:@"Verwalten Sie Ihre relevante Aufzüge. Ganz einfach und übersichtlich." countdown:5],
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
    if(!tutorial.closedByUser){
        tutorial.closedByUser = YES;
        [self storeStatus];
    }
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
        NSDictionary* tutStatus = @{ @"identifier":@(tutorial.identifier), @"closedByUser":@(tutorial.closedByUser), @"currentCount":@(tutorial.currentCount) };
        [status addObject:tutStatus];
    }
    if(DEBUG_TUTORIAL){
        // NSLog(@"tutorial store status %@",status);
    }
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
    [def setObject:status forKey:@"MBTUTORIAL_STATUS"];
    [def synchronize];
}
-(void)restoreStatus{
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
    NSArray* status = [def objectForKey:@"MBTUTORIAL_STATUS"];
    if(status){
        for(NSDictionary* tutStatus in status){
            MBTutorialViewType type = [tutStatus[@"identifier"] intValue];
            MBTutorial* tutorial = [self tutorialForType:type];
            tutorial.closedByUser = [tutStatus[@"closedByUser"] boolValue];
            tutorial.currentCount = [tutStatus[@"currentCount"] integerValue];
            // NSLog(@"tutorial restore %lu, %d, %ld",(unsigned long)tutorial.identifier,tutorial.closedByUser,(long)tutorial.currentCount);
        }
    }
    _userDisabledTutorials = [def boolForKey:@"MBTutorial.userDisabledTutorials"];
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
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
    [def setBool:userDisabledTutorials forKey:@"MBTutorial.userDisabledTutorials"];
    [def synchronize];
}
-(BOOL)userDidCloseAllTutorials{
    for(MBTutorial* tutorial in self.allTutorials){
        if(!tutorial.closedByUser){
            return NO;
        }
    }
    return YES;
}


-(void)displayTutorialIfNecessary:(MBTutorialViewType)type{
    [self displayTutorialIfNecessary:type withOffset:0];
}
-(void)displayTutorialIfNecessary:(MBTutorialViewType)type withOffset:(NSInteger)y{
    
    if(self.userDisabledTutorials){
        return;
    }
    
    MBTutorial* tutorial = [self tutorialForType:type];
    if(tutorial.currentCount > 0){
        if(DEBUG_TUTORIAL){
            // NSLog(@"tutorial decrease count for %lu",(unsigned long)tutorial.identifier);
        }
        tutorial.currentCount--;
        [self storeStatus];
    }
    if(tutorial.currentCount <= 0 && !tutorial.closedByUser){
        if(DEBUG_TUTORIAL){
            // NSLog(@"tutorial show %lu",(unsigned long)tutorial.identifier);
        }
        MBTutorialView* view = [[MBTutorialView alloc] initWithTutorial:tutorial];
        view.viewYOffset = y;
        [self.visibleTutorials addObject:view];
        
        //add the view on top of the currently visible viewcontroller
        AppDelegate* app = (AppDelegate*) [UIApplication sharedApplication].delegate;
        UINavigationController* vc = (UINavigationController*) app.window.rootViewController;
        
        CGFloat bottomSafeOffset = 0.0;
        if (@available(iOS 11.0, *)) {
            bottomSafeOffset = vc.view.safeAreaInsets.bottom;
        }
        view.viewYOffset = y+bottomSafeOffset;
        
        [vc.visibleViewController.view addSubview:view];
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, view);
        [view layoutIfNeeded];
    }
}

@end
