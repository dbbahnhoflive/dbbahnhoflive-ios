// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBFeedbackViewController.h"
#import "MBLabel.h"
#import "MBTextView.h"
#import "MBStationNavigationViewController.h"
#import <sys/utsname.h>
#import "AppDelegate.h"

@interface MBFeedbackViewController ()

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UIView *iconDivider;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *container;

@end

@implementation MBFeedbackViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.container = [[UIView alloc] init];
    
    if ([self.navigationController isKindOfClass:[MBStationNavigationViewController class]]) {
        [(MBStationNavigationViewController *)self.navigationController hideNavbar:NO];
        [(MBStationNavigationViewController *)self.navigationController showBackgroundImage:NO];
        [(MBStationNavigationViewController *)self.navigationController setShowRedBar:YES];
    }

    CGRect scrollViewFrame;
    if (ISIPAD) {
        double width = self.view.sizeWidth/2;
        scrollViewFrame = CGRectMake(self.view.sizeWidth/2-width/2, 0, width, self.view.sizeHeight);
    } else {
        scrollViewFrame = self.view.frame;
    }
    
    self.container.frame = scrollViewFrame;
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    self.scrollView.clipsToBounds = NO;
    
    UIView* iconBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.sizeWidth, 100)];
    iconBackground.backgroundColor = [UIColor db_grayBackgroundColor];
    [self.scrollView addSubview:iconBackground];
    
    self.iconView = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_dialog"]];
    [iconBackground addSubview:self.iconView];
    [self.iconView centerViewInSuperView];

    int y = [self addHeadline:@"Zufrieden mit der App?"
                      content:@"Unterstützen Sie uns mit einer positiven Bewertung im App Store."
                   buttonText:@"App bewerten"
               buttonSelector:@selector(didTapOnRatingButton:)
                          atY:CGRectGetMaxY(iconBackground.frame)+20];
    y = [self addHeadline:@"Kontakt"
                  content:@"Schreiben Sie uns, sollten Ihnen Unstimmigkeiten in der App auffallen."
               buttonText:@"Kontakt aufnehmen"
           buttonSelector:@selector(didTapOnFeedbackButton:) atY:y+20];
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.sizeWidth, y+10);
    
    [self.scrollView addSubview:self.container];
    
    [self.view addSubview:self.scrollView];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [MBTrackingManager trackStatesWithStationInfo:@[@"d2", @"feedback"]];
}

-(int)addHeadline:(NSString*)headline content:(NSString*)content buttonText:(NSString*)buttonText buttonSelector:(SEL)selector atY:(int)y
{
    MBLabel *headlineLabel = [[MBLabel alloc] initWithFrame:CGRectMake(20, y, self.container.sizeWidth-2*20, 20)];
    headlineLabel.font = [UIFont db_BoldFourteen];
    headlineLabel.text = headline;
    headlineLabel.textColor = [UIColor db_333333];
    
    MBTextView *contentLabel = [[MBTextView alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(headlineLabel.frame)+10, self.container.sizeWidth-2*20, 0)];
    contentLabel.dataDetectorTypes = UIDataDetectorTypeNone;
    contentLabel.font = [UIFont db_RegularFourteen];
    contentLabel.text = content;
    contentLabel.textColor = [UIColor db_333333];
    contentLabel.userInteractionEnabled = YES;
    [contentLabel sizeToFit];
    
    UIButton *redButton = [[UIButton alloc] initWithFrame: CGRectMake(20, CGRectGetMaxY(contentLabel.frame)+10, self.container.sizeWidth-2*20, 60)];
    [redButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [redButton setTitle:buttonText forState:UIControlStateNormal];

    redButton.layer.shadowOffset = CGSizeMake(1,1);
    redButton.layer.shadowColor = [[UIColor db_dadada] CGColor];
    redButton.layer.shadowRadius = 2;
    redButton.layer.shadowOpacity = 1.0;
    redButton.layer.cornerRadius = redButton.frame.size.height / 2.0;
    [redButton setBackgroundColor:[UIColor dbColorWithRGB:0x9A9EA5]];
    [redButton.titleLabel setFont:[UIFont db_BoldEighteen]];
    
    [redButton addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    
    [self.container addSubview:headlineLabel];
    [self.container addSubview:contentLabel];
    [self.container addSubview:redButton];
    
    return CGRectGetMaxY(redButton.frame);
}


- (void)didTapOnRatingButton:(id)sender
{
    [MBTrackingManager trackActionsWithStationInfo:@[TRACK_KEY_FEEDBACK, @"rating"]];
    [MBFeedbackViewController openStorePage];
}

- (void)didTapOnFeedbackButton:(id)sender
{
    [MBTrackingManager trackActionsWithStationInfo:@[TRACK_KEY_FEEDBACK, @"contact"]];
    [self openFeedbackMail];
}

- (void)openFeedbackMail
{
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build   = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *versionInfo = [NSString stringWithFormat:@"%@ (%@)", version, build];

    NSString *device      = [[UIDevice currentDevice] localizedModel];
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString* model= [NSString stringWithCString:systemInfo.machine
                                        encoding:NSUTF8StringEncoding];
    NSString* os = [[UIDevice currentDevice] systemVersion];
    NSString* deviceInfo = [NSString stringWithFormat:@"%@, %@ (%@)",device,model,os];
    
    NSString* subject = [@"Feedback DB Bahnhof live App" stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    NSString* body = [[NSString stringWithFormat:@"\n\n\n\nUm meine folgenden Anmerkungen leichter nachvollziehen zu können, sende ich Ihnen anbei meine Geräteinformationen:\nBahnhof: %@ (%@)\nGerät: %@\nApp-Version: %@",self.station.title,self.station.mbId,deviceInfo,
                       versionInfo] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    NSString *mailString = [NSString stringWithFormat:@"mailto:marketing-bahnhoefe@deutschebahn.com?subject=%@&body=%@", subject, body];
    
    NSURL* url = [NSURL URLWithString:mailString];
    
    [[AppDelegate appDelegate] openURL:url];
}

+ (void)openStorePage
{
    [[AppDelegate appDelegate] openURL:[NSURL URLWithString:@"https://appsto.re/de/6Kxhbb.i"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
