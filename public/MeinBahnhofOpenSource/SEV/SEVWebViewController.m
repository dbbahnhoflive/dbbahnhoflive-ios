// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "SEVWebViewController.h"

@interface SEVWebViewController ()<WKScriptMessageHandler>
@property(nonatomic,strong) SEVWebView* webView;
@end

@implementation SEVWebViewController
//BAHNHOFLIVE-2519

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Zurück" style:UIBarButtonItemStyleDone target:self action:@selector(closeWebView)];
        self.title = @"DB Wegbegleitung";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    WKWebViewConfiguration* config = [[WKWebViewConfiguration alloc] init];
    WKUserContentController* userContentController = [[WKUserContentController alloc] init];
    [userContentController addScriptMessageHandler:self name:@"BahnhofLive"];
    config.userContentController = userContentController;
    
    WKWebpagePreferences* preferences = [WKWebpagePreferences new];
    preferences.allowsContentJavaScript = true;
    preferences.preferredContentMode = WKContentModeRecommended;
    config.defaultWebpagePreferences = preferences;
    config.allowsInlineMediaPlayback = true;
    config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    
    self.webView = [[SEVWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) configuration:config];
    [self.view addSubview:self.webView];
    [self.webView loadService];
}
- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    NSLog(@"didReceiveScriptMessage: %@",message);
    if([message.name isEqualToString:@"BahnhofLive"]){
        if([message.body isKindOfClass:NSString.class]){
            NSString* body = message.body;
            if([body isEqualToString:@"close"]){
                [self.navigationController dismissViewControllerAnimated:true completion:nil];
            }
        }
    }
}



+(BOOL)wegbegleitungIsActiveTime{
    NSDateComponents *components = [NSCalendar.currentCalendar components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitWeekday) fromDate:NSDate.now];
    BOOL isActive = false;
    //active daily between 7:00-19:00
    if(components.hour >= 7 && components.hour < 19){//} && components.weekday >= 2 && components.weekday <=6){//So=1, Mo=2, Di=3, Mi=4, Do=5, Fr=6
        isActive = true;
    }/* else if(components.hour == 7){
        if(components.minute >= 30){
            isActive = true;
        }
    } else if(components.hour == 18){
        if(components.minute < 30){
            isActive = true;
        }
    }*/
    return isActive;
}

-(void)closeWebView{
    [self.navigationController.presentingViewController dismissViewControllerAnimated:true completion:nil];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.webView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}


@end
