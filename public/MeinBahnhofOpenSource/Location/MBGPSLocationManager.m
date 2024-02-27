// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBGPSLocationManager.h"

@interface MBGPSLocationManager()

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSNotificationCenter *dispatcher;
@property (nonatomic, strong) CLLocation *lastknownLocation;
@property (nonatomic) BOOL isAuthorized;

@end

@implementation MBGPSLocationManager

+ (MBGPSLocationManager*)sharedManager {
    static MBGPSLocationManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
        
        sharedManager.dispatcher = [NSNotificationCenter defaultCenter];
        
        sharedManager.locationManager = [[CLLocationManager alloc] init];
        sharedManager.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        sharedManager.locationManager.distanceFilter = 50;//50meter
        sharedManager.locationManager.delegate = sharedManager;
        sharedManager.locationManager.activityType = CLActivityTypeOther;
        sharedManager.locationManager.headingFilter = 3.0;
//        [sharedManager.locationManager requestWhenInUseAuthorization];
    });
    //NSLog(@"accessing location manager with authorizationStatus %d",[CLLocationManager authorizationStatus]);
    return sharedManager;
}

-(void)requestAuthorization{
    [self.locationManager requestWhenInUseAuthorization];
}

-(CLAuthorizationStatus)authStatus{
    return self.locationManager.authorizationStatus;
}


- (void) stopPositioning
{
    NSLog(@"GPS stopPositioning");
    [self.locationManager stopUpdatingLocation];
    self.isGettingOneShotLocation = NO;
}

- (void) stopAllUpdates
{
    [self stopPositioning];
}


-(void) getOneShotLocationUpdate
{
    if(self.isGettingOneShotLocation){
        return;
    }
    NSLog(@"getOneShotLocationUpdate: %@ and %d",self.locationManager,self.isLocationManagerAuthorized);
    // Request a location update
    if (self.locationManager && self.isLocationManagerAuthorized) {
        /*CLLocation *lastKnownLocation = [self.locationManager location];
        if (lastKnownLocation) {
            [self locationManager:self.locationManager didUpdateLocations:@[lastKnownLocation]];
        }*/
        NSLog(@"request location from %@",[NSThread currentThread]);
        self.isGettingOneShotLocation = YES;
        [self.locationManager requestLocation];
    }
}

- (CLLocation*) lastKnownLocation
{
    CLLocation *lastknownLocation = [self isLocationValid:self.lastknownLocation] ? self.lastknownLocation : nil;
    
    if (!lastknownLocation && self.isLocationManagerAuthorized) {
        // fallback to locationManager's last location
        lastknownLocation = [self isLocationValid:self.locationManager.location] ? self.locationManager.location : nil;
    }
    return lastknownLocation;
}

- (BOOL) isLocationValid:(CLLocation*)location
{
    if (!location) {
        return NO;
    }
    
    if ([[NSDate date] timeIntervalSinceDate:location.timestamp] > 60*4) {
        return NO;
    }
    
    if (location.coordinate.latitude <= 0 || location.coordinate.longitude <= 0 || location.horizontalAccuracy <= 0) {
        return NO;
    }
    
    return YES;
}


#pragma -
#pragma CLLocationManagerDelegate

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    self.isGettingOneShotLocation = NO;
    CLLocation *location = nil;
    
    BOOL isLocationValid = [self isLocationValid:manager.location];
    
    if (isLocationValid) {
        location = manager.location;
        self.lastknownLocation = location;
    }

    for (CLLocation *loc in locations) {
        BOOL isLocationValid = [self isLocationValid:loc];
        
        if (isLocationValid) {
            location = loc;
            self.lastknownLocation = location;
        }
    }
    NSLog(@"GPS updated lastknownLocation %@",self.lastknownLocation);
    
    if (location) {
        NSDictionary *payload = @{kGPSNotifLocationPayload: location};
        [self.dispatcher postNotificationName:NOTIF_GPS_LOCATION_UPDATE object:self userInfo:payload];
    } else {
        [self.dispatcher postNotificationName:NOTIF_GPS_LOCATION_UPDATE object:self userInfo:nil];
    }
}


-(BOOL)isLocationManagerAuthorized{
    return self.isAuthorized;
}

-(void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager{
    CLAuthorizationStatus status = manager.authorizationStatus;
    NSLog(@"didChangeAuthorizationStatus: %d",status);
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
            // ask user to give permission
            self.isAuthorized = NO;
            [self.dispatcher postNotificationName:NOTIF_GPS_AUTH_CHANGED object:self userInfo:@{@"available": @(NO)}];
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusAuthorizedAlways:
            self.isAuthorized = YES;
            [self.dispatcher postNotificationName:NOTIF_GPS_AUTH_CHANGED object:self userInfo:@{@"available": @(YES)}];
            break;
        default:
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    self.isGettingOneShotLocation = NO;
    NSLog(@"GPS: fail %@",error);
    [self stopAllUpdates];
    
    [self.dispatcher postNotificationName:NOTIF_GPS_LOCATION_UPDATE object:self userInfo:nil];
}

@end
