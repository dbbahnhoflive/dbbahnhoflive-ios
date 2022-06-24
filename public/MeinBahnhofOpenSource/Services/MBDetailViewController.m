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

    if(self.serviceNeedsAdditionalData){
        [self loadServiceData];
    } else {
        [self configureServiceView:self.service];
    }
}


-(BOOL)serviceNeedsAdditionalData{
    return [self.service.type isEqualToString:kServiceType_Barrierefreiheit] && self.station.platformAccessibility == nil;
}
-(void)loadServiceData{
    self.act = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:self.act];
    [self.act startAnimating];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.act);

    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    for(NSString* eva in self.station.stationEvaIds){
        dispatch_group_enter(group);
        //NSLog(@"loading platform data for eva %@",eva);
        [[MBRISStationsRequestManager sharedInstance] requestAccessibility:eva success:^(NSArray<MBPlatformAccessibility *> *platformList) {
            //NSLog(@"got platform acc: %@",platformList);
            [self.station addPlatformAccessibility:platformList];
            dispatch_group_leave(group);
        } failureBlock:^(NSError *error) {
            dispatch_group_leave(group);
        }];
    }
    dispatch_group_leave(group);
    dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.act stopAnimating];
            [self.act removeFromSuperview];
            self.act = nil;
            [self configureServiceView:self.service];
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.view);
        });
    });
}

-(NSArray<NSString *> *)mapFilterPresets{
    if(self.service){
        if([self.service.type isEqualToString:kServiceType_Barrierefreiheit] ){
            return @[PRESET_ELEVATORS];
        } else if([self.service.type isEqualToString:kServiceType_SEV]){
            return @[PRESET_SEV];
        }
    }
    return nil;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
        
    if(self.trackingTitle){
        [MBTrackingManager trackStatesWithStationInfo:@[@"d1", self.trackingTitle]];
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
