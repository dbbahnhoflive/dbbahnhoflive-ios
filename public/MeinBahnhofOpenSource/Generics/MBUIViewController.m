// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBUIViewController.h"
#import "MBUIHelper.h"
#import "MBButtonWithAction.h"


@interface MBUIViewController()

@property (nonatomic, assign) BOOL showBackButton;
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

    UIImage *backButtonImage = [UIImage db_imageNamed: @"ChevronBlackLeft"];
    
    backButton.accessibilityLabel =  @"Zurück" ;
    backButton.accessibilityLanguage = @"de-DE";
    
    //[backButton setBackgroundImage:backButtonImage forState:UIControlStateNormal];
    UIImageView* img = [[UIImageView alloc] initWithImage:backButtonImage];
    [backButton addSubview:img];
    backButton.frame = CGRectMake(0, 0, 32,32);
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




@end
