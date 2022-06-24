// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBNavigationController.h"
#import "MBUIHelper.h"

@interface MBNavigationController ()

@property (nonatomic, strong) UIView *redBar;

@end

@implementation MBNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.swipeBackGestureEnabled = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.accessibilityLanguage = @"de-DE";
        
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self.interactivePopGestureRecognizer.delegate = self;
}

- (void) loadView
{
    [super loadView];
    int top = self.navigationBar.frame.size.height;
    self.redBar = [[UIView alloc] initWithFrame:CGRectMake(0, top-1, self.view.frame.size.width, 2)];
    self.redBar.backgroundColor = [UIColor db_mainColor];
    
    NSDictionary * navBarTitleTextAttributes =
      @{ NSForegroundColorAttributeName : [UIColor db_333333],
         NSFontAttributeName            : [UIFont db_RegularSeventeen] };
    
    [[UINavigationBar appearance] setTitleTextAttributes:navBarTitleTextAttributes];
    [self.navigationBar addSubview:self.redBar];
    self.navigationBar.translucent = NO;
    
    
}

- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    int navigationBarHeight = self.navigationBar.frame.size.height;
    self.redBar.frame = CGRectMake(0, navigationBarHeight-1, self.view.frame.size.width, 2);
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer;
{
    // disabled swipe gesture on some views to disable back swipe    
    UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
    
    if(UIDeviceOrientationIsPortrait(currentOrientation)) {
        //do portrait work
        return self.interactivePopGestureRecognizer.enabled; //self.swipeBackGestureEnabled; //self.interactivePopGestureRecognizer.enabled;
    } else if(UIDeviceOrientationIsPortrait(currentOrientation)){
        //do landscape work
        return NO;
    }
    
    return NO;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void) setSwipeBackGestureEnabled:(BOOL)swipeBackGestureEnabled
{
    _swipeBackGestureEnabled = swipeBackGestureEnabled;
}

- (BOOL) shouldAutorotate
{
    return ISIPAD ? YES : self.rotationEnabled;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return ISIPAD ? (self.rotationEnabled ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskPortrait|UIInterfaceOrientationMaskPortraitUpsideDown) : UIInterfaceOrientationMaskAllButUpsideDown;
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

@end
