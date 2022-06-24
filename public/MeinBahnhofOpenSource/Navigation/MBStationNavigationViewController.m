// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBStationNavigationViewController.h"
#import "MBUIHelper.h"

@interface MBStationNavigationViewController ()
@property (nonatomic, assign) BOOL behindViewSmall;
@property (nonatomic, assign) BOOL behindViewHuge;

@property (nonatomic, strong) UIView *redBar;

@end

@implementation MBStationNavigationViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.redBar = [UIView new];
    [self.redBar setBackgroundColor:[UIColor db_mainColor]];
    [self.redBar setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.showRedBar = NO;
    
    self.behindViewSmall = NO;
    UINavigationBar *navBar = self.navigationBar;
    [navBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [navBar setShadowImage:[UIImage new]];
    
    navBar.tintColor = [UIColor db_333333];
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont db_RegularSixteen],
                                 NSForegroundColorAttributeName:[UIColor db_333333]};
    navBar.titleTextAttributes = attributes;
    navBar.barTintColor = [UIColor whiteColor];
    navBar.translucent = NO;
    
    self.behindView = [[MBStationTopView alloc] initWithFrame:CGRectZero];
    self.behindView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.behindView addSubview:self.redBar];
    NSDictionary *redbarViews = @{@"redbar":self.redBar};
    NSArray *redbarHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[redbar]|"
                                                                          options:0 metrics:nil views:redbarViews];
    NSArray *redbarVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[redbar]|"
                                                                          options:0 metrics:nil views:redbarViews];
    NSLayoutConstraint *redbarHeightConstraint = [NSLayoutConstraint constraintWithItem:self.redBar
                                                               attribute:NSLayoutAttributeHeight
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:nil
                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                              multiplier:1.0
                                                                constant:2.0];
    NSMutableArray *redBarConstraints = [[NSMutableArray alloc] initWithArray:redbarHConstraints];
    [redBarConstraints addObjectsFromArray:redbarVConstraints];
    [redBarConstraints addObject:redbarHeightConstraint];
    [self.behindView addConstraints:redBarConstraints];
    
    [self.view insertSubview:self.behindView belowSubview:navBar];
    
    NSDictionary *views = @{@"behind":self.behindView};
    NSArray *navbarHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[behind]|"
                                                                          options:0 metrics:nil views:views];
    NSArray *navbarVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[behind]"
                                                                          options:0 metrics:nil views:views];
    self.behindHeightConstraint = [NSLayoutConstraint constraintWithItem:self.behindView
                                                               attribute:NSLayoutAttributeHeight
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:nil
                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                              multiplier:1.0
                                                            constant:STATION_NAVIGATION_PICTURE_HEIGHT];
    NSMutableArray *constraints = [[NSMutableArray alloc] initWithArray:navbarHConstraints];
    [constraints addObjectsFromArray:navbarVConstraints];
    [constraints addObject:self.behindHeightConstraint];
    
    [self.view addConstraints:constraints];
    
    //NOTE: this is set in layoutcode!
    self.contentSearchButton = [[MBContentSearchButton alloc] init];
    self.contentSearchButton.hidden = YES;
    //the shadow should not be visible above the image but only below, that's why we need a separate view for it
    [self.view insertSubview:self.contentSearchButton.contentSearchButtonShadow belowSubview:self.behindView];
    [self.view addSubview:self.contentSearchButton];

    
}

-(void)setShowRedBar:(BOOL)showRedBar{
    _showRedBar = showRedBar;
    [self.view setNeedsLayout];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self.contentSearchButton layoutForScreenWidth:self.view.sizeWidth];
    [self.contentSearchButton setGravityTop:self.behindView.sizeHeight- self.contentSearchButton.sizeHeight/2];
    self.contentSearchButton.contentSearchButtonShadow.frame = self.contentSearchButton.frame;

    self.contentSearchButton.alpha = self.behindView.alpha;
    if(self.behindView.alpha < 1.0){
        //fade out button quicker
        self.contentSearchButton.alpha = (self.behindView.alpha*2)-1.;
    }

    self.redBar.hidden = !self.showRedBar;
    self.behindView.hidden = self.hideEverything;
    if (self.hideEverything) {
        self.navigationBarHidden = YES;
    } else if (self.behindViewHuge) {
        self.behindView.stationId = self.station.mbId;
        self.behindView.title = self.station.title;
        [self.behindView hideSubviews:NO];
        self.navigationBarHidden = YES;
    } else {
        if(self.behindViewBackgroundColor){
            self.behindView.backgroundColor = self.behindViewBackgroundColor;
        } else {
            self.behindView.backgroundColor = [UIColor whiteColor];
        }
        [self.behindView hideSubviews:YES];
        if (nil != self.topViewController.title) {
            [self.navigationBar.topItem setTitle:self.topViewController.title];
        } else {
            [self.navigationBar.topItem setTitle:self.station.title];
        }
        self.navigationBarHidden = self.behindViewSmall;
    }
    [self.topViewController.view setNeedsLayout];
}

- (void)showBackgroundImage:(BOOL)showBackground {
    if (showBackground) {
        self.behindViewHuge = YES;
        self.contentSearchButton.hidden = NO;
    } else {
        self.behindViewHuge = NO;
        self.contentSearchButton.hidden = YES;
    }
    [self setNeedsStatusBarAppearanceUpdate];
    [self.view setNeedsLayout];
}

-(void)removeSearchButton{
    [self.contentSearchButton.contentSearchButtonShadow removeFromSuperview];
    [self.contentSearchButton removeFromSuperview];
}

- (void)hideNavbar:(BOOL)hidden {
    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
    CGFloat navBarHeight = self.navigationBar.frame.size.height;
    if (hidden) {
        self.behindHeightConstraint.constant = statusBarFrame.size.height;
        self.behindViewSmall = YES;
        // hide title
        self.navigationBarHidden = YES;
    } else {
        self.behindHeightConstraint.constant = navBarHeight + 2.0 + statusBarFrame.size.height;
        self.behindViewSmall = NO;
        // show title
        self.navigationBarHidden = NO;
    }
}

-(BOOL)shouldAutorotate{
    return ISIPAD ? YES : NO;
}
-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return ISIPAD ? (UIInterfaceOrientationMaskPortrait|UIInterfaceOrientationMaskPortraitUpsideDown) : UIInterfaceOrientationMaskPortrait;
}

@end
