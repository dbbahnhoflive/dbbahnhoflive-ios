// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBStaticServiceView.h"
#import "MBLabel.h"

#import "AppDelegate.h"
#import "MBPTSTravelcenter.h"
#import "MBButtonWithData.h"
#import "MBExternalLinkButton.h"
#import <sys/utsname.h>

@interface MBStaticServiceView() <MBTextViewDelegate>
@property (nonatomic, strong) MBService *service;
@property (nonatomic, strong) MBStation *station;

@property(nonatomic) BOOL fullscreenLayout;
@end

@implementation MBStaticServiceView

- (instancetype) initWithService:(MBService*)service station:(MBStation*)station fullscreenLayout:(BOOL)fullscren andFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.clipsToBounds = YES;
        self.fullscreenLayout = fullscren;
        self.service = service;
        self.station = station;
        
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
            NSInteger newHeight = iconBackground.sizeHeight - 2*10;
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
                NSString *imageName = obj[kImageKey];
                if(imageName){
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
                        redPhoneButton.data = obj[kActionButtonAction];
                        [redPhoneButton addTarget:self action:@selector(didTapOnActionButton:) forControlEvents:UIControlEventTouchUpInside];
                    }
                    [redPhoneButton setBackgroundColor:[UIColor db_GrayButton]];
                    [redPhoneButton.titleLabel setFont:[UIFont db_BoldEighteen]];
                    
                    
                    offset.y += redPhoneButton.frame.size.height+10;
                    contentSize.height += redPhoneButton.frame.size.height+10;
                    
                    [baseView addSubview:redPhoneButton];
                }
            }
        }];
    }
    
    // insert table
    if (self.service.table) {
        
        NSArray *rows = [self.service.table objectForKey:@"rows"];
        NSArray *headlines = [self.service.table objectForKey:@"headlines"]; // this gives us the reference to order the rows

        __block CGPoint tableRowOffset = CGPointMake(0, offset.y);
        __block CGFloat totalTableHeight = 20;
        __block CGFloat blockHeight = 0;
        
        [rows enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSArray *rowItems = [obj objectForKey:@"rowItems"];
            
            // sort using descriptor and reference array
            NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"key" ascending:YES comparator:^NSComparisonResult(id obj1, id obj2) {
                NSUInteger index1 = [headlines indexOfObject:obj1];
                NSUInteger index2 = [headlines indexOfObject:obj2];
                return index1 - index2;
            }];
            
            rowItems = [rowItems sortedArrayUsingDescriptors:@[descriptor]];
            
            if (idx > 0) {
                tableRowOffset.y += blockHeight+20; // 20 is the bottom spacing
                blockHeight = 0;
            }
            
            __block CGPoint tableRowItemOffset = CGPointMake(0, tableRowOffset.y);
            
            if (idx > 0) {
                UIView *dividerView = [[UIView alloc] initWithFrame:CGRectMake(0, tableRowItemOffset.y, self.frame.size.width, 0.5)];
                dividerView.backgroundColor = [UIColor db_878c96];
                [baseView addSubview:dividerView];
            }
            
            //iphone will display headline+content in rows, ipad will display headline+content in a table with max 3 columns
            __block NSInteger column = 0;
            __block CGFloat x = 15;
            __block CGFloat maxHeightInRow = 0;
            [rowItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                NSString *headline = [obj objectForKey:@"headline"];
                NSString *content = [obj objectForKey:@"content"];
                
                //NSLog(@"head: %@\ncontent: %@",headline,content);
                
                if(ISIPAD){
                    if(column >= 3){
                        column = 0;
                        x = 15;
                        tableRowItemOffset.y += maxHeightInRow;
                        blockHeight += maxHeightInRow;
                        maxHeightInRow = 0;
                    }
                }
                
                CGFloat width = (ISIPAD ? (int)(((self.frame.size.width-2*40)/3.0)-50) : contentSize.width-2*x);
                
                NSString* txt = [NSString stringWithFormat:@"<b>%@</b><br>%@",headline,content];
                
                MBTextView *contentLabel = [[MBTextView alloc] initWithFrame:CGRectMake(x, tableRowItemOffset.y+15, width, 0)];
                contentLabel.font = [UIFont db_HelveticaFourteen];
                contentLabel.htmlString = txt;
                //contentLabel.textColor = [UIColor db_878c96];
                contentLabel.userInteractionEnabled = YES;
                contentLabel.delegado = self;
                
                [self sizeViewForWidth:contentLabel];
                
                [baseView addSubview:contentLabel];
                
                CGFloat entryHeight = (25+contentLabel.frame.size.height)+5;

                if(ISIPAD){
                    maxHeightInRow = MAX(entryHeight, maxHeightInRow);
                    column++;
                    x += width + 50;
                } else {
                    tableRowItemOffset.y += entryHeight;
                    blockHeight += entryHeight;
                }

            }];
            
            if(ISIPAD){
                tableRowItemOffset.y += maxHeightInRow;
                blockHeight += maxHeightInRow;
            }
            
            totalTableHeight += blockHeight+22.5; // add 2.5 px extra space;
        }];
        
        if(rows.count > 0){
            offset.y += (totalTableHeight)+20;
            contentSize.height += (totalTableHeight)+20;
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
    AppDelegate* app = (AppDelegate*) [UIApplication sharedApplication].delegate;
    [app routeToName:self.service.travelCenter.title location:self.service.travelCenter.coordinate fromViewController:nil];
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
        [[AppDelegate appDelegate] openURL:[NSURL URLWithString:@"https://bahnhof-bot.deutschebahn.com/"]];
    } else if([action isEqualToString:kActionPickpackWebsite]){
        [MBTrackingManager trackActionsWithStationInfo:@[@"d1",@"tap",@"pickpack",@"website"]];
        [[AppDelegate appDelegate] openURL:[NSURL URLWithString:@"https://www.pickpack.de"]];
    } else if([action isEqualToString:kActionPickpackApp]){
        [MBTrackingManager trackActionsWithStationInfo:@[@"d1",@"tap",@"pickpack",@"app"]];
        [[AppDelegate appDelegate] openURL:[NSURL URLWithString:@"https://itunes.apple.com/de/app/pickpack-unterwegs-bestellen/id1437396914?ls=1&mt=8"]];
    } else if([action isEqualToString:kActionFeedbackMail]){
        [self openFeedbackMail];
    } else if([action isEqualToString:kActionFeedbackChatbotMail]){
        [self chatBotMail];
    } else if([action isEqualToString:kActionFeedbackVerschmutzungMail]){
        [self feedbackDirtViaWhatspp:false];
    } else if([action isEqualToString:kActionWhatsAppFeedback]){
        [self feedbackDirtViaWhatspp:true];
    } else {
        NSURL* url = [NSURL URLWithString:action];
        if(url){
            [[AppDelegate appDelegate] openURL:url];
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
        [[AppDelegate appDelegate] openURL:url];
    }
}

-(void)chatBotMail{
    NSString *mailString = [NSString stringWithFormat:@"mailto:feedback@bahnhof.de?subject=%@&body=%@", @"", @""];
    
    NSURL* url = [NSURL URLWithString:mailString];
    
    [[AppDelegate appDelegate] openURL:url];
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

@end
