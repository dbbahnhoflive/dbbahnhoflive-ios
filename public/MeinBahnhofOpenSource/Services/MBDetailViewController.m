// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBDetailViewController.h"
#import "MBNavigationController.h"
#import "NSString+MBString.h"
#import "MBUIHelper.h"
#import "MBLabel.h"
#import "MBStationNavigationViewController.h"
#import "MBUrlOpening.h"
#import "MBRISStationsRequestManager.h"
#import "MBTrackingManager.h"

@interface MBDetailViewController()

@property (nonatomic, strong) MBService *service;
@property (nonatomic, strong) MBMarker *marker;
@property(nonatomic,strong) UIActivityIndicatorView* act;

@end

@implementation MBDetailViewController


- (instancetype) initWithStation:(MBStation *)station service:(MBService *)service
{
    if (self = [super init]) {
        self.station = station;
        self.service = service;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)setService:(MBService *)service{
    _service = service;
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    self.title = self.service.title;
    self.trackingTitle = self.service.trackingKey;

    [self configureServiceView:self.service];
}


-(BOOL)serviceNeedsAdditionalData{
    return [self.service.type isEqualToString:kServiceType_Barrierefreiheit] && self.station.platformAccessibility == nil;
}

-(NSArray<NSString *> *)mapFilterPresets{
    if(self.service){
        if([self.service.type isEqualToString:kServiceType_Barrierefreiheit] ){
            return @[PRESET_ELEVATORS,PRESET_DB_TIMETABLE];
        } else if([self.service.type isEqualToString:kServiceType_SEV] || [self.service.type isEqualToString:kServiceType_SEV_AccompanimentService]){
            return @[PRESET_SEV];
        } else if([self.service.type isEqualToString:kServiceType_Locker]){
            return @[PRESET_LOCKER, PRESET_LUGGAGE];
        }
    }
    return nil;
}

- (id)mapSelectedPOI{
    return self.poiToSelectOnMap;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
        
    if(self.trackingTitle){
        [MBTrackingManager trackStatesWithStationInfo:@[@"d1", self.trackingTitle]];
    }
    if([self.service.type isEqualToString:kServiceType_SEV]){
        [MBTrackingManager trackActionsWithStationInfo:@[@"d1",@"schienenersatzverkehr",@"haltestelleninformation"]];
    }
    
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (nil != self.navigationController) {
        if ([self.navigationController isKindOfClass:[MBStationNavigationViewController class]]) {
            [(MBStationNavigationViewController *)self.navigationController hideNavbar:NO];
            [(MBStationNavigationViewController *)self.navigationController showBackgroundImage:NO];
            [(MBStationNavigationViewController *)self.navigationController setShowRedBar:YES];
        }
    }
    [self.act centerViewInSuperView];
}

- (void) updateDistanceLabel:(CLLocation*)location
{
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}

#pragma Create Views

- (void) configureServiceView:(MBService*)service
{
    MBStaticServiceView *staticServiceView = [[MBStaticServiceView alloc] initWithService:service station:self.station viewController:self fullscreenLayout:YES andFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    staticServiceView.delegate = self;
    [self.view addSubview:staticServiceView];
}





#pragma -


#pragma mark MBDetailViewDelegate

- (void) didTapOnPhoneLink:(NSString *)phoneNumber
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Anrufen" message:phoneNumber preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Anrufen" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *phoneURLString = [NSString stringWithFormat:@"tel:%@",phoneNumber];
        phoneURLString = [phoneURLString stringByReplacingOccurrencesOfString:@"  " withString:@""];
        phoneURLString = [phoneURLString stringByReplacingOccurrencesOfString:@" " withString:@""];
        phoneURLString = [phoneURLString stringByReplacingOccurrencesOfString:@"/" withString:@""];
        phoneURLString = [phoneURLString stringByReplacingOccurrencesOfString:@"-" withString:@""];
        
        NSURL *phoneURL = [NSURL URLWithString:phoneURLString];
        [MBUrlOpening openURL:phoneURL];

    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Abbrechen" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) didOpenUrl:(NSURL *)url
{
    [MBUrlOpening openURL:url];

}

- (void) didTapOnEmailLink:(NSString*)mailAddress;
{
    if ([mailAddress rangeOfString:@"mailto:"].location == NSNotFound) {
        mailAddress = [NSString stringWithFormat:@"mailto:%@",mailAddress];
    }
    [MBUrlOpening openURL:[NSURL URLWithString:mailAddress]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
