// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBMapConsentViewController.h"
#import "UIView+Frame.h"
#import "UIColor+DBColor.h"
#import "UIFont+DBFont.h"
#import "MBLinkButton.h"
#import "MBUrlOpening.h"

#import "MBRootContainerViewController.h"
#import "MBStationSearchViewController.h"

@interface MBMapConsentViewController ()
@property(nonatomic,strong) UIView* darkLayer;


@property(nonatomic,strong) UIView* whiteBackground;

@property(nonatomic,strong) UILabel* headerLabel;
@property(nonatomic,strong) UILabel* textLabel;
@property(nonatomic,strong) MBLinkButton* googleButton;
@property(nonatomic,strong) MBLinkButton* bhfButton;

@property(nonatomic,strong) UIButton* cancelButton;
@property(nonatomic,strong) UIButton* consentButton;
@property(nonatomic,strong) UIView* buttonLine;
@property(nonatomic,strong) UIViewController* vcParent;
@property (nonatomic, copy) void (^consentBlock)(void);


@end

@implementation MBMapConsentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    
    self.whiteBackground = [UIView new];
    self.whiteBackground.layer.cornerRadius = 5;
    self.whiteBackground.backgroundColor = UIColor.whiteColor;
    self.whiteBackground.clipsToBounds = YES;
    [self.view addSubview:self.whiteBackground];

    self.headerLabel = [UILabel new];
    self.headerLabel.textColor = UIColor.blackColor;
    self.headerLabel.text = @"Datenschutzhinweis";
    self.headerLabel.font = UIFont.db_BoldSixteen;
    [self.whiteBackground addSubview:self.headerLabel];
    [self.headerLabel sizeToFit];

    self.textLabel = [UILabel new];
    self.textLabel.textColor = UIColor.blackColor;
    self.textLabel.numberOfLines = 0;
    self.textLabel.text = @"Mit Aktivierung der Karte wird von Ihnen eine Verbindung zu den Servern von Google hergestellt. Dabei übermitteln Sie personenbezogene Daten (mindestens Ihre IP-Adresse) an Google.";
    self.textLabel.font = UIFont.db_RegularFourteen;
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:3];
    NSAttributedString* attr = [[NSAttributedString alloc] initWithString:self.textLabel.text attributes:@{ NSForegroundColorAttributeName:self.textLabel.textColor, NSFontAttributeName: self.textLabel.font, NSParagraphStyleAttributeName: style }];
    self.textLabel.attributedText = attr;
    
    [self.whiteBackground addSubview:self.textLabel];

    self.googleButton = [MBLinkButton boldButtonWithRedLink];
    [self.googleButton setLabelText:@"Datenschutzhinweise von Google"];
    [self.googleButton addTarget:self action:@selector(googlePressed) forControlEvents:UIControlEventTouchUpInside];
    [self.whiteBackground addSubview:self.googleButton];

    self.bhfButton = [MBLinkButton boldButtonWithRedLink];
    [self.bhfButton setLabelText:@"Mehr dazu in unserem Datenschutzhinweis"];
    [self.bhfButton addTarget:self action:@selector(bhfPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.whiteBackground addSubview:self.bhfButton];

    self.cancelButton = [UIButton new];
    [self.cancelButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    self.cancelButton.backgroundColor = UIColor.db_HeaderColor;
    [self.cancelButton setTitle:@"Abbrechen" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    self.cancelButton.titleLabel.font = UIFont.db_RegularSixteen;
    [self.whiteBackground addSubview:self.cancelButton];
    
    self.consentButton = [UIButton new];
    [self.consentButton addTarget:self action:@selector(consent) forControlEvents:UIControlEventTouchUpInside];
    self.consentButton.backgroundColor = UIColor.db_HeaderColor;
    [self.consentButton setTitle:@"Karte anzeigen" forState:UIControlStateNormal];
    [self.consentButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    self.consentButton.titleLabel.font = UIFont.db_RegularSixteen;
    [self.whiteBackground addSubview:self.consentButton];

    self.buttonLine = [UIView new];
    self.buttonLine.backgroundColor = [UIColor dbColorWithRGB:0x91969D];
    [self.whiteBackground addSubview:self.buttonLine];
}

-(void)googlePressed{
    [MBUrlOpening openURL:[NSURL URLWithString:@"https://policies.google.com/privacy?hl=de"]];
}
-(void)bhfPressed{
    [MBStationSearchViewController displayDataProtectionOn:self];
    
}
-(void)cancel{
    [self hideWithCompletion:^{
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.vcParent.view);
        self.vcParent = nil;
    }];
}
-(void)consent{
    [self hideWithCompletion:^{
        self.consentBlock();
        self.vcParent = nil;
    }];
}

-(void)hideWithCompletion: (void (^ __nullable)(void))completion{
    [self.darkLayer removeFromSuperview];
    self.darkLayer = nil;
    [self dismissViewControllerAnimated:YES completion:completion];
}

-(BOOL)accessibilityPerformEscape{
    [self cancel];
    return YES;
}


+(void)presentAlertOnViewController:(UIViewController*)vc consentCompletion:(void (^)(void))completion{
    MBMapConsentViewController* consent = [MBMapConsentViewController new];
    consent.consentBlock = completion;
    consent.modalPresentationStyle = UIModalPresentationOverFullScreen;
    consent.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

    consent.vcParent = vc;
    consent.darkLayer = [UIView new];
    consent.darkLayer.backgroundColor = UIColor.blackColor;
    consent.darkLayer.alpha = 0.7;
    UIViewController* presentingVC = MBRootContainerViewController.rootViewController;
    if(presentingVC.presentedViewController){
        presentingVC = presentingVC.presentedViewController;
    }
    [presentingVC.view addSubview:consent.darkLayer];
    consent.darkLayer.frame = CGRectMake(0, 0, presentingVC.view.frame.size.width, presentingVC.view.frame.size.height);
    
    [vc presentViewController:consent animated:YES completion:^{
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, consent.view);
    }];

}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    NSInteger maxWidth = MIN(342,self.view.frame.size.width-2*16);
    NSInteger textWidth = maxWidth - 2*16;
    self.whiteBackground.frame = CGRectMake(0, 0, maxWidth, 500);//height updated later
    [self.headerLabel setGravityTop:20];
    [self.headerLabel centerViewHorizontalInSuperView];
    
    CGSize textSize = [self.textLabel sizeThatFits:CGSizeMake(textWidth, 2000)];
    self.textLabel.frame = CGRectMake(16, 0, ceil(textSize.width), ceil(textSize.height));
    [self.textLabel setBelow:self.headerLabel withPadding:12];

    [self.googleButton setBelow:self.textLabel withPadding:20];
    [self.bhfButton setBelow:self.googleButton withPadding:20];
    [self.googleButton setGravityLeft:16];
    [self.bhfButton setGravityLeft:16];
    
    if(CGRectGetMaxX(self.bhfButton.frame) > self.whiteBackground.sizeWidth-16){
        //button too long (iphone5)
        self.bhfButton.titleLabel.numberOfLines = 0;
        CGRect f = self.bhfButton.frame;
        f.size.height = f.size.height*2;
        f.size.width = self.whiteBackground.sizeWidth-2*16;
        self.bhfButton.frame = f;
    }

    self.cancelButton.frame = CGRectMake(0, 0, maxWidth/2, 44);
    [self.cancelButton setBelow:self.bhfButton withPadding:30];
    self.consentButton.frame = CGRectMake(0, 0, maxWidth/2, 44);
    [self.consentButton setBelow:self.bhfButton withPadding:30];
    [self.consentButton setGravityRight:0];
    self.buttonLine.frame = CGRectMake(self.cancelButton.frame.size.width, 0, 1, 24);
    [self.buttonLine setBelow:self.bhfButton withPadding:30+10];

    self.whiteBackground.frame = CGRectMake(0, 0, maxWidth, CGRectGetMaxY(self.cancelButton.frame));
    [self.whiteBackground centerViewInSuperView];
    
}

@end
