// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBTrackingConsentViewController.h"
#import "AppDelegate.h"
#import "MBLargeButton.h"
#import "MBUIHelper.h"
#import "MBImprintViewController.h"
#import "MBNavigationController.h"
#import "MBStationSearchViewController.h"
#import "MBTrackingManager.h"

@interface MBTrackingConsentViewController ()<UITextViewDelegate>
@property(nonatomic,strong) UIImageView* topImage;
@property(nonatomic,strong) UITextView* textLabel;
@property(nonatomic,strong) UIButton* noButton;
@property(nonatomic,strong) UIButton* yesButton;

@property(nonatomic,strong) UIScrollView* scrollView;

@end

@implementation MBTrackingConsentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    
    self.scrollView = [UIScrollView new];
    [self.view addSubview:self.scrollView];
    
    self.topImage = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"analytics_poi_icon"]];
    [self.scrollView addSubview:self.topImage];
    self.topImage.isAccessibilityElement = false;
    
    self.textLabel = [UITextView new];
    self.textLabel.scrollEnabled = false;
    self.textLabel.editable = false;
    self.textLabel.delegate = self;
    [self.scrollView addSubview:self.textLabel];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 2;
    
    NSMutableAttributedString* text = [[NSMutableAttributedString alloc] init];
    
    NSDictionary* regularParams = @{ NSFontAttributeName: UIFont.db_RegularFourteen, NSForegroundColorAttributeName: UIColor.blackColor, NSParagraphStyleAttributeName: paragraphStyle};
    NSDictionary* boldParams = @{ NSFontAttributeName: UIFont.db_BoldFourteen, NSForegroundColorAttributeName: UIColor.blackColor, NSParagraphStyleAttributeName: paragraphStyle};
    NSDictionary* linkParams = @{ NSFontAttributeName: UIFont.db_RegularFourteen, NSForegroundColorAttributeName: UIColor.blackColor, NSLinkAttributeName:@"link", NSUnderlineStyleAttributeName:[NSNumber numberWithInteger:NSUnderlineStyleSingle], NSParagraphStyleAttributeName: paragraphStyle};
    
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"Gemeinsam mit Ihnen wollen wir besser werden!\n\n" attributes:@{ NSFontAttributeName: UIFont.db_BoldSeventeen, NSForegroundColorAttributeName: UIColor.blackColor}]];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"Um DB Bahnhof live gemeinsam mit Ihnen weiter zu verbessern, " attributes:regularParams]];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"möchten wir Sie bitten, der Verarbeitung Ihrer Daten im Umgang mit dieser App für Statistiken und Analysen zuzustimmen" attributes:boldParams]];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:@". Mithilfe dieser anonymisierten Daten können wir die " attributes:regularParams]];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"Nutzererfahrung verbessern und frühzeitig Fehler erkennen und beseitigen" attributes:boldParams]];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:@". Für Details sehen Sie bitte unsere " attributes:regularParams]];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"Datenschutzhinweise" attributes:linkParams]];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:@".\n\nDiese Zustimmung erfolgt freiwillig. Sie können Sie jederzeit unter " attributes:regularParams]];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"Datenschutz" attributes:linkParams]];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:@" widerrufen." attributes:@{ NSFontAttributeName: UIFont.db_RegularFourteen, NSForegroundColorAttributeName: UIColor.blackColor, NSParagraphStyleAttributeName: paragraphStyle}]];

    self.textLabel.attributedText = text;

    self.noButton = [[MBLargeButton alloc] initWithFrame:CGRectZero];
    [self.noButton setTitle:@"Nein, Danke" forState:UIControlStateNormal];
    [self.noButton addTarget:self action:@selector(decision:) forControlEvents:UIControlEventTouchUpInside];
    self.yesButton = [[MBLargeButton alloc] initWithFrame:CGRectZero];
    [self.yesButton setTitle:@"Ich stimme zu" forState:UIControlStateNormal];
    [self.yesButton setBackgroundColor:[UIColor db_mainColor]];
    [self.yesButton addTarget:self action:@selector(decision:) forControlEvents:UIControlEventTouchUpInside];

    [self.scrollView addSubview:self.noButton];
    [self.scrollView addSubview:self.yesButton];
}

- (BOOL)textView:(UITextView *)textView
shouldInteractWithURL:(NSURL *)URL
         inRange:(NSRange)characterRange
     interaction:(UITextItemInteraction)interaction{
    //display privacy text
    
    MBImprintViewController *imprintViewController =  [[MBImprintViewController alloc] init];
    imprintViewController.title = @"Datenschutz";
    imprintViewController.url = @"datenschutz";
    imprintViewController.openAsModal = YES;
    
    MBNavigationController *imprintNavigationController = [[MBNavigationController alloc] initWithRootViewController:imprintViewController];
    imprintNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;

    [MBTrackingManager trackState:@"data_protection"];

    [self presentViewController:imprintNavigationController animated:YES completion:nil];
    
    return false;
}

-(void)decision:(UIButton*)sender{
    AppDelegate* app = (AppDelegate*)UIApplication.sharedApplication.delegate;
    BOOL enabledTracking = sender == self.yesButton;
    [app userFeedbackOnPrivacyScreen:enabledTracking];
    
    MBStationSearchViewController* parentVC = (MBStationSearchViewController*)self.parentViewController;
    parentVC.privacySetupVisible = NO;
    
    //remove screen
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.scrollView flashScrollIndicators];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    self.scrollView.frame = CGRectMake(0, 0, self.view.sizeWidth, self.view.sizeHeight);
    
    [self.topImage centerViewHorizontalInSuperView];
    [self.topImage setGravityTop:25+self.view.safeAreaInsets.top];
    
    CGSize size = [self.textLabel sizeThatFits:CGSizeMake(self.view.frame.size.width-2*25, 1000)];
    self.textLabel.frame = CGRectMake(25, CGRectGetMaxY(self.topImage.frame)+25, size.width, size.height);
    
    NSInteger y = CGRectGetMaxY(self.textLabel.frame)+20;
    self.yesButton.frame = CGRectMake(15, y, self.view.frame.size.width-2*15, self.yesButton.frame.size.height);
    y += self.yesButton.frame.size.height+20;
    self.noButton.frame = CGRectMake(15, y, self.view.frame.size.width-2*15, self.yesButton.frame.size.height);
    y += self.noButton.frame.size.height+20;
    self.scrollView.contentSize = CGSizeMake(self.scrollView.sizeWidth, y);
}



@end
