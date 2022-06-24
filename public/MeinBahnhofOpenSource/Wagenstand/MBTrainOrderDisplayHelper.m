// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBTrainOrderDisplayHelper.h"
#import "Wagenstand.h"
#import "MBTrainPositionViewController.h"
#import "MBProgressHUD.h"

@interface MBTrainOrderDisplayHelper()
@property(nonatomic,strong) UIViewController* vc;
@property(nonatomic,strong) MBStation* station;
@property(nonatomic) BOOL departure;

@end

@implementation MBTrainOrderDisplayHelper


- (void) displayAlertWagenstandNotFound
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Hinweis" message:@"Für den ausgewählten Zug liegt derzeit noch keine aktuelle Wagenreihung vor. Bitte versuchen Sie es später erneut." preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:nil]];
    [self.vc presentViewController:alert animated:YES completion:nil];
    [self clearReferences];
}

-(void)clearReferences{
    self.vc = nil;
    self.station = nil;
}


- (void) displayWagenstandViewController:(Wagenstand *)wagenstand withQueryValues:(NSDictionary *) queryValues
{
    MBTrainPositionViewController *wagenstandDetailViewController = [[MBTrainPositionViewController alloc] init];
    wagenstandDetailViewController.station = self.station;
    wagenstandDetailViewController.isOpenedFromTimetable = YES;
    wagenstandDetailViewController.queryValues = queryValues;
    wagenstandDetailViewController.wagenstand = wagenstand;
    [self.vc.navigationController pushViewController:wagenstandDetailViewController animated:YES];
    [self clearReferences];
}



- (void) requestISTWagenstand:(NSString*)dateString forStop:(Stop*) stop withQueryValues:(NSDictionary*)queryValues
{
    [[WagenstandRequestManager sharedManager]
     loadISTWagenstandWithTrain:stop.transportCategory.transportCategoryNumber
     type:stop.transportCategory.transportCategoryType
     departure:dateString
     evaIds:@[stop.evaNumber]
     completionBlock:^(Wagenstand *istWagenstand) {
        [MBProgressHUD hideHUDForView:self.vc.navigationController.view animated:YES];
         if (istWagenstand) {
             //add delay information from IRIS to the IST-Wagenstand data for delayed notification
             Event *event = [stop eventForDeparture:self.departure];
             istWagenstand.expectedTime = [event formattedExpectedTime];
             [self displayWagenstandViewController:istWagenstand withQueryValues:queryValues];
         } else {
             [self displayAlertWagenstandNotFound];
         }
         
     }];
    
}

-(void)showWagenstandForStop:(Stop *)stop station:(MBStation*)station departure:(BOOL)departure inViewController:(UIViewController*)vc{
    self.departure = departure;
    self.station = station;
    self.vc = vc;
    
    [MBProgressHUD showHUDAddedTo:vc.navigationController.view animated:YES];
    
    Event *event = [stop eventForDeparture:self.departure];
    
    NSMutableDictionary* queryValues = [NSMutableDictionary dictionaryWithCapacity:3];
    if(stop.transportCategory.transportCategoryType){
        [queryValues setObject:stop.transportCategory.transportCategoryType forKey:@"type"];
    }
    if(stop.transportCategory.transportCategoryNumber){
        [queryValues setObject:stop.transportCategory.transportCategoryNumber forKey:@"number"];
    }
    if(event.originalPlatform){
        [queryValues setObject:event.originalPlatform forKey:@"platform"];
    }
    
    NSString* dateString = [Wagenstand makeDateStringForTime:event.formattedTime];
    
    if ([Wagenstand isValidTrainTypeForIST:stop.transportCategory.transportCategoryType]) {
        // Request IST for ICE
        [self requestISTWagenstand:dateString forStop:stop withQueryValues:queryValues];
    } else {
        [MBProgressHUD hideHUDForView:vc.navigationController.view animated:YES];
        [self displayAlertWagenstandNotFound];
    }
}
@end
