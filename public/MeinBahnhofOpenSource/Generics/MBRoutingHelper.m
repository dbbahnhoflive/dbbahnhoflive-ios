// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBRoutingHelper.h"
#import "AppDelegate.h"
#import <GoogleMaps/GoogleMaps.h>
#import <MapKit/MapKit.h>
#import "MBUrlOpening.h"

@implementation MBRoutingHelper

//routing

+ (BOOL) hasGoogleMaps
{
    return [MBUrlOpening canOpenURL:
            [NSURL URLWithString:@"comgooglemaps://"]];
}

+ (BOOL) hasAppleMaps
{
    return [MBUrlOpening canOpenURL:
            [NSURL URLWithString:@"https://maps.apple.com"]];
}

+(void)showRoutingForParking:(MBParkingInfo *)parking fromViewController:(UIViewController*)fromViewController{
    
    NSString* name = parking.name;
    CLLocationCoordinate2D loc = parking.location;
    
    [self routeToName:name location:loc fromViewController:fromViewController];
}

+(void)routeToName:(NSString *)name location:(CLLocationCoordinate2D)loc fromViewController:(UIViewController* _Nullable)fromViewController{
    
    if(fromViewController == nil){
        AppDelegate* app = AppDelegate.appDelegate;
        fromViewController = app.viewController;
    }
    
    BOOL hasGoogleMaps = [self hasGoogleMaps];
    BOOL hasAppleMaps = [self hasAppleMaps];
    if(hasAppleMaps && hasGoogleMaps){
        
        UIAlertControllerStyle style = UIAlertControllerStyleActionSheet;
        if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad){
            style = UIAlertControllerStyleAlert;
        }
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Routing"
                                                                       message:@"Routing per Apple Karten oder Google Maps?"
                                                                preferredStyle:style];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Apple Karten" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  // NSLog(@"Apple");
                                                                  MKMapItem * item = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:loc addressDictionary:@{
                                                                                                                                                                                          }]];
                                                                  [item setName:name];
                                                                  [item openInMapsWithLaunchOptions:@{}];
                                                                  
                                                              }];
        [alert addAction:defaultAction];
        defaultAction = [UIAlertAction actionWithTitle:@"Google Maps" style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action) {
                                                   // NSLog(@"Google");
                                                   //NSString* addr = [NSString stringWithFormat:@"%@", parking.name];
                                                   //addr = [addr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                                                   NSString* link = [NSString stringWithFormat:@"comgooglemaps://?daddr=%f,%f",
                                                                     loc.latitude,loc.longitude];
                                                   [MBUrlOpening openURL:[NSURL URLWithString:link]];
                                               }];
        [alert addAction:defaultAction];
        defaultAction = [UIAlertAction actionWithTitle:@"Abbrechen" style:UIAlertActionStyleCancel
                                               handler:nil];
        [alert addAction:defaultAction];
        
        // show action sheet
        [fromViewController presentViewController:alert animated:YES completion:nil];
    } else {
        [MBUrlOpening openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://maps.apple.com/?q=%f,%f",loc.latitude,loc.longitude]]];
    }
}
@end
