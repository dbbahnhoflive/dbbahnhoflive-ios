// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Mantle/Mantle.h>
#import "MBStationSearchViewController.h"
#import "MBUIHelper.h"

#import "MBInputField.h"
#import "MBRootContainerViewController.h"
#import "MBNavigationController.h"
#import "TimetableManager.h"
#import "AttributableButton.h"

#import "MBGPSLocationManager.h"
#import "FacilityStatusManager.h"

#import "MBImprintViewController.h"

#import "FacilityStatus.h"
#import "MBStation.h"
#import "MBService.h"
#import "LevelplanWrapper.h"
#import "WagenstandRequestManager.h"
#import "OnboardingViewController.h"
#import "MBTrackingConsentViewController.h"

#import "MBParkingManager.h"
#import "MBParkingInfo.h"
#import "MBParkingOccupancyManager.h"

#import "RIMapPoi.h"

#import "MBLinkButton.h"
#import "MBMapViewButton.h"
#import "MBMarkerMerger.h"
#import "MBMarker.h"

#import "MBFavoriteStationManager.h"
#import "MBMapViewController.h"
#import "MBRISStationsRequestManager.h"

#import "MBStationNavigationViewController.h"
#import "MBTutorialManager.h"

#import "MBStationPickerTableViewCell.h"
#import "MBLabel.h"
#import "HafasRequestManager.h"
#import "HafasCacheManager.h"
#import "MBTimetableViewController.h"
#import "MBTriangleView.h"
#import "MBSearchErrorView.h"
#import "MBUrlOpening.h"
#import "MBStationListTableView.h"
#import "MBProgressHUD.h"
#import "MBTrackingManager.h"
#import "AppDelegate.h"
#import "MBTrainPositionViewController.h"
#import "MBBackNavigationState.h"

@import Sentry;

typedef NS_ENUM(NSUInteger, MBStationSearchType){
    MBStationSearchTypeTextSearch = 0,
    MBStationSearchTypeFavorite = 1,
    MBStationSearchTypeLocation = 2
};

#define SETTING_DIDSEE_TUTORIAL @"did_see_tutorial"
#define SETTING_LAST_ONBOARDING_VERSION @"onboarding_version_info"
#define SETTING_LAST_SEARCH_TYPE @"LAST_SEARCH_TYPE"

#define kErrorMessage @"Die Anfrage konnte gerade nicht ausgeführt werden."
#define kEmptyMessage @"Für diesen Suchbegriff konnten keine Stationen gefunden werden."


#define kMinCharactedsSuggestionTreshold 2
#define kOuterPadding 35

#define kLocationManagerAccuracy 50.f

#define kButtonTagCancel 999
#define kButtonTagLocation 888

#define BACKGROUND_IMAGE_HEIGHT ( ISIPAD ? 512-60 : (int)(188*SCALEFACTORFORSCREEN))
#define SEARCHVIEW_CONTAINER_Y (ISIPAD ? 390-126 : 0)
#define SEARCHVIEW_CONTAINER_Y_MIN (SEARCHVIEW_CONTAINER_Y)
#define FOOTER_HEIGHT (ISIPAD ? 60 : 40)

static NSString * const kFavoriteCollectionViewCellReuseIdentifier = @"Cell";


@interface MBStationSearchViewController ()<MBMapViewControllerDelegate, UITextFieldDelegate,CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource,MBStationPickerTableViewCellDelegate, MBSearchErrorViewDelegate>

@property (nonatomic, strong) MBStation* _Nullable selectedStation;
@property (nonatomic, strong) MBRootContainerViewController* _Nullable stationMapController;

@property (nonatomic) MBStationSearchType currentType;
@property (nonatomic,strong) MBTriangleView* triangleErrorView;
@property (nonatomic,strong) MBTriangleView* triangleInputTextfieldView;

@property (nonatomic,strong) UIImageView* backgroundImage;

@property (nonatomic,strong) UIView* backgroundTapView;

@property (nonatomic,strong) UIView* featureButtonArea;
@property (nonatomic,strong) UIButton* featureSearchButton;
@property (nonatomic,strong) UIButton* featureFavoriteButton;
@property (nonatomic,strong) UIButton* featureLocationButton;

@property(nonatomic,strong) UIButton* closeButton;//only visible in text input mode

@property (nonatomic, strong) MBInputField *stationSearchInputField;
@property (nonatomic, strong) MBStationListTableView* searchResultTableView;
@property (nonatomic, strong) MBStationListTableView* favoritesTableView;
@property (nonatomic, strong) MBStationListTableView* geoSearchTableView;
@property (nonatomic, strong) MBSearchErrorView* searchErrorView;
@property (nonatomic, strong) NSIndexPath* longPressStation;

@property (nonatomic, strong) UIButton* searchResultDeleteButton;
@property (nonatomic, strong) UILabel* searchResultHeaderTitle;
@property (nonatomic, strong) NSArray<MBStationFromSearch*>* searchResultTextArray;
@property (nonatomic) BOOL searchResultListFromSearchHistory;
@property (nonatomic, strong) NSArray<MBStationFromSearch*>* searchResultGeoArray;

@property (nonatomic, strong) UIActivityIndicatorView* loadActivity;
@property (nonatomic, strong) UIImageView *logoImage;
@property (nonatomic, strong) UILabel *logoText;//this is the text "Bahnhof live"

@property (nonatomic, strong) CLLocation *currentUserPosition;
@property (nonatomic, assign) BOOL locationManagerAuthorized;
@property (nonatomic) BOOL viewAppeared;

@property (nonatomic, strong) NSArray *staticStations;

@property (nonatomic, strong) UIButton *inputAccessoryButton;

@property (nonatomic, strong) MBLinkButton *imprintButton;
@property (nonatomic, strong) MBLinkButton *datenschutzButton;
@property (nonatomic, strong) UIView* footerButtons;

@property (nonatomic, strong) NSDictionary* wagenstandUserInfo;
@property (nonatomic) BOOL startWithFacilityView;

@property (atomic) BOOL isProcessingLocationUpdate;
@property (atomic) BOOL triggerSearchAfterLocationUpdate;
@property (atomic) BOOL mapRequestedSearchUpdate;
@property (nonatomic,strong) MBMapViewController* mapViewController;

@property (nonatomic,strong) UIButton* mapFloatingBtn;

@property(nonatomic) BOOL isVisible;
@property (nonatomic) NSInteger requestDBOngoing;
@property(nonatomic) BOOL didSelectStationRunning;

@property(nonatomic,strong) NSMutableArray<MBBackNavigationState*>* backNavigationList;

@end

@implementation MBStationSearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.requestDBOngoing = 0;
    self.backNavigationList = [NSMutableArray arrayWithCapacity:2];
    
    [(MBStationNavigationViewController *)self.navigationController setHideEverything:YES];

    self.title = @"";
    
    //this is a bit hacky, we need a tap gesture on the background and in all tableview backgrounds
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(backgroundTapped:)];
    NSLog(@"adding tap: %@",tap);
    [self.backgroundTapView addGestureRecognizer:tap];
}
-(void)backgroundTapped:(UITapGestureRecognizer*)sender{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        NSLog(@"backgroundTapped:");
        if(self.longPressStation){
            self.longPressStation = nil;
            [self reloadAllTableViews];
        } else {
            [self dismissKeyboard:sender];
        }
    }
}
-(void)reloadAllTableViews{
    [self.searchResultTableView reloadData];
    [self.favoritesTableView reloadData];
    [self.geoSearchTableView reloadData];
}


- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [MBTrackingManager trackState:@"h0"];

    //NSLog(@"GPS viewDidAppear stops positioning");
    [[MBGPSLocationManager sharedManager] stopPositioning];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleEnterForeground:)
                                                name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveLocationUpdate:) name:NOTIF_GPS_LOCATION_UPDATE object:nil];


    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardDidShow:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];

    if(self.locationManagerAuthorized){
        [[MBGPSLocationManager sharedManager] getOneShotLocationUpdate];//callback in didReceiveLocationUpdate
    }
    [self updateErrorViewForLocation];
    //we count viewDidAppear as "using app"
    if(!self.onBoardingVisible){
        //[[MBTutorialManager singleton] displayTutorialIfNecessary:MBTutorialViewType_00_Hub_Abfahrt withOffset:0];
        //[[MBTutorialManager singleton] displayTutorialIfNecessary:MBTutorialViewType_00_Hub_Start withOffset:0];
    }
    self.viewAppeared = YES;
}

- (void) displayOnboarding
{
    if(UIAccessibilityIsVoiceOverRunning()){
        [self displayPrivacyDialog];
        return;
    }
    
    NSString *appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    NSUserDefaults* def = NSUserDefaults.standardUserDefaults;
    BOOL didSeeTutorial = [def boolForKey:SETTING_DIDSEE_TUTORIAL];
    if (!didSeeTutorial) {
        
        [def setBool:YES forKey:SETTING_DIDSEE_TUTORIAL];
        [def setObject:appVersionString forKey:SETTING_LAST_ONBOARDING_VERSION];
        
        self.onBoardingVisible = YES;
        OnboardingViewController *onboardingViewController = [[OnboardingViewController alloc] init];
        onboardingViewController.view.frame = CGRectMake(0, 0, self.view.sizeWidth, self.view.sizeHeight);
        onboardingViewController.view.accessibilityViewIsModal = YES;
        [self addChildViewController:onboardingViewController];
        [onboardingViewController didMoveToParentViewController:self];
        [self.view addSubview:onboardingViewController.view];
   }
   [self displayPrivacyDialog];

}
-(void)displayPrivacyDialog{
    if(self.privacySetupVisible){
        return;
    }
    AppDelegate* app = (AppDelegate*) UIApplication.sharedApplication.delegate;
    if(app.needsInitialPrivacyScreen){
        self.privacySetupVisible = YES;
        MBTrackingConsentViewController* vc = [MBTrackingConsentViewController new];
        vc.view.accessibilityViewIsModal = YES;
        vc.view.frame = CGRectMake(0, 0, self.view.sizeWidth, self.view.sizeHeight);
        [self addChildViewController:vc];
        [vc didMoveToParentViewController:self];
        [self.view addSubview:vc.view];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveLocationAuthorizationUpdate:) name:NOTIF_GPS_AUTH_CHANGED object:nil];

    [(MBStationNavigationViewController *)self.navigationController setHideEverything:YES];
    [(MBStationNavigationViewController *)self.navigationController hideNavbar:YES];
    
    self.isVisible = YES;
    [self.stationSearchInputField resignFirstResponder];
    
    self.locationManagerAuthorized = [[MBGPSLocationManager sharedManager] isLocationManagerAuthorized];
    
    [self reloadAllTableViews];
    [self displayOnboarding];

}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.isVisible = NO;

    [self.stationSearchInputField resignFirstResponder];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIF_GPS_AUTH_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIF_GPS_LOCATION_UPDATE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

}


- (int)scaleForScreen:(CGFloat)v
{
    return (int)(v*SCALEFACTORFORSCREEN);
}

- (void) loadView
{
    [super loadView];
    
    self.locationManagerAuthorized = [[MBGPSLocationManager sharedManager] isLocationManagerAuthorized];

    
    _currentType = MBStationSearchTypeTextSearch;
    NSUserDefaults* def = NSUserDefaults.standardUserDefaults;
    if([def objectForKey:SETTING_LAST_SEARCH_TYPE]){
        _currentType = [[def objectForKey:SETTING_LAST_SEARCH_TYPE] integerValue];
    }
    
    
    self.view.backgroundColor = [UIColor db_f0f3f5];

    NSString* file = [[NSBundle mainBundle] pathForResource:@"Blurred_Hintergrund.jpg" ofType:nil];
    if(!file){
        file = [[NSBundle mainBundle] pathForResource:@"Blurred_Hintergrund_gray.png" ofType:nil];
    }
    self.backgroundImage = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:file]];
    self.backgroundImage.contentMode = UIViewContentModeScaleAspectFill;
    self.backgroundImage.clipsToBounds = YES;
    [self.view addSubview:self.backgroundImage];
    
    self.backgroundTapView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.sizeWidth, self.view.sizeHeight)];
    self.backgroundTapView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.backgroundTapView];
    
    self.closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    [self.closeButton setImage:[UIImage db_imageNamed:@"ChevronBlackLeft"] forState:UIControlStateNormal];
    self.closeButton.accessibilityLabel = @"Suche schließen";
    self.closeButton.accessibilityIdentifier = @"CloseButton";
    [self.closeButton addTarget:self action:@selector(closeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.closeButton];
    self.closeButton.hidden = YES;
    
    if(!MBMapViewController.canDisplayMap){
        NSLog(@"no map button available when starting with voiceover");
    } else {
        self.mapFloatingBtn = [[MBMapViewButton alloc] init];
        [self.mapFloatingBtn addTarget:self action:@selector(mapFloatingBtnPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.mapFloatingBtn setSize:CGSizeMake([self scaleForScreen:self.mapFloatingBtn.frame.size.width], [self scaleForScreen:self.mapFloatingBtn.frame.size.height])];
    }

    self.logoImage = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"Hub_Icon"]];
    if(SCALEFACTORFORSCREEN != 1.0){
        self.logoImage.size = CGSizeMake([self scaleForScreen:self.logoImage.sizeWidth], [self scaleForScreen:self.logoImage.sizeHeight]);
    }
    [self.view addSubview:self.logoImage];
    [self.logoImage centerViewHorizontalInSuperView];
    [self.logoImage setGravityTop:[self scaleForScreen:26]];
    
    self.logoText = [[UILabel alloc] initWithFrame:CGRectZero];
    CGRect logoFrame = CGRectMake(0,
                                  [self scaleForScreen:146],
                                  300,
                                  32);
    self.logoText.frame = logoFrame;
    self.logoText.textColor = [UIColor whiteColor];
    self.logoText.textAlignment = NSTextAlignmentCenter;
    NSMutableAttributedString* logotext = [[NSMutableAttributedString alloc] initWithString:@"Bahnhof live" attributes:@{NSFontAttributeName:[UIFont db_RegularWithSize:25.*SCALEFACTORFORSCREEN]}];
    [logotext setAttributes:@{NSFontAttributeName:[UIFont db_BoldWithSize:25.*SCALEFACTORFORSCREEN]} range:NSMakeRange(0, @"Bahnhof".length)];
    self.logoText.attributedText = logotext;
    self.logoText.accessibilityTraits = UIAccessibilityTraitHeader;
    [self.view addSubview:self.logoText];
    [self.logoText centerViewHorizontalInSuperView];
    
    self.featureSearchButton = [self createFeatureButton:MBStationSearchTypeTextSearch];
    self.featureFavoriteButton = [self createFeatureButton:MBStationSearchTypeFavorite];
    self.featureLocationButton = [self createFeatureButton:MBStationSearchTypeLocation];
    self.featureButtonArea = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.sizeWidth, self.featureSearchButton.sizeHeight)];
    self.featureButtonArea.backgroundColor = [UIColor clearColor];
    
    UIView* featureBackground = [[UIView alloc] initWithFrame:CGRectMake(15, 0, self.featureSearchButton.sizeWidth*3, self.featureSearchButton.sizeHeight)];
    featureBackground.backgroundColor = [UIColor dbColorWithRGB:0xF5F5F5];
    featureBackground.layer.cornerRadius = featureBackground.sizeHeight/2;
    [self.featureButtonArea addSubview:featureBackground];
    
    [self.featureButtonArea addSubview:self.featureSearchButton];
    [self.featureButtonArea addSubview:self.featureFavoriteButton];
    [self.featureButtonArea addSubview:self.featureLocationButton];
    [self.view addSubview:self.featureButtonArea];

    [self.featureSearchButton setGravityLeft:15];
    [self.featureFavoriteButton setRight:self.featureSearchButton withPadding:0];
    [self.featureLocationButton setRight:self.featureFavoriteButton withPadding:0];
    [self.featureButtonArea setBelow:self.logoText withPadding:[self scaleForScreen:30]];
    
    CGRect inputFrame = CGRectMake(15, 0, self.view.frame.size.width-2*15, [self scaleForScreen:60]);
    self.stationSearchInputField = [[MBInputField alloc] initWithFrame:inputFrame];
    self.stationSearchInputField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.stationSearchInputField.font = [UIFont db_RegularWithSize:14.*SCALEFACTORFORSCREEN];
    self.stationSearchInputField.placeholder = @"Haltestellen finden. Bahnhöfe entdecken.";
    self.stationSearchInputField.accessibilityLanguage = @"de-DE";
    [self.view addSubview:self.stationSearchInputField];
    [self.stationSearchInputField setBelow:self.featureButtonArea withPadding:20];
    self.triangleInputTextfieldView = [[MBTriangleView alloc] initWithFrame:CGRectMake(0, 0, 16, 8)];
    [self.view addSubview:self.triangleInputTextfieldView];
    [self.triangleInputTextfieldView setAbove:self.stationSearchInputField withPadding:0];

    
    self.inputAccessoryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    self.inputAccessoryButton.isAccessibilityElement = NO;
    [self updateInputAccessoryForString:@""];
    [self.inputAccessoryButton setFrame:CGRectMake(0, 0, 25, 25)];
    [self.inputAccessoryButton addTarget:self action:@selector(accessoryButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.inputAccessoryButton.tag = kButtonTagLocation;
    self.inputAccessoryButton.accessibilityLabel = @"Eingabe löschen";
    self.inputAccessoryButton.accessibilityLanguage = @"de-DE";
    
    self.stationSearchInputField.rightViewMode = UITextFieldViewModeAlways;
    [self.stationSearchInputField setRightView:self.inputAccessoryButton];
    self.stationSearchInputField.delegate = self;
    
    UILabel* titleLabel = [[MBLabel alloc] initWithFrame:CGRectMake(inputFrame.origin.x+14, 0, inputFrame.size.width,[self scaleForScreen:26])];
    self.searchResultHeaderTitle = titleLabel;
    titleLabel.backgroundColor = [UIColor clearColor];
    [titleLabel setFont:[UIFont db_RegularFourteen]];
    [titleLabel setTextColor:[UIColor blackColor]];
    titleLabel.text = @"Suchverlauf";
    titleLabel.accessibilityLanguage = @"de-DE";
    titleLabel.accessibilityTraits |= UIAccessibilityTraitHeader;
    [self.view addSubview:titleLabel];
    
    self.searchResultDeleteButton = [[UIButton alloc] initWithFrame:CGRectMake(inputFrame.size.width-30, 0, 26+2*8, 26+2*8)];
    self.searchResultDeleteButton.accessibilityLabel = @"Suchverlauf löschen";
    [self.searchResultDeleteButton setImage:[UIImage db_imageNamed:@"app_loeschen"] forState:UIControlStateNormal];
    [self.searchResultDeleteButton addTarget:self action:@selector(searchResultDelete:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.searchResultDeleteButton];

    self.searchResultHeaderTitle.hidden = YES;
    self.searchResultDeleteButton.hidden = YES;
    
    CGRect pickerFrame = CGRectMake(inputFrame.origin.x, 0, inputFrame.size.width, 3*52);
    self.searchResultTableView = [self setupTableView];
    self.searchResultTableView.accessibilityIdentifier = @"SearchResults";
    self.searchResultTableView.triangleView.hidden = YES;
    self.favoritesTableView = [self setupTableView];
    self.favoritesTableView.accessibilityIdentifier = @"Favorites";
    self.geoSearchTableView = [self setupTableView];

    self.searchErrorView = [[MBSearchErrorView alloc] initWithFrame:pickerFrame];
    self.searchErrorView.delegate = self;
    [self.view addSubview:self.searchErrorView];
    self.searchErrorView.hidden = YES;
    
    self.triangleErrorView = [[MBTriangleView alloc] initWithFrame:CGRectMake(0, 0, 16, 8)];
    [self.searchErrorView addSubview:self.triangleErrorView];
    [self.triangleErrorView setY:-self.triangleErrorView.sizeHeight];
    [self.triangleErrorView centerViewHorizontalInSuperView];
    [self.searchErrorView addSubview:self.triangleErrorView];

    
    self.loadActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.loadActivity stopAnimating];
    if([[NSBundle mainBundle] pathForResource:@"impressum" ofType:@"html"]){
        self.imprintButton = [MBLinkButton boldButtonWithRedLink];
        [self.imprintButton setLabelText:@"Impressum"];
        [self.imprintButton addTarget:self action:@selector(didTapOnImprintLink:) forControlEvents:UIControlEventTouchUpInside];
    }
    if([[NSBundle mainBundle] pathForResource:@"datenschutz" ofType:@"html"]){
        self.datenschutzButton = [MBLinkButton boldButtonWithRedLink];
        [self.datenschutzButton setLabelText:@"Datenschutz"];
        [self.datenschutzButton addTarget:self action:@selector(didTapOnDatasecLink:) forControlEvents:UIControlEventTouchUpInside];
    }
    self.footerButtons = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, FOOTER_HEIGHT)];
    self.footerButtons.backgroundColor = [UIColor dbColorWithRGB:0xF0F3F5];
    [self.footerButtons addSubview:self.imprintButton];
    [self.footerButtons addSubview:self.datenschutzButton];
    
    [self.view addSubview:self.footerButtons];
    [self.view addSubview:self.mapFloatingBtn];

    [self configureCurrentType];
}

-(MBStationListTableView*)setupTableView{
    MBStationListTableView* tblv = [[MBStationListTableView alloc] initWithFrame:CGRectMake(15, 0, self.view.frame.size.width-2*15, 52) style:UITableViewStylePlain];
    tblv.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [tblv setContentInset:UIEdgeInsetsMake(8, 0, 80, 0)];
    [tblv registerClass:MBStationPickerTableViewCell.class forCellReuseIdentifier:@"cell"];
    tblv.separatorStyle = UITableViewCellSeparatorStyleNone;
    tblv.backgroundColor = [UIColor clearColor];
    tblv.backgroundView = [[UIView alloc] init];
    tblv.backgroundView.backgroundColor = [UIColor clearColor];
    tblv.delegate = self;
    tblv.dataSource = self;
    [self.view addSubview:tblv];
    tblv.hidden = YES;
    
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc]
           initWithTarget:self
           action:@selector(backgroundTapped:)];
    [tblv.backgroundView addGestureRecognizer:tap];

    return tblv;
}

-(void)updateInputAccessoryForString:(NSString*)string{
    if(string.length > 0){
        //we have some input
        [self.inputAccessoryButton setImage:[UIImage db_imageNamed:@"app_schliessen"] forState:UIControlStateNormal];
        self.inputAccessoryButton.userInteractionEnabled = YES;
        self.inputAccessoryButton.isAccessibilityElement = YES;
    } else {
        [self.inputAccessoryButton setImage:[UIImage db_imageNamed:@"app_lupe"] forState:UIControlStateNormal];
        self.inputAccessoryButton.userInteractionEnabled = NO;
        self.inputAccessoryButton.isAccessibilityElement = NO;
    }
}

#define CONTENT_VIEW_TAG 42
-(UIButton*)createFeatureButton:(MBStationSearchType)type{
    int buttonWidth = (self.view.sizeWidth-2*15)/3.;
    AttributableButton* button = [[AttributableButton alloc] initWithFrame:CGRectMake(0, 0, buttonWidth, 40)];
    button.backgroundColor = [UIColor clearColor];
    
    NSString* iconName = @"app_lupe";
    if(type == MBStationSearchTypeFavorite){
        iconName = @"app_favorit";
        button.accessibilityLabel = @"Favoriten";
    } else if(type == MBStationSearchTypeLocation){
        iconName = @"app_position";
        button.accessibilityLabel = @"Umkreissuche";
    } else {
        //textsearch
        button.accessibilityLabel = @"Suche";
    }
    button.accessibilityIdentifier = button.accessibilityLabel;

    UIImageView* icon = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:iconName]];
    [button addSubview:icon];
    [icon centerViewInSuperView];
    icon = nil;

    UIView* contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, button.sizeWidth, button.sizeHeight)];
    contentView.tag = CONTENT_VIEW_TAG;
    [button addSubview:contentView];
    
    contentView.layer.cornerRadius = 40/2;
    contentView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    contentView.layer.shadowColor = [[UIColor blackColor] CGColor];
    contentView.layer.shadowRadius = 4;
    contentView.layer.shadowOpacity = 0.35;
    contentView.backgroundColor = [UIColor whiteColor];
    
    UIImage* iconImg = [[UIImage db_imageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    icon = [[UIImageView alloc] initWithImage:iconImg];
    icon.tintColor = [UIColor db_mainColor];
    [contentView addSubview:icon];
    [icon centerViewInSuperView];
    
    button.actionType = [NSString stringWithFormat:@"%lu",(unsigned long)type];
    [button addTarget:self action:@selector(featureButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}
-(void)featureButtonPressed:(AttributableButton*)featureButton{
    MBStationSearchType type = featureButton.actionType.integerValue;
    self.currentType = type;
    [self configureCurrentType];
    switch (type) {
        case MBStationSearchTypeTextSearch:
            //[MBTrackingManager trackActions:@[@"h0", @"tap", @"suche"]];
            [self.searchResultTableView reloadData];
            break;
        case MBStationSearchTypeFavorite:
            [MBTrackingManager trackActions:@[@"h0", @"tap", @"favoriten"]];
            [self.favoritesTableView reloadData];
            break;
        case MBStationSearchTypeLocation:
            [MBTrackingManager trackActions:@[@"h0", @"tap", @"naehe"]];
            [self.geoSearchTableView reloadData];
            break;
    }
}

-(void)setCurrentType:(MBStationSearchType)currentType{
    _currentType = currentType;
    NSUserDefaults* def = NSUserDefaults.standardUserDefaults;
    [def setObject:[NSNumber numberWithInteger:_currentType] forKey:SETTING_LAST_SEARCH_TYPE];
}
-(void)configureCurrentType{
    self.triggerSearchAfterLocationUpdate = NO;
    self.longPressStation = nil;
    self.searchErrorView.hidden = YES;
    self.triangleErrorView.hidden = YES;
    self.stationSearchInputField.hidden = YES;
    self.triangleInputTextfieldView.hidden = YES;
    //hide all table views
    self.searchResultTableView.hidden = YES;
    self.favoritesTableView.hidden = YES;
    self.geoSearchTableView.hidden = YES;

    switch(self.currentType){
        case MBStationSearchTypeTextSearch:
            //buttons state
            [self.triangleErrorView setX:CGRectGetMidX(self.featureSearchButton.frame)-self.triangleErrorView.sizeWidth/2-15];
            [self.searchErrorView setHeaderText:@"Keine Ergebnisse gefunden" bodyText:nil];
            [self changeButtonStateToActive:self.featureSearchButton];
            
            self.stationSearchInputField.hidden = NO;
            self.triangleInputTextfieldView.hidden = NO;
            break;
        case MBStationSearchTypeFavorite:{
            self.triangleErrorView.hidden = NO;
            [self.triangleErrorView setX:CGRectGetMidX(self.featureFavoriteButton.frame)-self.triangleErrorView.sizeWidth/2-15];
            [self.searchErrorView setHeaderText:@"Ihre Favoritenliste ist leer." bodyText:@"Bestimmen Sie Ihre favorisierten Stationen einfach mithilfe des Stern-Icons in der Suche oder Umgebungsanzeige."];
            [self changeButtonStateToActive:self.featureFavoriteButton];

            self.favoritesTableView.hidden = NO;
            [self.favoritesTableView reloadData];

            NSArray* fav = [[MBFavoriteStationManager client] favoriteStationsList];
            if(fav.count == 0){
                self.searchErrorView.hidden = NO;
            }
            break;
        }
        case MBStationSearchTypeLocation:
            self.triangleErrorView.hidden = NO;
            [self.triangleErrorView setX:CGRectGetMidX(self.featureLocationButton.frame)-self.triangleErrorView.sizeWidth/2-15];
            [self changeButtonStateToActive:self.featureLocationButton];

            self.geoSearchTableView.hidden = NO;
            [self.geoSearchTableView reloadData];

            [self refreshLocationSearch];
            break;
    }
    [self.view setNeedsLayout];
}

-(void)changeButtonStateToActive:(UIButton*)btn{
    [self.featureSearchButton viewWithTag:CONTENT_VIEW_TAG].hidden = self.featureSearchButton != btn;
    [self.featureFavoriteButton viewWithTag:CONTENT_VIEW_TAG].hidden = self.featureFavoriteButton != btn;
    [self.featureLocationButton viewWithTag:CONTENT_VIEW_TAG].hidden = self.featureLocationButton != btn;
    
    self.featureSearchButton.accessibilityTraits = UIAccessibilityTraitButton;
    self.featureFavoriteButton.accessibilityTraits = UIAccessibilityTraitButton;
    self.featureLocationButton.accessibilityTraits = UIAccessibilityTraitButton;
    btn.accessibilityTraits |= UIAccessibilityTraitSelected;
}

-(void)refreshLocationSearch{
    [self updateErrorViewForLocation];
    if(self.locationManagerAuthorized){
        self.triggerSearchAfterLocationUpdate = YES;
        [[MBGPSLocationManager sharedManager] getOneShotLocationUpdate];
        [self updateErrorViewForLocation];
    }
}

-(void)updateErrorViewForLocation{
    if(self.currentType == MBStationSearchTypeLocation){
        //NSLog(@"updateErrorViewForLocation...");
        self.searchErrorView.hidden = NO;
        self.geoSearchTableView.hidden = YES;
        if(!self.locationManagerAuthorized){
            //NSLog(@"...not authorized");
            [self.searchErrorView setHeaderText:nil bodyText:@"Haltestellen in Ihrer Umgebung werden Ihnen nur angezeigt, wenn Sie den Ortungsdienst aktivieren." actionText:@"Jetzt erlauben" actionType:MBErrorActionTypeRequestLocation];
        } else {
            if([MBGPSLocationManager sharedManager].isGettingOneShotLocation){
                //NSLog(@"...getting location");
                [self.searchErrorView setHeaderText:nil bodyText:@"Bitte warten Sie bis Ihre Position bestimmt und die Daten geladen wurden."];
            } else {
                if(!self.currentUserPosition){
                    //NSLog(@"...no location");
                    [self.searchErrorView setHeaderText:nil bodyText:@"Haltestellen in Ihrer Umgebung werden Ihnen nur angezeigt, wenn Ihre Position bestimmt werden konnte." ];
                } else {
                    if(_requestDBOngoing > 0){
                        //NSLog(@"...loading data");
                        [self.searchErrorView setHeaderText:nil bodyText:@"Lade Daten..." ];
                    } else {
                        if(self.searchResultGeoArray == nil){
                            [self.searchErrorView setHeaderText:@"Ladefehler" bodyText:@"Daten konnten nicht geladen werden. Bitte versuchen Sie es später erneut." actionText:@"Erneut versuchen" actionType:MBErrorActionTypeReload];
                        } else if(self.searchResultGeoArray.count == 0){
                            //NSLog(@"...no data");
                            [self.searchErrorView setHeaderText:nil bodyText:@"Keine Ergebnisse gefunden"];
                        } else {
                            //NSLog(@"...got data");
                            self.searchErrorView.hidden = YES;
                            [self.geoSearchTableView reloadData];
                            self.geoSearchTableView.hidden = NO;
                        }
                    }
                }
            }
        }
    }
}

-(void)searchErrorDidPressActionButton:(MBSearchErrorView *)errorView withAction:(MBErrorActionType)action{
    if(action == MBErrorActionTypeRequestLocation){
        [self locationAllowButtonTapped];
    } else if(action == MBErrorActionTypeReload){
        if(self.currentType == MBStationSearchTypeLocation){
            [self refreshLocationSearch];
        } else if(self.currentType == MBStationSearchTypeTextSearch){
            [self didEndEditing:self.stationSearchInputField];
        }
    }
}



-(void)searchResultDelete:(UIButton*)btn{
    self.stationSearchInputField.delegate = nil;//need to nil the delegate, otherwise the display of the alert will trigger endEditing events in textfield
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Suchhistorie" message:@"Möchten Sie die Suchhistorie löschen?" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Abbrechen" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        self.stationSearchInputField.delegate = self;
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Löschen" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:SETTINGS_LAST_SEARCHES];
        btn.hidden = YES;
        [self fillPickerWithLastStations];
        [self.searchResultTableView reloadData];
        self.stationSearchInputField.delegate = self;
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}


- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}


-(void)locationAllowButtonTapped{
    CLAuthorizationStatus status = [[MBGPSLocationManager sharedManager] authStatus];
    if(status == kCLAuthorizationStatusNotDetermined){
        [[MBGPSLocationManager sharedManager] requestAuthorization];
    } else {
        [MBUrlOpening openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

#pragma mark OepnvDelegate
- (void)showTimetableViewController:(UIViewController *)vc
{
    [self.navigationController pushViewController:vc animated:YES];
}



- (void)mapFloatingBtnPressed
{
    [MBMapConsent.sharedInstance showConsentDialogInViewController:self completion:^{
        if([self mapNearbyStations].count == 0){
            //no stations, force update
            self.mapRequestedSearchUpdate = YES;
            self.triggerSearchAfterLocationUpdate = YES;
            [[MBGPSLocationManager sharedManager] getOneShotLocationUpdate];
            //station list in map will be updated when both requests (DB+Hafas finished), see updateMapWithStations
        }
        
        MBMapViewController* vc = [MBMapViewController new];
        vc.delegate = self;
        [vc configureWithDelegate];
        
        if(self.mapRequestedSearchUpdate){
            self.mapViewController = vc;
        }
        [MBTrackingManager trackActions:@[@"tab_navi", @"tap", @"map_button"]];

        MBStationNavigationViewController* nav = [[MBStationNavigationViewController alloc] initWithRootViewController:vc];
        nav.hideEverything = YES;
        [nav setShowRedBar:NO];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:nav animated:YES completion:nil];
    }];
}

-(BOOL)mapShouldCenterOnUser{
    return YES;
}
-(BOOL)mapDisplayFilter{
    return NO;
}

-(MBMarker *)mapSelectedMarker{
    return self.mapNearbyStations.firstObject;
}

- (NSArray *)mapNearbyStations {
    if(self.searchResultGeoArray.count > 0){
        NSMutableArray* list = [NSMutableArray arrayWithCapacity:self.searchResultGeoArray.count];
        for(MBStationFromSearch* station in self.searchResultGeoArray){
            [list addObject:[MBMarkerMerger markerForSearchStation:station]];
        }
        return list;
    }
    return nil;
}

-(void)fillPickerWithLastStations{
    //initial state: load the main stations into picker view or the last searches?
    NSArray<NSDictionary*> *lastRequestedStations = [self lastRequestedStations];
    if (lastRequestedStations.count > 0) {
        self.searchResultHeaderTitle.text = @"Suchverlauf";
        NSMutableArray<MBStationFromSearch*>* list = [NSMutableArray arrayWithCapacity:lastRequestedStations.count];
        for(NSDictionary* dict in lastRequestedStations){
            MBStationFromSearch* s = [[MBStationFromSearch alloc] initWithDict:dict];
            [list addObject:s];
        }
        self.searchResultTextArray = list;
        self.searchResultListFromSearchHistory = true;
        self.searchResultDeleteButton.hidden = NO;
    } else {
        self.searchResultHeaderTitle.text = @"Suchergebnisse";
        self.searchResultListFromSearchHistory = false;
        self.searchResultTextArray = @[];
        self.searchResultDeleteButton.hidden = YES;
    }
}



- (void)didTapOnImprintLink:(id)sender
{
    MBImprintViewController *imprintViewController =  [[MBImprintViewController alloc] init];
    imprintViewController.title = @"Impressum";
    imprintViewController.url = @"impressum";
    imprintViewController.openAsModal = YES;
    
    MBNavigationController *imprintNavigationController = [[MBNavigationController alloc] initWithRootViewController:imprintViewController];
    imprintNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    [MBTrackingManager trackState:@"imprint"];
    
    [self presentViewController:imprintNavigationController animated:YES completion:nil];
}

- (void)didTapOnDatasecLink:(id)sender
{
    [MBStationSearchViewController displayDataProtectionOn:self];
}

+(void)displayDataProtectionOn:(nonnull UIViewController*)vc{
    MBImprintViewController *imprintViewController =  [[MBImprintViewController alloc] init];
    imprintViewController.title = @"Datenschutz";
    imprintViewController.url = @"datenschutz";
    imprintViewController.openAsModal = YES;
    
    MBNavigationController *imprintNavigationController = [[MBNavigationController alloc] initWithRootViewController:imprintViewController];
    imprintNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;

    [MBTrackingManager trackState:@"data_protection"];

    [vc presentViewController:imprintNavigationController animated:YES completion:nil];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self.mapFloatingBtn setGravityRight:10];
    
    CGFloat bottomSafeOffset = self.view.safeAreaInsets.bottom;
    [self.mapFloatingBtn setGravityBottom:15+self.imprintButton.sizeHeight+bottomSafeOffset];
    
    [self.footerButtons setGravityBottom:bottomSafeOffset];
    //center the buttons in the footerButtons
    [self.imprintButton setGravity:Left withMargin:(int)((self.view.sizeWidth-(self.imprintButton.sizeWidth+20+self.datenschutzButton.sizeWidth))/2)];
    [self.imprintButton setGravity:Bottom withMargin:10];
    [self.datenschutzButton setRight:self.imprintButton withPadding:20];
    [self.datenschutzButton setGravity:Bottom withMargin:10];

    
    self.backgroundImage.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);

    if(self.currentType == MBStationSearchTypeLocation || self.currentType == MBStationSearchTypeFavorite){
        MBStationListTableView* tv = (self.currentType == MBStationSearchTypeLocation) ? self.geoSearchTableView : self.favoritesTableView;
        UIView* triangleView = tv.triangleView;
        [tv setBelow:self.featureButtonArea withPadding:20-triangleView.sizeHeight];
        [self.searchErrorView setBelow:self.featureButtonArea withPadding:20];
        
        [tv setHeight:self.footerButtons.originY-tv.originY];
        [triangleView setY:-triangleView.sizeHeight];
        if(self.currentType == MBStationSearchTypeFavorite){
            [triangleView setGravityLeft:(int)(tv.sizeWidth/2-triangleView.sizeWidth/2)];
        } else {
            [triangleView setGravityLeft:(int)(CGRectGetMidX(self.featureLocationButton.frame)-triangleView.sizeWidth/2-self.geoSearchTableView.frame.origin.x)];
        }
    } else if(self.currentType == MBStationSearchTypeTextSearch) {
        if(self.searchResultTableView.hidden){
            [self.triangleInputTextfieldView setAbove:self.stationSearchInputField withPadding:0];
            [self.triangleInputTextfieldView setGravityLeft:(int)(self.featureSearchButton.center.x-self.triangleInputTextfieldView.sizeWidth/2)];
        }
    }
}



- (void) showAlertForDeniedLocationServices
{
    NSString *errorMessage = @"Aktivieren Sie Ihren Standort im Bereich Einstellungen, um Bahnhöfe in Ihrer Nähe zu finden.";
    NSString *errorHeadline = @"Standortangabe ist deaktiviert";
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:errorHeadline message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Einstellungen" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //open settings app
        [MBUrlOpening openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Nein, danke" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}


- (NSArray*) lastRequestedStations
{
    NSArray *data = [NSUserDefaults.standardUserDefaults objectForKey:SETTINGS_LAST_SEARCHES];
    if (data) {
        return data;
    }
    return @[];
}

- (void) updateLastRequestedStations:(MBStationFromSearch*)station
{
    if(station.isInternalLink){
        //don't update the list of last searched stations
        return;
    }
    NSMutableArray *archivedStations = [[self lastRequestedStations] mutableCopy];
    
    BOOL contains = NO;

    NSDictionary* storedDict = nil;
    for(NSDictionary *dictionary in archivedStations) {
        if (dictionary[@"id"] && [dictionary[@"id"] longValue]  == [station.stationId longValue]) {
            contains = YES;
        } else if(dictionary[@"eva_ids"]){
            NSArray* evaIds = dictionary[@"eva_ids"];
            if(evaIds.count >  0 && [station.eva_ids.firstObject isEqualToString:evaIds.firstObject]){
                contains = YES;
            }
        }
        if(contains){
            storedDict = dictionary;
            break;
        }
    }
    
    NSDictionary* stationDict = station.dictRepresentation;
    
    if (!contains) {
        [archivedStations insertObject:stationDict atIndex:0];
        if (archivedStations.count > 10) {
            [archivedStations removeLastObject];
        }
    } else {
        //remove old entry, insert new one at the top
        [archivedStations removeObject:storedDict];
        [archivedStations insertObject:stationDict atIndex:0];
    }
    
    if(self.currentType == MBStationSearchTypeTextSearch && !self.searchResultTableView.hidden){
        self.searchResultDeleteButton.hidden = archivedStations.count == 0;
    }
    [NSUserDefaults.standardUserDefaults setObject:archivedStations forKey:SETTINGS_LAST_SEARCHES];
    
}

#define MAX_NUMBER_OF_RESULTS 100


-(void)setRequestDBOngoing:(NSInteger)requestDBOngoing{
    if(requestDBOngoing < 0){
        requestDBOngoing = 0;
    }
    _requestDBOngoing = requestDBOngoing;
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.requestDBOngoing == 0){
            [self.loadActivity stopAnimating];
            if(self.mapRequestedSearchUpdate){
                [self updateMapWithStations];
            }
        } else {
            [self.loadActivity startAnimating];
        }
        [self updateErrorViewForLocation];
    });
}

-(void)updateMapWithStations{
    self.mapRequestedSearchUpdate = NO;
    [self.mapViewController configureWithDelegate];
    self.mapViewController = nil;
}

- (void) updateSearchResults:(NSArray<MBStationFromSearch*>*)stationList searchTerm:(NSString*)searchTerm typeLocation:(BOOL)isLocation
{
    NSArray<MBStationFromSearch*>* results = nil;
    if(!stationList){
        //failure in search: display error
        results = nil;
    } else if(stationList && stationList.count == 0){
        //no results in search
        results = @[];
    } else {
        //got some results
        results = stationList;
        //calculate distance to user
        CLLocation *userLocation = self.currentUserPosition;
        if(userLocation){
            for(MBStationFromSearch* s in results){
                CLLocationDistance dist = 0;
                CLLocation *stationLocation = [[CLLocation alloc] initWithLatitude:s.coordinate.latitude longitude:s.coordinate.longitude];
                dist = [userLocation distanceFromLocation:stationLocation];
                s.distanceInKm = [NSNumber numberWithDouble:dist/1000.];
            }
        }
        if(userLocation && isLocation){
            results = [results sortedArrayUsingComparator:^NSComparisonResult(MBStationFromSearch* obj1, MBStationFromSearch* obj2) {
                NSNumber* dist1 = obj1.distanceInKm;
                NSNumber* dist2 = obj2.distanceInKm;
                return [dist1 compare:dist2];
            }];
        }
        
        if(results.count > MAX_NUMBER_OF_RESULTS){
            results = [results subarrayWithRange:NSMakeRange(0, MAX_NUMBER_OF_RESULTS)];
        }
        
        if(isLocation){
            //special handling: show the next DB-station at the top
            NSMutableArray* resultsWithWithDBFirst = [NSMutableArray arrayWithCapacity:results.count];
            BOOL addedFirstStation = NO;
            for(MBStationFromSearch* s in results){
                if(s.isOPNVStation){
                    [resultsWithWithDBFirst addObject:s];
                } else {
                    if(!addedFirstStation){
                        [resultsWithWithDBFirst insertObject:s atIndex:0];
                        addedFirstStation = YES;
                    } else {
                        [resultsWithWithDBFirst addObject:s];
                    }
                }
            }
            results = resultsWithWithDBFirst;
        }
    }
    
//    NSLog(@"updateSearchresults: %d, %@",isLocation, results);
    
    if(isLocation){
        self.searchResultGeoArray = results;
    } else {
        //must be text search
        self.searchResultListFromSearchHistory = false;
        self.searchResultTextArray = results;
        self.searchResultDeleteButton.hidden = YES;
    }
}


-(void)setSearchResultTextArray:(NSArray<MBStationFromSearch*> *)searchResultTextArray{
    self.longPressStation = nil;
    BOOL invalidSearchResult = NO;
    if(searchResultTextArray){
        _searchResultTextArray = [[NSArray alloc] initWithArray:searchResultTextArray copyItems:YES];
    } else {
        _searchResultTextArray = nil;
        invalidSearchResult = YES;
    }
    [self.searchResultTableView reloadData];
    if(self.currentType == MBStationSearchTypeTextSearch){
        if(invalidSearchResult){
            NSLog(@"invalid results");
            [self.searchErrorView setHeaderText:@"Ladefehler" bodyText:@"Daten konnten nicht geladen werden. Bitte versuchen Sie es später erneut." actionText:@"Erneut versuchen" actionType:MBErrorActionTypeReload];
            self.searchErrorView.hidden = NO;
        } else if(searchResultTextArray && searchResultTextArray.count == 0 && self.stationSearchInputField.text.length >= 2){
            [self.searchErrorView setHeaderText:@"Keine Ergebnisse gefunden" bodyText:nil];
            self.searchErrorView.hidden = NO;
        } else {
            self.searchErrorView.hidden = YES;
        }
    }
    if(!invalidSearchResult && [self tableView:self.searchResultTableView numberOfRowsInSection:0] > 0){
        [self.searchResultTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}
-(void)setSearchResultGeoArray:(NSArray<MBStationFromSearch *> *)searchResultGeoArray{
    self.longPressStation = nil;
    if(searchResultGeoArray){
        _searchResultGeoArray = [[NSArray alloc] initWithArray:searchResultGeoArray copyItems:YES];
    } else {
        _searchResultGeoArray = nil;
    }
    [self.geoSearchTableView reloadData];
}

- (void) openStation:(NSDictionary*)stationDict andShowWagenstand:(NSDictionary*)wagenstandUserInfo
{
    self.wagenstandUserInfo = wagenstandUserInfo;
    MBStationFromSearch* station = [[MBStationFromSearch alloc] initWithDict:stationDict];
    [self didSelectStation:station];
}

- (void) openStationAndShowFacility:(NSDictionary*)stationDict
{
    self.startWithFacilityView = YES;
    MBStationFromSearch* station = [[MBStationFromSearch alloc] initWithDict:stationDict];
    [self didSelectStation:station];
}


#pragma -
#pragma MBStationPickerViewDelegates

-(void)openStation:(NSDictionary *)stationDict{
    MBStationFromSearch* station = [[MBStationFromSearch alloc] initWithDict:stationDict];
    [self didSelectStation:station startWithDepartures:YES];
}

-(void)popToSearchViewController{
    AppDelegate* app = (AppDelegate*) UIApplication.sharedApplication.delegate;
    if(MBRootContainerViewController.currentlyVisibleInstance){
        [MBRootContainerViewController.currentlyVisibleInstance goBackToSearchAnimated:false clearBackHistory:false];
    } else {
        //the user is viewing a departure from H0
        [app.viewController.navigationController popToRootViewControllerAnimated:NO];
    }
}

-(void)openStationFromInternalLink:(MBStationFromSearch *)station  withBackState:(MBBackNavigationState*)state{
    [self popToSearchViewController];
    NSLog(@"adding to backNavigationList: %@",state);
    [self.backNavigationList addObject:state];
    [self didSelectStation:station];
}
-(BOOL)allowBackFromStation{
    return self.backNavigationList.count > 0;
}
-(void)goBackToPreviousStation{
    MBBackNavigationState* state = self.backNavigationList.lastObject;
    NSLog(@"go back to the station from backNavigationList: %@",state);
    if(state){
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.trainJourneyToRestore = state;
        [self.backNavigationList removeLastObject];
        [self popToSearchViewController];
        [(MBStationNavigationViewController *)self.navigationController hideNavbar:true];
        [(MBStationNavigationViewController *)self.navigationController setShowRedBar:false];
        [(MBStationNavigationViewController *)self.navigationController setHideEverything:true];

        MBStationFromSearch* station = [[MBStationFromSearch alloc] init];
        station.isOPNVStation = state.isOPNVStation;
        station.isInternalLink = true;
        station.isGoingBack = true;
        station.isFreshStationFromSearch = true;//not really, but we need to safe the request here
        station.coordinate = state.position;
        station.eva_ids = state.evaIds;
        station.title = state.title;
        station.stationId = state.mbId;
        [self didSelectStation:station startWithDepartures:true];
        [MBProgressHUD hideHUDForView:self.view animated:NO];
    } else {
        //there is no station to go back to, return to search controller
        [self popToSearchViewController];
    }
}


- (void) didSelectStation:(MBStationFromSearch *)station{
    [self didSelectStation:station startWithDepartures:NO];
}

- (void) didSelectStation:(MBStationFromSearch *)stationFromSearch startWithDepartures:(BOOL)startWithDepartures
{
    if(_didSelectStationRunning){
        NSLog(@"ignored %@, waiting for %@",stationFromSearch,_selectedStation);
        return;
    }
    NSLog(@"didSelectStation: %@",stationFromSearch);
    _didSelectStationRunning = YES;
    [[MBTutorialManager singleton] hideTutorials];

    [self updateLastRequestedStations:stationFromSearch];
    [self.stationSearchInputField resignFirstResponder];
    
    if([MBStationFromSearch needToUpdateEvaIdsForStation:stationFromSearch]){
        self.view.userInteractionEnabled = false;
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [stationFromSearch updateEvaIds:^(BOOL success) {
            self.view.userInteractionEnabled = true;
            [MBProgressHUD hideHUDForView:self.view animated:NO];
            [self loadStation:stationFromSearch startWithDepartures:startWithDepartures];
        }];
    } else {
        // not a stored station or we have no stada: continue with stored data
        [self loadStation:stationFromSearch startWithDepartures:startWithDepartures];
    }
}

-(void)loadStation:(MBStationFromSearch*)stationFromSearch startWithDepartures:(BOOL)startWithDepartures{
    BOOL stadaMissing = NO;
    NSNumber* stationId = stationFromSearch.stationId;
    if(!stationId){
        NSLog(@"no STADA id, fallback to eva");
        stadaMissing = YES;
        stationId = [NSNumber numberWithInteger:stationFromSearch.eva_ids.firstObject.integerValue];
    }

    MBStation* station = [[MBStation alloc] initWithId:stationId name:stationFromSearch.title evaIds:stationFromSearch.eva_ids location:stationFromSearch.location];
    
    self.selectedStation = station;

    [SentrySDK configureScope:^(SentryScope *_Nonnull scope) {
        [scope setContextValue:@{
            @"stationId" : (station.mbId == nil ? @0 : station.mbId),
            @"station" : (station.title == nil ? @"" : station.title)
        } forKey:@"station"];
    }];

    if(stationFromSearch.isOPNVStation){
        NSLog(@"opening an opnv station");
        switch(self.currentType){
            case MBStationSearchTypeTextSearch:
                [MBTrackingManager trackActions:@[@"h0", @"tap", @"abfahrt_suche_opnv"]];
                break;
            case MBStationSearchTypeFavorite:
                [MBTrackingManager trackActions:@[@"h0", @"tap", @"abfahrt_favoriten_opnv"]];
                break;
            case MBStationSearchTypeLocation:
                [MBTrackingManager trackActions:@[@"h0", @"tap", @"abfahrt_naehe_opnv"]];
                break;
        }

        NSString* idString = stationFromSearch.eva_ids.firstObject;
        NSString* stationTitle = stationFromSearch.title;
        MBTimetableViewController *timeVC = [[MBTimetableViewController alloc] initWithOPNVAndAllowBack:self.backNavigationList.count > 0];
        timeVC.oepnvOnly = YES;
        timeVC.includeLongDistanceTrains = false;
        timeVC.hafasStation = [MBOPNVStation stationWithId:idString name:stationTitle];
        [self.navigationController pushViewController:timeVC animated:!stationFromSearch.isGoingBack];
        _didSelectStationRunning = NO;
        return;
    }
    
    if(stadaMissing){
        NSLog(@"FAILURE, cant load station without stada-id");
        _didSelectStationRunning = NO;
        return;
    }
    
    switch(self.currentType){
        case MBStationSearchTypeTextSearch:
            [MBTrackingManager trackActions:@[@"h0", @"tap", @"abfahrt_suche_bhf"]];
            break;
        case MBStationSearchTypeFavorite:
            [MBTrackingManager trackActions:@[@"h0", @"tap", @"abfahrt_favoriten_bhf"]];
            break;
        case MBStationSearchTypeLocation:
            [MBTrackingManager trackActions:@[@"h0", @"tap", @"abfahrt_naehe_bhf"]];
            break;
    }

    
    self.stationMapController = [[MBRootContainerViewController alloc] initWithRootBackButton];
    self.stationMapController.startWithFacility = self.startWithFacilityView;
    self.stationMapController.allowBackFromStation = self.allowBackFromStation;
    self.startWithFacilityView = false;
    self.stationMapController.startWithDepartures = startWithDepartures;
    if(startWithDepartures){
        //ensure that timetable is setup early
        self.stationMapController.preloadedDepartures = station.stationEvaIds;
        [[TimetableManager sharedManager] reloadTimetableWithEvaIds:station.stationEvaIds];
    }
    
    self.stationMapController.station = station;
    
    MBStationNavigationViewController *navigationController = (MBStationNavigationViewController*)self.navigationController;
    
    self.stationMapController.station = station;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [navigationController pushViewController:self.stationMapController animated:!stationFromSearch.isGoingBack];
        
        if(self.wagenstandUserInfo){
            //opened station from a wagenstand reminder
            [MBTrainPositionViewController showWagenstandForUserInfo:self.wagenstandUserInfo fromViewController:self.stationMapController];
            self.wagenstandUserInfo = nil;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.view.hidden = NO;
            self.didSelectStationRunning = NO;
        });
    });
}

- (void) freeStationAndClearBackHistory:(BOOL)clearBackHistory
{
    [[TimetableManager sharedManager] resetTimetable];
    [self.stationMapController cleanup];
    self.stationMapController = nil;
    self.selectedStation = nil;
    [SentrySDK configureScope:^(SentryScope *_Nonnull scope) {
        [scope removeContextForKey:@"station"];
    }];
    if(clearBackHistory){
        NSLog(@"clearing backNavigationList");
        [self.backNavigationList removeAllObjects];
        self.trainJourneyToRestore = nil;
    }
    NSLog(@"freeStation finished");
}

- (void) triggerSearchAround
{
    if(self.mapRequestedSearchUpdate){
        [self triggerSearchWithQuery:nil andUseLocation:YES];
        return;
    }
    
    if(!self.isVisible){
        // NSLog(@"triggerSearchAround ignored");
        return;//search around might be triggered when we select a station
    }
    
    if(self.currentType != MBStationSearchTypeLocation){
        return;
    }
    
    [self triggerSearchWithQuery:nil andUseLocation:YES];
}

- (void) triggerSearchWithQuery:(NSString*)searchTerm andUseLocation:(BOOL)useLocation
{
    //[self.loadActivity.superview bringSubviewToFront:self.loadActivity];
    MBStationSearchType lastSearchType = self.currentType;
    NSString* searchTermCopy = [searchTerm copy];
    if(useLocation){
        if(!self.currentUserPosition){
            return;
        }
        CLLocationCoordinate2D geo = self.currentUserPosition.coordinate;
        self.requestDBOngoing += 1;
        [[MBRISStationsRequestManager sharedInstance] searchStationByGeo:geo success:^(NSArray<MBStationFromSearch*>* stationList) {
            if(self.currentType != lastSearchType){
                NSLog(@"WARNING; SEARCH TYPE CHANGED, IGNORE REQUEST RESULTS");
            } else {
                [self updateSearchResults:stationList searchTerm:searchTerm typeLocation:useLocation];
            }
            self.requestDBOngoing -= 1;
        } failureBlock:^(NSError *error) {
            if(self.currentType != lastSearchType){
                NSLog(@"WARNING; SEARCH TYPE CHANGED, IGNORE REQUEST RESULTS");
            } else {
                [self updateSearchResults:nil searchTerm:searchTerm typeLocation:useLocation];
            }
            self.requestDBOngoing -= 1;
        }];
    } else {
        self.requestDBOngoing += 1;
        [[MBRISStationsRequestManager sharedInstance] searchStationByName:searchTerm success:^(NSArray<MBStationFromSearch*>* stationList) {
            if(self.currentType != lastSearchType){
                NSLog(@"WARNING; SEARCH TYPE CHANGED, IGNORE REQUEST RESULTS");
            } else if(![searchTermCopy isEqualToString:self.stationSearchInputField.text]){
                NSLog(@"WARNING; SEARCH TEXT CHANGED, IGNORE REQUEST RESULTS for %@",searchTermCopy);
            } else {
                [self updateSearchResults:stationList searchTerm:searchTerm typeLocation:useLocation];
            }
            self.requestDBOngoing -= 1;
        } failureBlock:^(NSError *error) {
            if(self.currentType != lastSearchType){
                NSLog(@"WARNING; SEARCH TYPE CHANGED, IGNORE REQUEST RESULTS");
            } else if(![searchTermCopy isEqualToString:self.stationSearchInputField.text]){
                NSLog(@"WARNING; SEARCH TEXT CHANGED, IGNORE REQUEST RESULTS for %@",searchTermCopy);
            } else {
                [self updateSearchResults:nil searchTerm:searchTerm typeLocation:useLocation];
            }
            self.requestDBOngoing -= 1;
        }];
    }
}

#pragma -
#pragma Notification callback

-(void)enableTextSearch{
    NSLog(@"enable text search...");
    self.mapFloatingBtn.hidden = YES;
    self.logoText.hidden = YES;
    self.logoImage.hidden = YES;
    self.footerButtons.hidden = YES;
    self.featureButtonArea.hidden = YES;
    self.triangleInputTextfieldView.hidden = YES;

    [UIView animateWithDuration:0.25 animations:^{
        if(SCALEFACTORFORSCREEN != 1.0){
            [self.stationSearchInputField setGravityTop:60];
        } else {
            CGFloat topSafeOffset = 0.0;
            [self.stationSearchInputField setGravityTop:15+60+topSafeOffset];
        }
    } completion:^(BOOL finished) {
        [self.closeButton setAbove:self.stationSearchInputField withPadding:7];
        [self.closeButton setGravityLeft:5];
        self.closeButton.hidden = NO;
        [self.searchResultTableView setBelow:self.stationSearchInputField withPadding:54];
        [self.searchErrorView setBelow:self.stationSearchInputField withPadding:54];
        [self.searchResultDeleteButton setBelow:self.stationSearchInputField withPadding:2];
        [self.searchResultHeaderTitle setBelow:self.stationSearchInputField withPadding:10];
        self.searchResultHeaderTitle.hidden = NO;
        //self.searchResultDeleteButton.hidden = NO;
        self.searchResultTableView.hidden = NO;
        [self fillPickerWithLastStations];
        
        [self.view addSubview:self.loadActivity];
        [self.loadActivity setGravityRight:self.stationSearchInputField.frame.origin.x+5];
        [self.loadActivity setBelow:self.stationSearchInputField withPadding:12];
    }];
}


- (void)keyBoardDidShow:(NSNotification*)notification
{
    [self updateSearchResultTableWithKeyboardChange:notification];
}

-(void)updateSearchResultTableWithKeyboardChange:(NSNotification*)notification{
    //modify searchresultstableview so that it ends just above the keyboard
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    CGFloat yTable = self.searchResultTableView.frame.origin.y;
    UIView* parent = self.searchResultTableView.superview;
    while(parent != nil){
        yTable += parent.frame.origin.y;
        parent = parent.superview;
    }
    
    self.searchResultTableView.height = keyboardFrameBeginRect.origin.y-yTable;
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.stationSearchInputField);
}


- (void)keyBoardWillHide:(NSNotification*)notification
{
    [self updateSearchResultTableWithKeyboardChange:notification];
}

- (void)dismissKeyboard:(UITapGestureRecognizer*)sender
{
    NSLog(@"dismissKeyboard");
    if (sender.state == UIGestureRecognizerStateEnded){
        [self.stationSearchInputField resignFirstResponder];
    }
}

#pragma -
#pragma App Lifecyle Events
- (void)handleEnterForeground:(NSNotification*)aNotification
{
    //NSLog(@"GPS enter foreground, get location update");
    [[MBGPSLocationManager sharedManager] getOneShotLocationUpdate];
    [self updateErrorViewForLocation];
}

#pragma -
#pragma UITextfieldInputDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString* newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self updateInputAccessoryForString:newString];

    // manually delay search to make sure user stopped typing
    // otherwise we send a request on every character
    [NSRunLoop cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(didEndEditing:) withObject:textField afterDelay:0.75];
    return YES;
}

- (void) didEndEditing:(UITextField*)textField //this called with a delay (see above)
{
    if(self.currentType != MBStationSearchTypeTextSearch || self.searchResultTableView.hidden){
        return;
    }
    
    // trigger an auto suggested search when user stops typing
    if (textField.text.length >= kMinCharactedsSuggestionTreshold) {
        self.searchResultHeaderTitle.text = @"Suchergebnisse";
        self.searchResultDeleteButton.hidden = YES;
        [self triggerSearchWithQuery:textField.text andUseLocation:NO];
    } else if (textField.text.length  == 0) {
        [self fillPickerWithLastStations];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}


-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    
    [MBTrackingManager trackActions:@[@"h0", @"tap", @"suche"]];
    
    [self enableTextSearch];
    
    
    return YES;
}

-(BOOL)accessibilityPerformEscape{
    if(self.featureButtonArea.hidden){
        [self closeTextInputMode];
        return YES;
    }
    return [super accessibilityPerformEscape];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    //
}

- (void)textFieldDidEndEditing:(UITextField *)textField;
{

}

-(void)closeTextInputMode{
    self.closeButton.hidden = YES;

    self.searchErrorView.hidden = YES;
    if(self.locationManagerAuthorized){
        self.mapFloatingBtn.hidden = NO;
    }
    self.logoText.hidden = NO;
    self.logoImage.hidden = NO;
    self.footerButtons.hidden = NO;
    
    self.searchResultHeaderTitle.hidden = YES;
    self.searchResultDeleteButton.hidden = YES;
    
    self.featureButtonArea.hidden = NO;
    self.triangleInputTextfieldView.hidden = NO;
    
    self.stationSearchInputField.text = @"";
    [self updateInputAccessoryForString:@""];
    
    [self.stationSearchInputField setBelow:self.featureButtonArea withPadding:20];
    self.searchResultTableView.hidden = YES;
    
    [self.loadActivity removeFromSuperview];
    
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.logoText);
}

- (void) didReceiveLocationUpdate:(NSNotification*)notification;
{
    //NOTE: this method is the only place where currentUserPosition is manipulated!
    
    //NSLog(@"GPS didReceiveLocationUpdate:%@, isProce %d",notification,self.isProcessingLocationUpdate);
    if(self.isProcessingLocationUpdate){
        //may end in an endless loop, ignore this update
        return;
    }
    self.isProcessingLocationUpdate = YES;
    if (notification.userInfo) {
        NSDictionary *payload = notification.userInfo;
        CLLocation *location = [payload objectForKey:kGPSNotifLocationPayload];
        
        if (location && [location.timestamp timeIntervalSinceNow] > -60.0) {
            // The value is not older than 60 sec and the user moved at least 10meters
            BOOL coordinateChanged = NO;
            if(!self.currentUserPosition || [self.currentUserPosition distanceFromLocation:location] >= 10.0){
                coordinateChanged = YES;
            }
            self.currentUserPosition = location;
            NSLog(@"GPS coordinate changed? %d",coordinateChanged);
            if(coordinateChanged || self.triggerSearchAfterLocationUpdate){
                self.triggerSearchAfterLocationUpdate = NO;
                self.searchResultGeoArray = @[];
                [self triggerSearchAround];
            }
        } else {
            NSLog(@"GPS outdated, last user timestamp %f",[self.currentUserPosition.timestamp timeIntervalSinceNow]);
            if(!self.currentUserPosition || (self.currentUserPosition && [self.currentUserPosition.timestamp timeIntervalSinceNow] < -60)){
                //
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.currentUserPosition = nil;
                });
            }
        }
    } else {
        if(!self.currentUserPosition || (self.currentUserPosition && [self.currentUserPosition.timestamp timeIntervalSinceNow] < -60)){
            //
            dispatch_async(dispatch_get_main_queue(), ^{
                self.currentUserPosition = nil;
            });
        }
    }
    self.isProcessingLocationUpdate = NO;
}

-(void)setCurrentUserPosition:(CLLocation *)currentUserPosition{
    _currentUserPosition = currentUserPosition;
    dispatch_async(dispatch_get_main_queue(), ^{
        if(!currentUserPosition){
            self.searchResultGeoArray = @[];
        }
        [self updateErrorViewForLocation];
    });
}

- (void) didReceiveLocationAuthorizationUpdate:(NSNotification*)notification;
{
    //callback for event gps.authorization
    if (notification.userInfo) {
        NSDictionary *payload = notification.userInfo;
        NSNumber *authorization = [payload objectForKey:@"available"];
        BOOL isAuthorized = [authorization boolValue];
        
        self.locationManagerAuthorized = isAuthorized;
        //NSLog(@"GPS auth update %d, currentUser is %@",isAuthorized,self.currentUserPosition);
        if (!self.currentUserPosition && self.viewAppeared) {
            [[MBGPSLocationManager sharedManager] getOneShotLocationUpdate];
        }
        [self updateErrorViewForLocation];
    }
}

-(void)setLocationManagerAuthorized:(BOOL)locationManagerAuthorized{
    // NSLog(@"setLocationmanagerAuthorized %d",locationManagerAuthorized);
    //BOOL changed = _locationManagerAuthorized != locationManagerAuthorized;
    _locationManagerAuthorized = locationManagerAuthorized;
    if(locationManagerAuthorized){
        self.mapFloatingBtn.hidden = NO;
    } else {
        self.mapFloatingBtn.hidden = YES;
        self.searchResultGeoArray = @[];
    }
    [self updateErrorViewForLocation];
}

- (void) accessoryButtonTapped:(NSNotification*)notification
{
    self.stationSearchInputField.text = @"";
    [self updateInputAccessoryForString:@""];
    [self didEndEditing:self.stationSearchInputField];
}
-(void)closeButtonTapped{
    [self.stationSearchInputField resignFirstResponder];
    [self closeTextInputMode];
}
    

- (void) searchButtonTapped:(NSNotification*)notification
{
    // manual search triggered
    if (self.stationSearchInputField.text.length >= kMinCharactedsSuggestionTreshold) {
        [self triggerSearchWithQuery:self.stationSearchInputField.text andUseLocation:NO];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark search results table view

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(tableView == self.searchResultTableView){
        return self.searchResultTextArray.count;
    }
    if(tableView == self.favoritesTableView){
        NSArray* fav = [[MBFavoriteStationManager client] favoriteStationsList];
        return fav.count;
    }
    if(tableView == self.geoSearchTableView){
        return self.searchResultGeoArray.count;
    }
    return 0;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger height = 52;
    if(self.longPressStation && [self.longPressStation isEqual:indexPath]){
        height += MBStationPickerTableViewCell.departureContainerHeight;
        if(tableView == self.geoSearchTableView){
            height += 50;//extra space for distance
        }
    }
    return height;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    BOOL isPressedCell = self.longPressStation && [self.longPressStation isEqual:indexPath];
    MBStationPickerTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.tableView = (MBStationListTableView*) tableView;
    cell.delegate = self;
    cell.station = [self stationDataForTableView:tableView path:indexPath];
    cell.showDistance = isPressedCell && self.currentType == MBStationSearchTypeLocation;
    cell.showDetails = isPressedCell;
    return cell;
}
-(MBStationFromSearch*)stationDataForTableView:(UITableView*)tableView path:(NSIndexPath*)indexPath{
    if(tableView == self.searchResultTableView){
        return self.searchResultTextArray[indexPath.row];
    }
    if(tableView == self.favoritesTableView){
        NSArray* fav = [[MBFavoriteStationManager client] favoriteStationsList];
        return fav[indexPath.row];
    }
    if(tableView == self.geoSearchTableView){
        return self.searchResultGeoArray[indexPath.row];
    }
    return nil;
}
-(void)stationPickerCell:(MBStationPickerTableViewCell *)cell changedFavStatus:(BOOL)favStatus{
    if(self.currentType == MBStationSearchTypeFavorite){
        [self reloadAllTableViews];//reload on every change (remove favorite station)
        NSArray* fav = [[MBFavoriteStationManager client] favoriteStationsList];
        if(fav.count == 0){
            self.searchErrorView.hidden = NO;
        } else {
            self.searchErrorView.hidden = YES;
        }
        if(!favStatus){
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Der Eintrag wurde aus Favoriten entfernt.");
            });
        }
    }
}
-(void)stationPickerCellDidLongPress:(MBStationPickerTableViewCell *)cell{
    MBStationListTableView* tv = cell.tableView;
    NSIndexPath* indexPath = [tv indexPathForCell:cell];
    if([self.longPressStation isEqual:indexPath]){
        self.longPressStation = nil;
    } else {
        self.longPressStation = indexPath;
    }
    [tv reloadData];
    if(self.longPressStation){
        [CATransaction begin];
        [tv scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        [CATransaction setCompletionBlock:^{
            if(indexPath.row > 0){
                //correct the position by adding the triangle
                CGPoint p = tv.contentOffset;
                p.y += tv.triangleView.sizeHeight;
                tv.contentOffset = p;
            }
        }];
        [CATransaction commit];
    }
}
-(void)stationPickerCellDidTapDeparture:(MBStationPickerTableViewCell *)cell{
    NSIndexPath* indexPath = [cell.tableView indexPathForCell:cell];
    MBStationFromSearch* station = [self stationDataForTableView:cell.tableView path:indexPath];
    [self didSelectStation:station startWithDepartures:YES];
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MBStationFromSearch* station = [self stationDataForTableView:tableView path:indexPath];
    if(station){
        [self didSelectStation:station startWithDepartures:NO];
        //close text search area
        if(self.featureButtonArea.hidden){
            [self closeTextInputMode];
        }
    }
}


@end
