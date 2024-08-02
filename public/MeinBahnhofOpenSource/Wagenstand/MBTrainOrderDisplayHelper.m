// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBTrainOrderDisplayHelper.h"
#import "Wagenstand.h"
#import "MBTrainPositionViewController.h"
#import "MBProgressHUD.h"
#import "Stop.h"

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


- (void) displayWagenstandViewController:(Wagenstand *)wagenstand
{
    MBTrainPositionViewController *wagenstandDetailViewController = [[MBTrainPositionViewController alloc] init];
    wagenstandDetailViewController.station = self.station;
    wagenstandDetailViewController.isOpenedFromTimetable = YES;
    wagenstandDetailViewController.wagenstand = wagenstand;
    [self.vc.navigationController pushViewController:wagenstandDetailViewController animated:YES];
    [self clearReferences];
}


-(void)showWagenstandForStop:(Stop *)stop station:(MBStation*)station departure:(BOOL)departure inViewController:(UIViewController*)vc{
    self.departure = departure;
    self.station = station;
    self.vc = vc;
    
    [MBProgressHUD showHUDAddedTo:vc.navigationController.view animated:YES];
    
    Event *event = [stop eventForDeparture:self.departure];
    
    NSString* dateString = [Wagenstand dateRequestStringForTimestamp:event.timestamp];
    if (dateString && [Wagenstand isValidTrainTypeForIST:stop.transportCategory.transportCategoryType]) {
        [[WagenstandRequestManager sharedManager]
         loadISTWagenstandWithTrain:stop.transportCategory.transportCategoryNumber
         type:stop.transportCategory.transportCategoryType
         date:dateString
         evaId:stop.evaNumber
         departure:self.departure
         completionBlock:^(Wagenstand *istWagenstand) {
            [MBProgressHUD hideHUDForView:self.vc.navigationController.view animated:YES];
             if (istWagenstand) {
                 //add delay information from IRIS to the IST-Wagenstand data for delayed notification
                 Event *event = [stop eventForDeparture:self.departure];
                 istWagenstand.expected_time = [event formattedExpectedTime];
                 istWagenstand.plan_time = event.formattedTime;
                 [self displayWagenstandViewController:istWagenstand];
             } else {
                 [self displayAlertWagenstandNotFound];
             }
             
         }];
    } else {
        [MBProgressHUD hideHUDForView:vc.navigationController.view animated:YES];
        [self displayAlertWagenstandNotFound];
    }
}
@end
