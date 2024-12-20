// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBStaticServiceView.h"
#import "MBLabel.h"

#import "MBUrlOpening.h"
#import "MBTravelcenter.h"
#import "MBButtonWithData.h"
#import "MBExternalLinkButton.h"
#import <sys/utsname.h>
#import "MBPlatformAccessibilityView.h"
#import "MBUIHelper.h"
#import "MBTrackingManager.h"
#import "MBRoutingHelper.h"
#import "MBLargeButton.h"
#import "MBContentSearchResult.h"
#import "MBRootContainerViewController.h"
#import "MBARAppTeaserView.h"
#import "SEVWebViewController.h"
#import "MBLinkButton.h"
#import "MBWegbegleitungInfoViewController.h"
#import "SEVWebViewController.h"

@interface MBStaticServiceView() <MBTextViewDelegate>
@property (nonatomic, weak) UIViewController* viewController;
@property (nonatomic, strong) MBService *service;
@property (nonatomic, strong) MBStation *station;

@property(nonatomic) BOOL fullscreenLayout;
@end

@implementation MBStaticServiceView

- (instancetype) initWithService:(MBService*)service station:(MBStation*)station viewController:(UIViewController*)vc fullscreenLayout:(BOOL)fullscren andFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.clipsToBounds = YES;
        self.fullscreenLayout = fullscren;
        self.service = service;
        self.station = station;
        self.viewController = vc;
        
        [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self setupViews];
    }
    return self;
}

-(NSString*)firstHeaderAddressString{
    NSMutableString* addressString = [[NSMutableString alloc] init];
    [addressString appendString:self.service.addressHeader];
    [addressString appendString:@"\n"];
    [addressString appendString:self.service.addressStreet];
    [addressString appendString:@"\n"];
    [addressString appendString:self.service.addressPLZ];
    [addressString appendString:@" "];
    [addressString appendString:self.service.addressCity];
    return addressString;
}

- (void)setupViews
{
    UIView* baseView = self;
    __block CGPoint offset = CGPointMake(0, 0);
    __block CGSize contentSize = CGSizeMake(self.frame.size.width, 0);

    if(self.fullscreenLayout){
        // all content is added in a scrollview and we have an image at the top
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0,0,self.frame.size.width, self.frame.size.height)];
        baseView = scrollView;
        scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        scrollView.contentInset = UIEdgeInsetsMake(0, 0, 80+80, 0);//+60 is for the tabbar, this view is not correctly resized by the parent!
        UIView* iconBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, scrollView.sizeWidth, 100)];
        iconBackground.backgroundColor = [UIColor db_grayBackgroundColor];
        [scrollView addSubview:iconBackground];
        
        UIImageView *iconView = [[UIImageView alloc] initWithImage:[self.service iconForType]];
        if(iconView.size.height > iconBackground.sizeHeight-2*10){
            //reduce size
            iconView.contentMode = UIViewContentModeScaleAspectFit;
            NSInteger newHeight = iconBackground.sizeHeight - 2-2*25;
            NSInteger newWidth = iconBackground.sizeWidth;
            iconView.frame = CGRectMake(0, 0, newWidth, newHeight);
        }
        [iconBackground addSubview:iconView];
        [iconView centerViewInSuperView];
        offset = CGPointMake(0, iconBackground.frame.size.height+20);
        contentSize = CGSizeMake(scrollView.frame.size.width, offset.y);
    } else {
        //content is layouted inside a tableview, reduced width
        offset.y = 8;
        contentSize.height = 8;
        contentSize.width -= 16;
    }
     
    
    if(self.service.firstHeader){
        //this is only used for adress and routing
        UIButton* naviButton = [self createNaviButton];
        [baseView addSubview:naviButton];
        [naviButton setGravityRight:15];
        [naviButton setGravityTop:offset.y];

        MBLabel *headlineLabel = [[MBLabel alloc] initWithFrame:CGRectMake(15, offset.y, contentSize.width-2*15, 0)];
        headlineLabel.font = [UIFont db_HelveticaBoldFourteen];
        headlineLabel.text = self.service.firstHeader;
        headlineLabel.textColor = [UIColor db_333333];
        [self sizeViewForWidth:headlineLabel];
        NSInteger height = ceil(headlineLabel.frame.size.height)+5;
        offset.y += height;
        contentSize.height += height;
        [baseView addSubview:headlineLabel];

        MBTextView *descriptionHTMLLabel = [[MBTextView alloc] initWithFrame:CGRectMake(15, offset.y, contentSize.width-2*15, 0)];
        descriptionHTMLLabel.dataDetectorTypes = UIDataDetectorTypeNone;
        descriptionHTMLLabel.htmlString = self.firstHeaderAddressString;
        descriptionHTMLLabel.delegado = self;
        [self sizeViewForWidth:descriptionHTMLLabel];
        height = ceil(descriptionHTMLLabel.frame.size.height)+20;
        offset.y += height;
        contentSize.height += height;
        [baseView addSubview:descriptionHTMLLabel];
    }
    if(self.service.secondHeader){
        MBLabel *headlineLabel = [[MBLabel alloc] initWithFrame:CGRectMake(15, offset.y, contentSize.width-2*15, 0)];
        headlineLabel.font = [UIFont db_HelveticaBoldFourteen];
        headlineLabel.text = self.service.secondHeader;
        headlineLabel.textColor = [UIColor db_333333];
        [self sizeViewForWidth:headlineLabel];
        NSInteger height = ceil(headlineLabel.frame.size.height)+5;
        offset.y += height;
        contentSize.height += height;
        [baseView addSubview:headlineLabel];
        
        MBTextView *descriptionHTMLLabel = [[MBTextView alloc] initWithFrame:CGRectMake(15, offset.y, contentSize.width-2*15, 0)];
        descriptionHTMLLabel.dataDetectorTypes = UIDataDetectorTypeNone;
        descriptionHTMLLabel.htmlString = self.service.secondText;
        descriptionHTMLLabel.delegado = self;
        [self sizeViewForWidth:descriptionHTMLLabel];
        height = ceil(descriptionHTMLLabel.frame.size.height)+20;
        offset.y += height;
        contentSize.height += height;
        [baseView addSubview:descriptionHTMLLabel];
    }
    
    
    NSArray *descriptionComponents = [self.service descriptionTextComponents];
    if (descriptionComponents && descriptionComponents.count > 0) {
        [descriptionComponents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            if ([obj isKindOfClass:[NSString class]]) {
                
                MBTextView *descriptionHTMLLabel = [[MBTextView alloc] initWithFrame:CGRectMake(15, offset.y, contentSize.width-2*15, 0)];
                descriptionHTMLLabel.htmlString = obj;
                descriptionHTMLLabel.delegado = self;
                [self sizeViewForWidth:descriptionHTMLLabel];
                
                offset.y += descriptionHTMLLabel.frame.size.height;
                contentSize.height += descriptionHTMLLabel.frame.size.height;
                
                [baseView addSubview:descriptionHTMLLabel];
                
            } else if ([obj isKindOfClass:[NSDictionary class]]) {
                //title, is this a phone number or an action button?
                NSString *phoneNumber = obj[kPhoneKey];
                NSString *actionButton = obj[kActionButtonKey];
                NSString *actionButtonType = obj[kActionButtonType];
                NSString *imageName = obj[kImageKey];
                NSString *specialAction = obj[kSpecialAction];
                NSString *buttonActionString = obj[kActionButtonAction];
                if(specialAction){
                    if([specialAction isEqualToString:kSpecialActionPlatformAccessibiltyUI]){
                        //this view will resize its parent when the content changes
                        NSString* platform = self.service.serviceConfiguration[MB_SERVICE_ACCESSIBILITY_CONFIG_KEY_PLATFORM];
                        
                        MBPlatformAccessibilityView* av = [[MBPlatformAccessibilityView alloc] initWithFrame:CGRectMake(0, offset.y, contentSize.width, 0) station:self.station platform:platform];
                        av.viewController = self.viewController;
                        [baseView addSubview:av];
                        contentSize.height += av.frame.size.height;
                        offset.y += av.frame.size.height;
                    } else if([specialAction isEqualToString:kSpecialActionAR_Teaser]){
                        offset.y += 10;
                        contentSize.height += 10;
                        UIView* container = [UIView new];
                        container.backgroundColor = UIColor.whiteColor;
                        container.layer.shadowOffset = CGSizeMake(0,0);
                        container.layer.shadowColor = [[UIColor db_dadada] CGColor];
                        container.layer.shadowRadius = 3;
                        container.layer.shadowOpacity = 1.0;
                        MBARAppTeaserView* av = [MBARAppTeaserView new];
                        [container addSubview:av];
                        container.frame = CGRectMake(16, offset.y, contentSize.width-2*16, 180);
                        av.frame = CGRectMake(0, 0, container.sizeWidth, container.sizeHeight);
                        [baseView addSubview:container];
                        contentSize.height += container.frame.size.height + 20;
                        offset.y += container.frame.size.height + 20;
                    } else {
                        NSLog(@"ERROR: unknown special action: %@",specialAction);
                    }
                } else if(imageName){
                    UIImageView* imgV = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:imageName]];
                    imgV.contentMode = UIViewContentModeScaleAspectFit;
                    NSInteger imgH = 100;
                    imgV.frame = CGRectMake(0, offset.y, contentSize.width, imgH);
                    offset.y += imgV.frame.size.height+10;
                    contentSize.height += imgV.frame.size.height+10;
                    [baseView addSubview:imgV];
                    
                } else if(phoneNumber || actionButton){
                    offset.y += 20;
                    contentSize.height += 20;
                    
                    if([actionButtonType isEqualToString:@"action"]){
                        CGFloat width = (int) MIN(345, (contentSize.width-2*15));
                        MBButtonWithData *redPhoneButton = [[MBButtonWithData alloc] initWithFrame: CGRectMake((int)((contentSize.width-width)/2), offset.y, width, 60)];
                        redPhoneButton.layer.shadowOffset = CGSizeMake(1,1);
                        redPhoneButton.layer.shadowColor = [[UIColor db_dadada] CGColor];
                        redPhoneButton.layer.shadowRadius = 2;
                        redPhoneButton.layer.shadowOpacity = 1.0;
                        redPhoneButton.layer.cornerRadius = redPhoneButton.frame.size.height / 2.0;
                        
                        [redPhoneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                        
                        if(phoneNumber){
                            [redPhoneButton setTitle:phoneNumber forState:UIControlStateNormal];
                            [redPhoneButton addTarget:self action:@selector(didTapOnPhoneButton:) forControlEvents:UIControlEventTouchUpInside];
                        } else {
                            [redPhoneButton setTitle:actionButton forState:UIControlStateNormal];
                            redPhoneButton.data = buttonActionString;
                            [redPhoneButton addTarget:self action:@selector(didTapOnActionButton:) forControlEvents:UIControlEventTouchUpInside];
                        }
                        [redPhoneButton setBackgroundColor:[UIColor db_GrayButton]];
                        [redPhoneButton.titleLabel setFont:[UIFont db_BoldEighteen]];
                        
                        
                        offset.y += redPhoneButton.frame.size.height+10;
                        contentSize.height += redPhoneButton.frame.size.height+10;
                        
                        [baseView addSubview:redPhoneButton];
                    } else if([actionButtonType isEqualToString:@"intern"] || [actionButtonType isEqualToString:@"extern"]){
                        MBLinkButton* linkButton = nil;
                        if([actionButtonType isEqualToString:@"intern"]){
                            linkButton = [MBLinkButton boldButtonWithRedLink];
                        } else {
                            linkButton = [MBLinkButton boldButtonWithRedExternalLink];
                        }
                        linkButton.data = buttonActionString;
                        [linkButton setLabelText:actionButton];
                        [linkButton addTarget:self action:@selector(didTapOnActionButton:) forControlEvents:UIControlEventTouchUpInside];
                        [linkButton setGravityLeft:16];
                        [linkButton setGravityTop:offset.y];
                        if(CGRectGetMaxX(linkButton.frame) >= baseView.frame.size.width){
                            //wrap button in two lines
                            CGRect f = linkButton.frame;
                            linkButton.titleLabel.numberOfLines = 0;
                            f.size.width = baseView.frame.size.width-f.origin.x;
                            f.size.height = f.size.height*2;
                            linkButton.frame = f;
                        }
                        offset.y += linkButton.frame.size.height+10;
                        contentSize.height += linkButton.frame.size.height+10;
                        
                        [baseView addSubview:linkButton];

                    }
                }
            }
        }];
    }
    
    if(self.service.openingTimesOSM.hasOpenTimes){
        offset.y += 15;
        contentSize.height += 15;

        __block CGFloat x = 15;
        CGFloat width = contentSize.width-2*x;
        
        MBTextView* headline = [MBTextView new];
        headline.font = [UIFont db_BoldFourteen];
        headline.textColor = UIColor.db_333333;
        headline.text = @"Öffnungszeiten";
        [headline sizeToFit];
        [baseView addSubview:headline];
        [headline setGravityLeft:x];
        [headline setGravityTop:offset.y];
        CGFloat entryHeight = (headline.frame.size.height);
        entryHeight += 10;
        offset.y += entryHeight;
        contentSize.height += entryHeight;

        MBTextView* timeintervalLabel = [MBTextView new];
        timeintervalLabel.font = [UIFont db_ItalicFourteen];
        timeintervalLabel.textColor = UIColor.db_333333;
        timeintervalLabel.text = self.service.openingTimesOSM.weekstringForDisplay;
        [timeintervalLabel sizeToFit];
        [baseView addSubview:timeintervalLabel];
        [timeintervalLabel setGravityLeft:x];
        [timeintervalLabel setGravityTop:offset.y];
        entryHeight = (timeintervalLabel.frame.size.height);
        entryHeight += 10;
        offset.y += entryHeight;
        contentSize.height += entryHeight;

        NSArray* weekdays = self.service.openingTimesOSM.calculateWeekdays;
        NSInteger index = 0;
        for(NSString* day in weekdays){
            UIView* todayBackground = nil;
            if(index == 0){
                todayBackground = [UIView new];
                todayBackground.backgroundColor = [UIColor db_f0f3f5];
                [baseView addSubview:todayBackground];
                [todayBackground setGravityTop:offset.y];
                [todayBackground setWidth:contentSize.width];
            }
            
            offset.y += 5;
            contentSize.height += 5;
            
            UILabel* weekdayLabel = [UILabel new];
            weekdayLabel.isAccessibilityElement = NO;
            weekdayLabel.font = [UIFont db_BoldFourteen];
            weekdayLabel.textColor = UIColor.db_333333;
            weekdayLabel.text = day;
            [weekdayLabel sizeToFit];
            [baseView addSubview:weekdayLabel];
            [weekdayLabel setGravityLeft:x];
            [weekdayLabel setGravityTop:offset.y];
            
            //Note: VO does not read a UILabel correctly in the tablecell that's why we need to use UITextViews. To read the weekday together with the opening times we add them in a hidden (clear text) view:
            MBTextView* hiddenLabel = [MBTextView new];
            [baseView addSubview:hiddenLabel];
            [hiddenLabel setGravityLeft:x];
            [hiddenLabel setGravityTop:offset.y];
            hiddenLabel.backgroundColor = UIColor.clearColor;
            hiddenLabel.textColor = UIColor.clearColor;

            NSMutableString* voiceOverString = [NSMutableString new];
            [voiceOverString appendString:day];
            [voiceOverString appendString:@": "];

            NSArray* openTimes = [self.service.openingTimesOSM openTimesForDay:index];
            NSInteger timeHeight = 0;
            for(NSString* time in openTimes){
                UILabel* timeLabels = [UILabel new];
                timeLabels.isAccessibilityElement = NO;
                timeLabels.font = [UIFont db_RegularFourteen];
                timeLabels.numberOfLines = 0;
                timeLabels.textColor = UIColor.db_333333;
                timeLabels.text = time;
                [voiceOverString appendString:time];
                [voiceOverString appendString:@", "];
                /*
                NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:timeLabels.text];
                NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
                paragraphStyle.lineSpacing = 4;
                [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, timeLabels.text.length)];
                timeLabels.attributedText = attributedString;
                */
                CGSize size = [timeLabels sizeThatFits:CGSizeMake(width/2, 3000)];
                [timeLabels setSize:CGSizeMake(ceil(size.width), ceilf(size.height))];
                [baseView addSubview:timeLabels];
                [timeLabels setGravityLeft:width/2];
                [timeLabels setGravityTop:offset.y+timeHeight];

                timeHeight += timeLabels.sizeHeight + 5;
            }
            
            entryHeight = MAX(weekdayLabel.sizeHeight, timeHeight);
            [todayBackground setHeight:entryHeight+10];
            entryHeight += 5;
            offset.y += entryHeight;
            contentSize.height += entryHeight;
            index++;
            
            hiddenLabel.text = voiceOverString;
            [hiddenLabel setSize:CGSizeMake(width, entryHeight)];

        }
    }
    
    if (self.service.additionalText && self.service.additionalText.length > 0) {
        offset.y += 10;
        contentSize.height += 10;
        MBTextView *additionalTextHTMLLabel = [[MBTextView alloc] initWithFrame:CGRectMake(15, offset.y, contentSize.width-2*15, 0)];
        additionalTextHTMLLabel.htmlString = self.service.additionalText;
        [self sizeViewForWidth:additionalTextHTMLLabel];
                
        [baseView addSubview:additionalTextHTMLLabel];
        
        offset.y += additionalTextHTMLLabel.frame.size.height;
        contentSize.height += additionalTextHTMLLabel.frame.size.height;
    }
    
    contentSize.height += 16;
    if([baseView isKindOfClass:UIScrollView.class]){
        contentSize.height += 30;
        ((UIScrollView*)baseView).contentSize = contentSize;
        [self addSubview:baseView];
    } else {
        [self setSize:CGSizeMake(self.frame.size.width, contentSize.height)];
    }
}

-(void)sizeViewForWidth:(UIView*)v{
//    [v sizeToFit];//this is broken
    CGSize size = [v sizeThatFits:CGSizeMake(v.size.width, 3000)];
    [v setSize:CGSizeMake(ceilf(size.width), ceilf(size.height))];
}


-(UIButton*)createNaviButton{
    UIButton* navigationButton = [MBExternalLinkButton createButton];
    [navigationButton addTarget:self action:@selector(naviButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return navigationButton;
}
-(void)naviButtonTapped:(id)sender{
    [MBRoutingHelper routeToName:self.service.travelCenter.title location:self.service.travelCenter.coordinate fromViewController:nil];
}


- (void) layoutSubviews
{
    [super layoutSubviews];
    if (!_fullscreenLayout) {
        
    }
}

-(NSInteger)layoutForSize:(NSInteger)frameWidth{
    //this view is fixed layouted on init
    return self.frame.size.height;
}



- (void)didInteractWithURL:(NSURL *)url
{
    if ([url.absoluteString rangeOfString:@"tel:"].location != NSNotFound) {
        NSString *phoneString = [url.absoluteString stringByReplacingOccurrencesOfString:@"tel:" withString:@""];
        phoneString = [phoneString stringByReplacingOccurrencesOfString:@"%20" withString:@""];
        [self.delegate didTapOnPhoneLink:phoneString];
    } else if ([url.absoluteString rangeOfString:@"mailto:"].location != NSNotFound) {
        [self.delegate didTapOnEmailLink:url.absoluteString];
    } else if([url.absoluteString isEqualToString:kActionMobilitaetsService]){
        MBRootContainerViewController* root = [MBRootContainerViewController currentlyVisibleInstance];
        MBContentSearchResult* search = [MBContentSearchResult searchResultWithKeywords:CONTENT_SEARCH_KEY_STATIONINFO_SERVICES_MOBILITY_SERVICE];
        [root handleSearchResult:search];
    } else {
        [self.delegate didOpenUrl:url];
    }
}

- (void) didTapOnPhoneButton:(id)sender
{
    NSString *phoneNumber = ((UIButton*)sender).titleLabel.text;
    [self.delegate didTapOnPhoneLink:phoneNumber];
}
-(void)didTapOnActionButton:(MBButtonWithData*)sender{
    NSString* action = sender.data;
    if([action isEqualToString:kActionChatbot]){
        [MBTrackingManager trackActionsWithStationInfo:@[@"d1",@"tap",@"chatbot"]];
        [MBUrlOpening openURL:[NSURL URLWithString:@"https://bahnhof-bot.deutschebahn.com/"]];
    } else if([action isEqualToString:kActionFeedbackMail]){
        [self openFeedbackMail];
    } else if([action isEqualToString:kActionFeedbackChatbotMail]){
        [self chatBotMail];
    } else if([action isEqualToString:kActionFeedbackVerschmutzungMail]){
        [self feedbackDirtViaWhatspp:false];
    } else if([action isEqualToString:kActionWhatsAppFeedback]){
        [self feedbackDirtViaWhatspp:true];
    } else if([action isEqualToString:kActionWegbegleitung]){
        //BAHNHOFLIVE-2519
        [MBTrackingManager trackActionsWithStationInfo:@[@"d1",@"schienenersatzverkehr",@"wegbegleitung",@"video"]];
        MBRootContainerViewController* root = [MBRootContainerViewController currentlyVisibleInstance];
        if([SEVWebViewController wegbegleitungIsActiveTime]){
            SEVWebViewController* web = [SEVWebViewController new];
            UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:web];
            nav.modalPresentationStyle = UIModalPresentationFullScreen;
            [root presentViewController:nav animated:true completion:nil];
        } else {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Servicezeiten" message:@"Leider rufen Sie außerhalb unserer Servicezeiten an. Diese sind täglich von 07:00 Uhr bis 19:00 Uhr." preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            }]];
            [root presentViewController:alert animated:true completion:nil];
        }
    } else if([action isEqualToString:kActionWegbegleitung_info]){
        //BAHNHOFLIVE-2519
        UIViewController* wegbegleitungInfo = [[MBWegbegleitungInfoViewController alloc] initWithStation:self.station];
        UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:wegbegleitungInfo];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        MBRootContainerViewController* root = [MBRootContainerViewController currentlyVisibleInstance];
        [root presentViewController:nav animated:true completion:nil];
    } else {
        if([action isEqualToString:NEW_APP_LINK]){
            [MBTrackingManager trackActionsWithStationInfo:@[@"d1",@"nextapp",@"appstore"]];
        }
        NSURL* url = [NSURL URLWithString:action];
        if(url){
            [MBUrlOpening openURL:url];
        }
    }
}


-(void)feedbackDirtViaWhatspp:(BOOL)useWhatsapp{
    NSString* s = [NSString stringWithFormat:@"Sehr geehrte Damen und Herren, mir ist eine Verschmutzung an folgendem Bahnhof aufgefallen: %@ (%@). ",self.station.title,self.station.mbId];
    s = [s stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    NSString* link = nil;
    if(useWhatsapp){
        link = [NSString stringWithFormat:@"https://wa.me/4915792397402?text=%@",s];
    } else {
        NSString* subject = [[NSString stringWithFormat:@"Verschmutzungs-Meldung %@ (%@)",self.station.title,self.station.mbId] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
        link = [NSString stringWithFormat:@"mailto:feedback@bahnhof.de?subject=%@&body=%@", subject, s];
    }
    
    NSURL* url = [NSURL URLWithString:link];
    if(url){
        [MBUrlOpening openURL:url];
    }
}

-(void)chatBotMail{
    NSString *mailString = [NSString stringWithFormat:@"mailto:feedback@bahnhof.de?subject=%@&body=%@", @"", @""];
    
    NSURL* url = [NSURL URLWithString:mailString];
    
    [MBUrlOpening openURL:url];
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
    
    [MBUrlOpening openURL:url];
}

@end
