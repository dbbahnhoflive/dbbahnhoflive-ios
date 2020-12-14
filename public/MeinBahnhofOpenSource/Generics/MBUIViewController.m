// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBUIViewController.h"

#import "MBGPSLocationManager.h"

//imports for wagenstand
#import "MBProgressHUD.h"
#import "WagenstandRequestManager.h"
#import "MBTrainPositionViewController.h"
#import "MBButtonWithAction.h"

#import "MBRootContainerViewController.h"
#import "MBStationSearchViewController.h"

@interface MBUIViewController()

@property (nonatomic, assign) BOOL showBackButton;
@property (nonatomic, assign) BOOL showRootBackButton;
@end

@implementation MBUIViewController

- (instancetype) init
{
    if (self = [super init]) {
        self.showBackButton = YES;
    }
    return self;
}

- (instancetype) initWithBackButton:(BOOL)showBackButton
{
    if (self = [super init]) {
        self.showBackButton = showBackButton;
    }
    return self;
}

-(instancetype)initWithRootBackButton{
    if (self = [super init]) {
        self.showBackButton = YES;
        self.showRootBackButton = YES;
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    if (self.showBackButton) {
        [MBUIViewController addBackButtonToViewController:self andActionBlockOrNil:nil];
    }
    
}

+ (void) addBackButtonToViewController:(UIViewController*)vc andActionBlockOrNil:(void (^) (void))backHandler{
    MBButtonWithAction *backButton = [[MBButtonWithAction alloc] init];
    backButton.actionBlock = backHandler;
    if (backHandler == nil) {
        __weak UIViewController* vcWeak = vc;
        backButton.actionBlock = ^{
            [vcWeak.navigationController popViewControllerAnimated:YES];
        };
    }

    UIImage *backButtonImage = [UIImage db_imageNamed: @"app_zurueck_pfeil"];
    
    backButton.accessibilityLabel =  @"Zurück" ;
    backButton.accessibilityLanguage = @"de-DE";
    
    //[backButton setBackgroundImage:backButtonImage forState:UIControlStateNormal];
    UIImageView* img = [[UIImageView alloc] initWithImage:backButtonImage];
    [backButton addSubview:img];
    backButton.frame = CGRectMake(0, 0, 30,30);
    [img centerViewInSuperView];
    
    UIBarButtonItem *backBarButton = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    vc.navigationItem.leftBarButtonItem = backBarButton;
}

+ (void) removeBackButton:(UIViewController*)viewController
{
    if (viewController) {
        viewController.navigationItem.leftBarButtonItem = nil;
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}


- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
}




//- (void) showViewController:(UIViewController *)vc{
//    [self presentViewController:vc animated:YES completion:nil];
//}

- (void) showWagenstandForUserInfo:(NSDictionary *)userInfo
{
    // NSLog(@"load and display wagenstand for %@",userInfo);
    
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    
    UINavigationController* navi = self.navigationController;

    MBRootContainerViewController* root = nil;
    if([self isKindOfClass:[MBStationSearchViewController class]]){
        //opened wagenstand when inside a station
        root = ((MBStationSearchViewController*)self).stationMapController;
        navi = root.timetableNavigationController;
    } else if([self isKindOfClass:[MBRootContainerViewController class]]){
        //opened wagenstand when outside of a station
        root = (MBRootContainerViewController*)self;
        if(root.view){//force loading of view to get access to timetable
            navi = root.timetableNavigationController;
            // NSLog(@"open wagenstand for navi %@",navi);
        }
    }

    NSString* dateAndTime = [Wagenstand makeDateStringForTime:userInfo[WAGENSTAND_TIME]];
    // NSLog(@"request ist with evas %@",userInfo[WAGENSTAND_EVAS_NR]);
    [[WagenstandRequestManager sharedManager] loadISTWagenstandWithTrain:userInfo[WAGENSTAND_TRAINNUMBER] type:userInfo[WAGENSTAND_TYPETRAIN] departure:dateAndTime evaIds:userInfo[WAGENSTAND_EVAS_NR] completionBlock:^(Wagenstand *istWagenstand) {
        
        if(istWagenstand){
            MBTrainPositionViewController *wagenstandDetailViewController = [[MBTrainPositionViewController alloc] init];
            wagenstandDetailViewController.station = self.station;
            wagenstandDetailViewController.wagenstand = istWagenstand;
            [root selectTimetableTab];
            [navi pushViewController:wagenstandDetailViewController animated:YES];
        } else {
            //no IST-data
            UIAlertController* alertView = [UIAlertController alertControllerWithTitle:@"Hinweis" message:@"Beim Abrufen des Wagenreihungsplans ist ein Fehler aufgetreten. Bitte versuchen Sie es später erneut." preferredStyle:UIAlertControllerStyleAlert];
            [alertView addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:nil]];
            [root presentViewController:alertView animated:YES completion:nil];
            [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
            return;
        }
        
        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    }];
}

- (void) showFacilityFavorites //this is not used
{
    /*
    if([self.navigationController.topViewController isKindOfClass:[FacilityStatusViewController class]]){
        FacilityStatusViewController* vc = (FacilityStatusViewController*)self.navigationController.topViewController;
        [vc selectFavoritesTab];
        return;
    }
    FacilityStatusViewController *facilityStatusViewController = [[FacilityStatusViewController alloc] init];
    facilityStatusViewController.startWithFavoriteTab = YES;
    facilityStatusViewController.view.frame = self.view.frame;
    facilityStatusViewController.station = self.station;
    
    [self.navigationController pushViewController:facilityStatusViewController animated:YES];*/
}

- (void) showFacilityForStation
{
    /*
    if([self.navigationController.topViewController isKindOfClass:[FacilityStatusViewController class]]){
        FacilityStatusViewController* vc = (FacilityStatusViewController*)self.navigationController.topViewController;
        [vc selectOverviewTab];
        return;
    }
    FacilityStatusViewController *facilityStatusViewController = [[FacilityStatusViewController alloc] init];
    facilityStatusViewController.startWithFavoriteTab = NO;
    facilityStatusViewController.view.frame = self.view.frame;
    facilityStatusViewController.station = self.station;
    
    [self.navigationController pushViewController:facilityStatusViewController animated:YES];*/
}



@end
