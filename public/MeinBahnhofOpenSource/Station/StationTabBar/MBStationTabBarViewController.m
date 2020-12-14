// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBStationTabBarViewController.h"
#import "MBStationTabBarView.h"
#import "MBMapViewButton.h"
#import "MBMapViewController.h"

@interface MBStationTabBarViewController () <MBStationTabBarViewDelegate>

@property (nonatomic,strong) UIView* line;
@property (nonatomic, strong) UIViewController *currentViewController;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) MBMapViewButton* mapViewButton;
@property (nonatomic, strong) MBStation* station;

@property NSUInteger selectedTabIndex;
@property (nonatomic, strong) NSLayoutConstraint *tabbarHeightConstraint;

@end

@implementation MBStationTabBarViewController

- (instancetype)initWithViewControllers:(NSArray *)viewControllers station:(MBStation*)station{
    self = [super initWithNibName:nil bundle:nil];
    self.viewControllers = viewControllers;
    self.station = station;
    NSArray *images = @[
                        [[self safeImage:@"app_bahnhofsuche_default"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate],
                        [[self safeImage:@"app_bahnhof"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate],
                        [[self safeImage:@"app_abfahrt_ankunft"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate],
                        [[self safeImage:@"app_info"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate],
                        [[self safeImage:@"app_shop"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate],
                        ];
    NSArray* titles = @[
                                     @"Zurück zur Bahnhofsuche",
                                     @"Bahnhofstartseite",
                                     @"Abfahrt und Ankunft",
                                     @"Bahnhofsinformationen",
                                     @"Shoppen & Schlemmen"
                                     ];
    self.tabBarView = [[MBStationTabBarView alloc] initWithFrame:CGRectZero tabBarImages:images titles:titles];
    self.tabBarView.delegate = self;
    self.tabBarView.translatesAutoresizingMaskIntoConstraints = NO;
    // only show tabbar, once it is clear which tabs are needed
    self.tabBarView.alpha = 0.0;

    return self;
}
-(UIImage*)safeImage:(NSString*)name{
    UIImage* img = [UIImage db_imageNamed:name];
    if(!img){
        img = [UIImage db_imageNamed:@"white_40_40"];
    }
    return img;
}

-(void)dealloc{
    NSLog(@"dealloc MBStationTabBarViewController");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setNeedsStatusBarAppearanceUpdate];

    [self.view addSubview:self.tabBarView];
    self.selectedTabIndex = 1;
    [self.tabBarView selectTabIndex:self.selectedTabIndex];
    self.topSlack = @(0);
    self.containerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.containerView.clipsToBounds = YES;
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.containerView];
    
    NSDictionary *views = @{@"tabbar":self.tabBarView, @"view":self.view, @"container":self.containerView};
    NSArray *tabBarHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tabbar]|"
                                                                          options:0 metrics:nil views:views];
    CGFloat tabbarHeight = 60.0;
    self.tabbarHeightConstraint = [NSLayoutConstraint constraintWithItem:self.tabBarView
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1.0
                                                                         constant:tabbarHeight];
    
    NSArray *containerHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[container]|"
                                                                             options:0 metrics:nil views:views];
    NSDictionary *metrics = @{@"topslack":self.topSlack};
    NSArray *containerVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-topslack-[container][tabbar]|"
                                                                             options:0 metrics:metrics views:views];
    NSMutableArray *constraints = [[NSMutableArray alloc] initWithArray:tabBarHConstraints];
    [constraints addObjectsFromArray:containerHConstraints];
    [constraints addObjectsFromArray:containerVConstraints];
    [constraints addObject:self.tabbarHeightConstraint];
    [self.view addConstraints:constraints];
    
    
    // special case index 0 is back to search page, where the tab bar is gone again
    UIViewController *vc = self.viewControllers[self.selectedTabIndex];
    self.currentViewController = vc;
    [self addChildViewController:vc];
    [vc didMoveToParentViewController:self];
    [self.containerView addSubview:vc.view];
    
    self.mapViewButton = [[MBMapViewButton alloc] init];
    [self.mapViewButton setSize:CGSizeMake((int)(self.mapViewButton.frame.size.width*SCALEFACTORFORSCREEN), (int)(self.mapViewButton.frame.size.height*SCALEFACTORFORSCREEN))];
    [self.mapViewButton addTarget:self action:@selector(mapFloatingBtnPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.mapViewButton];
    [self updateMapButtonStatus];
    
    self.line = [[UIView alloc] initWithFrame:CGRectZero];
    self.line.backgroundColor = [UIColor db_light_lineColor];
    [self.view addSubview:self.line];
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    UIViewController *vc = [self visibleViewController];
    if (nil == vc) {
        vc = [self.viewControllers objectAtIndex:1];
        if ([vc isKindOfClass:[UINavigationController class]]) {
            vc = [(UINavigationController *)vc topViewController];
        }
    }
    return vc;
}

-(UIViewController*)visibleViewController{
    UIViewController* visibleController = nil;
    if([self.currentViewController isKindOfClass:[UINavigationController class]]){
        //ask the visible vc
        UINavigationController* nav = (UINavigationController*) self.currentViewController;
        visibleController = nav.visibleViewController;
    } else {
        visibleController = self.currentViewController;
    }
    return visibleController;
}

- (void)mapFloatingBtnPressed {
    [MBTrackingManager trackActionsWithStationInfo:@[@"tab_navi", @"tap", @"map_button"]];
    
    MBMapViewController* vc = [MBMapViewController new];
    UIViewController* visibleController = [self visibleViewController];
    if([visibleController conformsToProtocol:@protocol(MBMapViewControllerDelegate)]){
        vc.delegate = (id<MBMapViewControllerDelegate>) visibleController;
    }
    [vc configureWithStation:self.station];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    self.currentViewController.view.frame = self.containerView.bounds;
    [self.mapViewButton setGravityRight:10];
    [self.mapViewButton setGravityBottom:10+self.tabBarView.sizeHeight];
    
    self.line.frame = CGRectMake(0, self.tabBarView.frame.origin.y, self.view.sizeWidth, 1);

    CGFloat safeBottomOffset = 0.0;
    if (@available(iOS 11.0, *)) {
        safeBottomOffset = self.view.safeAreaInsets.bottom;
        self.tabbarHeightConstraint.constant = 60.0 + safeBottomOffset;
    } else {
        // Fallback on earlier versions
    }

}

- (void)disableTabAtIndex:(NSUInteger)index {
    [self.tabBarView disableTabIndex:index];
}
- (void)enableTabAtIndex:(NSUInteger)index {
    [self.tabBarView enableTabIndex:index];
}

- (void)showTabbar {
    [self.tabBarView setNeedsLayout];
    self.tabBarView.alpha = 1.0;
}

- (UIViewController *)selectViewControllerAtIndex:(NSUInteger)index {
    [self didSelectTabAtIndex:index trackAction:NO];
    return self.currentViewController;
}


- (void)didSelectTabAtIndex:(NSUInteger)index {
    [self didSelectTabAtIndex:index trackAction:YES];
}
- (void)didSelectTabAtIndex:(NSUInteger)index trackAction:(BOOL)track{

    NSString *trackingKey = @"";
    switch(index) {
        case 0:
            trackingKey = @"suche";
            break;
        case 1:
            trackingKey = @"uebersicht";
            break;
        case 2:
            trackingKey = @"abfahrtstafel";
            break;
        case 3:
            trackingKey = @"info";
            break;
        case 4:
            trackingKey = @"shops";
            break;
    }
    if(track){
        [MBTrackingManager trackActionsWithStationInfo:@[@"tab_navi", @"tap", trackingKey]];
    }
    
    // replace current view controller if needed
    if (index != self.selectedTabIndex) {
        
        self.selectedTabIndex = index;
        [self.tabBarView selectTabIndex:index];
        if (index == 0) {
            if (nil != self.delegate) {
                [self.delegate goBackToSearch];
            }
        } else {
            if (self.viewControllers.count > index) {
                UIViewController *vc = self.viewControllers[index];
                [self.currentViewController willMoveToParentViewController:nil];
                [self.currentViewController removeFromParentViewController];
                [self.currentViewController.view removeFromSuperview];
                if (index == 2) {
                    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
                    self.topSlack = @(statusBarFrame.size.height);
                    [self.view setNeedsUpdateConstraints];
                }
                self.currentViewController = vc;
                self.currentViewController.view.frame = self.containerView.frame;
                [self addChildViewController:vc];
                [self.containerView addSubview:vc.view];
                [self updateMapButtonStatus];
                [self setNeedsStatusBarAppearanceUpdate];
            }
        }
    } else {
        //pop to root
        if([self.currentViewController isKindOfClass:[UINavigationController class]]){
            [((UINavigationController*)self.currentViewController) popToRootViewControllerAnimated:YES];
        }
    }
}

-(void)updateMapButtonStatus{
    UIViewController* visibleController = [self visibleViewController];
    self.mapViewButton.hidden = ! [visibleController conformsToProtocol:@protocol(MBMapViewControllerDelegate)];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
