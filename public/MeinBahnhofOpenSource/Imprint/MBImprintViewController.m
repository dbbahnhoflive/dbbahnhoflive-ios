// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBImprintViewController.h"
#import "MBNavigationController.h"
#import "MBUrlOpening.h"
#import "MBUIHelper.h"
#import "MBTrackingManager.h"

@import WebKit;

@interface MBImprintViewController()<WKNavigationDelegate>

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UIView *iconBackground;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) MBTextView *htmlTextView;
@property (nonatomic, strong) WKWebView *webView;

@end

@implementation MBImprintViewController


-(instancetype)init{
    self = [super init];
    if(self){
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}


- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    
    UIView* iconBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.sizeWidth, 100)];
    iconBackground.backgroundColor = [UIColor db_grayBackgroundColor];
    [self.scrollView addSubview:iconBackground];
    self.iconBackground = iconBackground;
    
    self.iconView = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"IconImprint"]];
    [iconBackground addSubview:self.iconView];
    [self.iconView centerViewInSuperView];

    
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[WKWebViewConfiguration new]];
    self.webView.navigationDelegate = self;
    [self.webView.scrollView addSubview:iconBackground];
    [self.view addSubview:self.webView];
    
    if (self.openAsModal) {
        self.navigationItem.leftBarButtonItem = nil;
    }
}

- (void) setUrl:(NSString *)url
{
    _url = url;
}

- (void) setOpenAsModal:(BOOL)openAsModal
{
    _openAsModal = openAsModal;
    
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Schließen" style:UIBarButtonItemStyleDone target:self action:@selector(closeModal:)];
    [closeButton setTitleTextAttributes:@{NSFontAttributeName: [UIFont db_RegularFourteen]} forState:UIControlStateNormal];
    
    self.navigationItem.rightBarButtonItem = closeButton;
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor blackColor];
}

- (void) closeModal:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (NSString*) loadWebViewContent:(NSString*)url
{
    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:url ofType:@"html"];
    NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *build   = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *versionInfo = [NSString stringWithFormat:@"%@ (%@)", version, build];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"{APP_VERSION}" withString:versionInfo];
    return htmlString;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    ((MBNavigationController*)self.navigationController).swipeBackGestureEnabled = YES;
    
    if ([self.url isEqualToString:@"datenschutz"]) {
        self.iconView.image = [UIImage db_imageNamed:@"IconDatenschutz"];
        [MBTrackingManager trackStates:@[@"d2", @"datenschutz"]];
    } else {
        self.iconView.image = [UIImage db_imageNamed:@"IconImprint"];
        [MBTrackingManager trackStates:@[@"d2", @"impressum"]];
    }

    self.webView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    [self.webView loadHTMLString:[self loadWebViewContent:_url] baseURL:[[NSBundle mainBundle] bundleURL]];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{

    if ([navigationAction.request.URL.scheme isEqualToString:@"file"]) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    } else {
        if ([navigationAction.request.URL.scheme isEqualToString:@"settings"]) {
            [MBUrlOpening openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            decisionHandler(WKNavigationActionPolicyCancel);
        } else {
            [MBUrlOpening openURL:navigationAction.request.URL];
            decisionHandler(WKNavigationActionPolicyCancel);
        }
    }
}


- (void) didInteractWithURL:(NSURL*)url;
{
    if ([url.scheme isEqualToString:@"settings"]) {
        [MBUrlOpening openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    } else {
        [MBUrlOpening openURL:url];
    }
}

@end
