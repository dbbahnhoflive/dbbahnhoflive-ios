// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "OnboardingViewController.h"
#import "MBGPSLocationManager.h"
#import "MBStationSearchViewController.h"
#import "MBUrlOpening.h"
#import "MBUIHelper.h"
#import "AppDelegate.h"

@interface OnboardingViewController()

@property (nonatomic, strong) UIScrollView *tutorialPager;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) UIButton *closeButton;

@property (nonatomic,strong) UIImageView* splashImg;

@property (nonatomic,strong) UIImageView* topImage;
@property (nonatomic,strong) UIImageView* topImage2;

@property (nonatomic,strong) UILabel* headerLabel1;
@property (nonatomic,strong) UILabel* headerLabel2;
@property (nonatomic,strong) UILabel* descriptionLabel1;
@property (nonatomic,strong) UILabel* descriptionLabel2;

@property(nonatomic) NSInteger animationImg;

@property(nonatomic,strong) UIButton* actionButton;
@property(nonatomic,strong) UIImageView* checkImage;
@property(nonatomic) NSInteger spacing;

@property(nonatomic) CGSize imageSize;

@end

@implementation OnboardingViewController

#define NUMBER_OF_PAGES 6

-(NSInteger)numberOfImagesOnPage:(NSInteger)page{
    //note: pages start with 0 here... images are named starting with 1!
    switch(page){
        case 1:
        case 2:
        case 3:
        case 4:
            return 2;
        
        default:
            return 1;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    NSString* imgFile = [self filenameForPage:0 img:0];
    self.imageSize = [UIImage imageNamed:imgFile].size;
    
    self.view.accessibilityViewIsModal = YES;
    
    self.spacing = 20;
    /*
    // Load launch image
    NSString *launchImageName = @"LaunchImage.png";
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        if ([UIScreen mainScreen].bounds.size.height == 480) launchImageName = @"LaunchImage-700@2x.png"; // iPhone 4/4s, 3.5 inch screen
        if ([UIScreen mainScreen].bounds.size.height == 568) launchImageName = @"LaunchImage-700-568h@2x.png"; // iPhone 5/5s, 4.0 inch screen
        if ([UIScreen mainScreen].bounds.size.height == 667) launchImageName = @"LaunchImage-800-667h@2x.png"; // iPhone 6, 4.7 inch screen
        if ([UIScreen mainScreen].bounds.size.height == 736) launchImageName = @"LaunchImage-800-Portrait-736h@3x.png"; // iPhone 6+, 5.5 inch screen
        if ([UIScreen mainScreen].bounds.size.height == 1218) launchImageName = @"LaunchImage-1100-2436h@3x.png"; // iPhone X (??)
    }
    else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if ([UIScreen mainScreen].scale == 1) launchImageName = @"LaunchImage-700-Portrait~ipad.png"; // iPad 2
        if ([UIScreen mainScreen].scale == 2) launchImageName = @"LaunchImage-700-Portrait@2x~ipad.png"; // Retina iPads
    }
    
    self.splashImg = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:launchImageName ofType:nil]]];
    [self.view addSubview:self.splashImg];
    */
    
    self.topImage = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.topImage.contentMode = UIViewContentModeScaleAspectFill;
    self.topImage.clipsToBounds = YES;
    
    self.topImage2 = [[UIImageView alloc] initWithFrame:self.topImage.frame];
    self.topImage2.contentMode = self.topImage.contentMode;
    self.topImage2.clipsToBounds = self.topImage.clipsToBounds;
    
    self.headerLabel1 = [[UILabel alloc] init];
    self.headerLabel1.numberOfLines = 0;
    self.headerLabel1.textColor = [UIColor db_333333];
    self.headerLabel1.font = [UIFont db_BoldTwentyFive];
    
    self.headerLabel2 = [[UILabel alloc] init];
    self.headerLabel2.numberOfLines = self.headerLabel1.numberOfLines;
    self.headerLabel2.textColor = self.headerLabel1.textColor;
    self.headerLabel2.font = self.headerLabel1.font;

    self.headerLabel1.accessibilityTraits = self.headerLabel2.accessibilityTraits = self.headerLabel1.accessibilityTraits | UIAccessibilityTraitHeader;
    
    self.descriptionLabel1 = [[UILabel alloc] init];
    self.descriptionLabel1.numberOfLines = 0;
    self.descriptionLabel1.textColor = [UIColor db_333333];
    self.descriptionLabel1.font = [UIFont db_RegularFourteen];
    
    self.descriptionLabel2 = [[UILabel alloc] init];
    self.descriptionLabel2.numberOfLines = self.descriptionLabel1.numberOfLines;
    self.descriptionLabel2.textColor = self.descriptionLabel1.textColor;
    self.descriptionLabel2.font = self.descriptionLabel1.font;

    self.actionButton = [[UIButton alloc] initWithFrame:CGRectMake(16, 16, self.view.frame.size.width-2*16, 60)];
    self.actionButton.layer.cornerRadius = self.actionButton.sizeHeight/2;
    [self.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.actionButton setBackgroundColor:[UIColor db_mainColor]];
    [self.actionButton.titleLabel setFont:[UIFont db_BoldEighteen]];
    [self.actionButton addTarget:self action:@selector(actionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionButton configureDefaultShadow];
    
    self.checkImage = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"large_check"]];

    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeButton.size = CGSizeMake(60,60);
    [self.closeButton setAccessibilityLabel:@"Tutorial schließen"];
    [self.closeButton setImage:[UIImage db_imageNamed:@"MapToggleButtonClose"] forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(didTapOnCloseButton:) forControlEvents:UIControlEventTouchUpInside];
    
    self.tutorialPager = [[UIScrollView alloc] init];
    self.tutorialPager.backgroundColor = [UIColor clearColor];
    self.tutorialPager.delegate = self;
    self.tutorialPager.bounces = NO;
    self.tutorialPager.showsHorizontalScrollIndicator = NO;
    self.tutorialPager.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

    self.pageControl = [[UIPageControl alloc] init];
    self.pageControl.numberOfPages = NUMBER_OF_PAGES;
    [self.pageControl addTarget:self action:@selector(pageControlChanged:) forControlEvents:UIControlEventValueChanged];
    
    [self.view addSubview:self.topImage];
    [self.view addSubview:self.topImage2];
    
    [self.view addSubview:self.headerLabel1];
    [self.view addSubview:self.headerLabel2];
    [self.view addSubview:self.descriptionLabel1];
    [self.view addSubview:self.descriptionLabel2];
    
    [self.view addSubview:self.tutorialPager];
    [self.view addSubview:self.pageControl];
    [self.view addSubview:self.closeButton];
    [self.view addSubview:self.actionButton];
    [self.view addSubview:self.checkImage];

    self.tutorialPager.frame = self.view.frame;
    
    self.pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    self.pageControl.currentPageIndicatorTintColor = [UIColor db_mainColor];
    //self.pageControl.transform = CGAffineTransformMakeScale(1.3, 1.3);
    
    self.tutorialPager.contentSize = CGSizeMake(self.view.sizeWidth*NUMBER_OF_PAGES, self.view.sizeHeight);
    self.tutorialPager.pagingEnabled = YES;
    [self pageTransitionTo:0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gpsAuthChanged:) name:NOTIF_GPS_AUTH_CHANGED object:[MBGPSLocationManager sharedManager]];
}

-(void)gpsAuthChanged:(id)something{
    [self pageTransitionTo:self.pageControl.currentPage];
}

-(void)actionButtonTapped:(id)sender{
    if(self.pageControl.currentPage == NUMBER_OF_PAGES-1){
        [self didTapOnCloseButton:nil];
    } else if(self.pageControl.currentPage == 3){
        CLAuthorizationStatus status = [[MBGPSLocationManager sharedManager] authStatus];
        if(status == kCLAuthorizationStatusNotDetermined){
            [[MBGPSLocationManager sharedManager] requestAuthorization];
        } else {
            [MBUrlOpening openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
    }
}

#define SPACE_LEFT 17
#define SPACE_RIGHT 34

- (void) viewDidLayoutSubviews
{
    CGFloat bottomSpacing = 15;
    CGFloat screenHeight = AppDelegate.screenHeight;
    NSLog(@"screenHeight %f",screenHeight);
    //depending on the screen height we split the screen into the image (top) and text part, exactly with the same values used in the launch images.
    CGFloat topHeight = 750/2;
    self.spacing = 20;
    if(screenHeight == 960/2){
        topHeight = 464/2;
        self.spacing = 10;
        bottomSpacing = 5;
    } else if(screenHeight == 1136/2){
//        topHeight = 640/2;//iphone5
        //we need more space for our texts
        topHeight = 280;
    } else if(screenHeight == 1334/2){
        topHeight = 750/2;//iphone6-8
    } else if(screenHeight == 2048/2) {
        topHeight = 1152/2;//ipad
    } else if(screenHeight == 2208/3){
        topHeight = 1242/3;//iphone6-8+
    } else if(screenHeight == 2436/3){
        topHeight = 1350/3;//iphoneX
    } else if(screenHeight >= (self.view.frame.size.width/self.imageSize.width)*self.imageSize.height + 280) {
        //one of the newer devices with a large screen: display the whole image
        topHeight = (self.view.frame.size.width/self.imageSize.width)*self.imageSize.height;
    }
    //NSLog(@"topHeight %f",topHeight);
    UIEdgeInsets safeArea = self.view.safeAreaInsets;
    //NSLog(@"safearea %f",safeArea.top);
    self.topImage.frame = CGRectMake(0, 0, self.view.frame.size.width, topHeight);
    self.topImage2.frame = self.topImage.frame;

    self.tutorialPager.frame = self.view.frame;
    self.pageControl.frame = CGRectMake(0,0, 200,50);
    
    [self.pageControl centerViewHorizontalInSuperView];
    if (ISIPAD) {
        [self.pageControl setGravity:Bottom withMargin:30];
    } else {
        [self.pageControl setGravity:Bottom withMargin:bottomSpacing];
    }
    
    [self.closeButton setGravity:Right withMargin:0];
    [self.closeButton setGravity:Top withMargin:20+safeArea.top];
    
    [self.headerLabel1 setGravityLeft:SPACE_LEFT];
    [self.headerLabel2 setGravityLeft:SPACE_LEFT];
    [self.descriptionLabel1 setGravityLeft:SPACE_LEFT];
    [self.descriptionLabel2 setGravityLeft:SPACE_LEFT];

    [self.headerLabel1 setBelow:self.topImage withPadding:self.spacing+4];
    [self.descriptionLabel1 setBelow:self.headerLabel1 withPadding:self.spacing];
    [self.headerLabel2 setBelow:self.topImage withPadding:self.spacing+4];
    [self.descriptionLabel2 setBelow:self.headerLabel2 withPadding:self.spacing];
}


-(void)loadTextsForPage:(NSInteger)page{
    switch(page){
        case 0:
            [self loadHeader:@"Bahnhof live" boldFont:@[@"Bahnhof"] text:@"Egal ob zu Hause oder auf Reisen. Entdecken Sie 5.400 Bahnhöfe und alle Haltestellen des öffentlichen Personennahverkehrs deutschlandweit."
                    boldFont:@[@"5.400 Bahnhöfe", @"alle Haltestellen"]];
            [self hideActionButton];
            break;
        case 1:
            [self loadHeader:@"Bahnhöfe und Haltestellen" boldFont:@[@"Bahnhöfe",@"Haltestellen"] text:@"Finden Sie Ihren Bahnhof oder Ihre Haltestelle und speichern Sie diese als Favoriten."
                    boldFont:@[@"Finden"]];
            [self hideActionButton];
            break;
        case 2:
            [self loadHeader:@"Abfahrt in der Nähe" boldFont:@[@"Abfahrt"] text:@"Profi-Tipp: Wählen Sie einen Eintrag aus der Liste und halten Sie diesen gedrückt. Sie bekommen eine Schnellansicht der Abfahrtstafel angezeigt. Dies funktioniert auch bei Ihren Favoriten und der Suche."
                    boldFont:@[@"Profi-Tipp:", @"einen Eintrag", @"halten Sie diesen gedrückt", @"Favoriten", @"Suche" ]];
            [self hideActionButton];
            break;
        case 3:
            [self loadHeader:@"Schon gewusst?" boldFont:@[@"gewusst?"] text:@"Für Funktionen wie Haltestellen in Ihrer Nähe benötigt die App Zugriff auf Ihren Standort."
                    boldFont:@[]];
            CLAuthorizationStatus status = [[MBGPSLocationManager sharedManager] authStatus];
            if(status == kCLAuthorizationStatusNotDetermined || status == kCLAuthorizationStatusDenied){
                [self showActionButtonWithText:@"Jetzt erlauben"];
            } else {
                [self hideActionButton];
                if(status >= kCLAuthorizationStatusAuthorizedAlways){
                    //show the ok
                    self.checkImage.alpha = 1;
                }
            }
            break;
        case 4:
            [self loadHeader:@"Den Bahnhof erkunden" boldFont:@[@"erkunden"] text:@"Die bahnhofsbezogene Suche ist der einfachste Weg, um gezielt Angebote, Services und Informationen vorab, oder vor Ort zu erhalten."
                    boldFont:@[@"bahnhofsbezogene Suche"]];
            [self hideActionButton];
            break;
        case 5:
            [self loadHeader:@"Bahnhof live" boldFont:@[@"Bahnhof"] text:@"Haltestellen finden. Bahnhöfe entdecken."
                    boldFont:@[]];
            [self showActionButtonWithText:@"Viel Spaß"];
            break;
    }
}

#define IMG_DISPLAY_TIME 1.5
#define IMG_CROSSFADE_TIME 0.75

-(void)hideActionButton{
    self.actionButton.alpha = 0.0;
    self.checkImage.alpha = 0.0;
}
-(void)showActionButtonWithText:(NSString*)text{
    self.checkImage.alpha = 0;
    [UIView animateWithDuration:IMG_CROSSFADE_TIME animations:^{
        [self.actionButton setTitle:text forState:UIControlStateNormal];
        self.actionButton.alpha = 1;
    }];
}

-(void)loadHeader:(NSString*)headerText boldFont:(NSArray*)boldHeader text:(NSString*)descText boldFont:(NSArray*)boldTexts{
    self.headerLabel2.text = headerText;
    self.descriptionLabel2.text = descText;
    
    self.headerLabel2.font = [UIFont db_RegularTwentyFive];
    NSMutableAttributedString * attributedString = [self.headerLabel2.attributedText mutableCopy];
    NSString* simpleText = headerText;
    for(NSString* boldtext in boldHeader){
        NSRange range;
        NSUInteger loc = 0;
        do{
            range = [simpleText rangeOfString:boldtext options:0 range:NSMakeRange(loc, simpleText.length-loc)];
            if(range.location == NSNotFound){
                break;
            } else {
                loc = range.location;
                [attributedString setAttributes:@{NSFontAttributeName:[UIFont db_BoldTwentyFive]} range:NSMakeRange(loc, range.length)];
                loc += 1;
            }
        }while(true);
    }
    self.headerLabel2.attributedText = attributedString;
    
    self.descriptionLabel2.font = [UIFont db_RegularFourteen];
    attributedString = [self.descriptionLabel2.attributedText mutableCopy];
    simpleText = descText;
    for(NSString* boldtext in boldTexts){
        NSRange range;
        NSUInteger loc = 0;
        do{
            range = [simpleText rangeOfString:boldtext options:0 range:NSMakeRange(loc, simpleText.length-loc)];
            if(range.location == NSNotFound){
                break;
            } else {
                loc = range.location;
                [attributedString setAttributes:@{NSFontAttributeName:[UIFont db_BoldFourteen]} range:NSMakeRange(loc, range.length)];
                loc += 1;
            }
        }while(true);
    }
    self.descriptionLabel2.attributedText = attributedString;
    
    
    self.headerLabel2.size = [self.headerLabel2 sizeThatFits:CGSizeMake(self.view.sizeWidth-SPACE_LEFT-SPACE_RIGHT, CGFLOAT_MAX)];
    self.descriptionLabel2.size = [self.descriptionLabel2 sizeThatFits:CGSizeMake(self.view.sizeWidth-SPACE_LEFT-SPACE_RIGHT, CGFLOAT_MAX)];
    
    self.headerLabel2.alpha = 0;
    self.descriptionLabel2.alpha = 0;
    

    [UIView animateWithDuration:0.25 animations:^{
        self.headerLabel1.alpha = 0;
        self.descriptionLabel1.alpha = 0;
    }completion:^(BOOL finished) {
        [self.actionButton setBelow:self.descriptionLabel2 withPadding:self.spacing];
        [self.checkImage setBelow:self.descriptionLabel2 withPadding:self.spacing];
        [self.checkImage centerViewHorizontalInSuperView];
        [UIView animateWithDuration:IMG_CROSSFADE_TIME-0.25 animations:^{
            self.headerLabel2.alpha = 1;
            self.descriptionLabel2.alpha = 1;
        } completion:^(BOOL finished) {
            self.headerLabel1.attributedText = self.headerLabel2.attributedText;
            self.descriptionLabel1.attributedText = self.descriptionLabel2.attributedText;
            
            self.headerLabel1.frame = self.headerLabel2.frame;
            self.descriptionLabel1.frame = self.descriptionLabel2.frame;
        }];
    }];
    
}

-(void)pageControlChanged:(UIPageControl*)page{
    [self pageTransitionTo:self.pageControl.currentPage];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger nextPage = round(scrollView.contentOffset.x / scrollView.sizeWidth);
    BOOL changedPage = nextPage != self.pageControl.currentPage;
    self.pageControl.currentPage = nextPage;
    if(changedPage){
        [self pageTransitionTo:self.pageControl.currentPage];
    }
}

-(void)pageTransitionTo:(NSInteger)page{
    NSLog(@"pageTransitionTo: %ld",(long)page);
    
    [self loadTextsForPage:page];
    NSString* imgFile = [self filenameForPage:page img:0];
    self.topImage2.image = [UIImage db_imageNamed:imgFile];
    self.topImage2.alpha = 0.0;
    [UIView animateWithDuration:(self.topImage.image == nil ? 0 : IMG_CROSSFADE_TIME) animations:^{
        self.topImage2.alpha = 1.0;
    } completion:^(BOOL finished) {
        self.topImage2.alpha = 0.0;
        self.topImage.image = self.topImage2.image;
        
        [self animateImagesForPage:page];
    }];
}

-(void)animateImagesForPage:(NSInteger)page{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadAnimatedImage) object:nil];
    //NSLog(@"animateImagesForPage: %ld",(long)page);
    NSInteger images = [self numberOfImagesOnPage:page];
    if(images > 1){
        self.animationImg = 0;
        [self performSelector:@selector(loadAnimatedImage) withObject:nil afterDelay:IMG_DISPLAY_TIME];
    }
}
-(void)loadAnimatedImage{
    self.animationImg++;
    NSInteger img = self.animationImg;
    //NSLog(@"loadAnimatedImage: %ld",(long)img);
    NSInteger page = self.pageControl.currentPage;
    if(img >= [self numberOfImagesOnPage:page]){
        return;
    }
    NSString* imgFile = [self filenameForPage:page img:img];
    self.topImage2.image = [UIImage db_imageNamed:imgFile];
    self.topImage2.alpha = 0.0;
    [UIView animateWithDuration:IMG_CROSSFADE_TIME animations:^{
        self.topImage2.alpha = 1.0;
    } completion:^(BOOL finished) {
        self.topImage2.alpha = 0.0;
        self.topImage.image = self.topImage2.image;
        [self performSelector:@selector(loadAnimatedImage) withObject:nil afterDelay:IMG_DISPLAY_TIME];
    }];
}

-(NSString*)filenameForPage:(NSInteger)page img:(NSInteger)img{
    NSString* res= [NSString stringWithFormat:@"tutorial_screen_%ld_%ld",(long)(page+1),(long)(img+1)];
    NSLog(@"load %@",res);
    return res;
}

- (void)didTapOnCloseButton:(id)sender
{
    /*
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];*/
    
    MBStationSearchViewController* parentVC = (MBStationSearchViewController*)self.parentViewController;
    parentVC.onBoardingVisible = NO;
    
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];

}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


@end
