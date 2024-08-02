// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBNewsContainerView.h"
#import "MBExternalLinkButton.h"

#import "MBRootContainerViewController.h"
#import "MBNewsOverlayViewController.h"
#import "MBContentSearchResult.h"
#import "MBNewsContainerViewController.h"
#import "MBUrlOpening.h"
#import "MBUIHelper.h"
#import "MBTrackingManager.h"

#import "MBServiceListCollectionViewController.h"
#import "MBServiceListTableViewController.h"

@interface MBNewsContainerView()

@property(nonatomic,strong) UIButton* touchAreaButton;
@property(nonatomic,strong) UIView* headerLabelContainer;
@property(nonatomic,strong) UILabel* staticHeaderlabel;
@property(nonatomic,strong) UIView* line;
@property(nonatomic,strong) UIImageView* icon;

@property(nonatomic,strong) UIView* textBlock;
@property(nonatomic,strong) UILabel* titleLabel;
@property(nonatomic,strong) UILabel* contentLabel;

@property(nonatomic) NSInteger sizeOfBlock;
@end

@implementation MBNewsContainerView

-(instancetype)initWithFrame:(CGRect)frame news:(MBNews*)news{
    self = [super initWithFrame:frame];
    if(self){
        _news = news;
        self.clipsToBounds = NO;
        self.backgroundColor = [UIColor whiteColor];
        [self configureH1Shadow];
        
        self.headerLabelContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 44)];
        self.headerLabelContainer.clipsToBounds = YES;
        [self addSubview:self.headerLabelContainer];
        self.staticHeaderlabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 44)];
        self.staticHeaderlabel.textAlignment = NSTextAlignmentLeft;
        self.staticHeaderlabel.text = @"+++ Aktuelle Informationen ";
        if(self.news.headerOverwrite != nil){
            if(self.endlessAnimation){
                self.staticHeaderlabel.text = [NSString stringWithFormat:@"+++ %@ ",self.news.headerOverwrite];
            } else {
                self.staticHeaderlabel.text = self.news.headerOverwrite;
            }
        }
        self.staticHeaderlabel.font = [UIFont db_BoldSixteen];
        self.staticHeaderlabel.textColor = [UIColor db_333333];
        [self.headerLabelContainer addSubview:self.staticHeaderlabel];
        [self.staticHeaderlabel sizeToFit];
        
        self.sizeOfBlock = self.staticHeaderlabel.sizeWidth;
        NSString* txt = [self.staticHeaderlabel.text copy];
        if(self.endlessAnimation){
            for(NSInteger i=0; i<3; i++){
                self.staticHeaderlabel.text = [self.staticHeaderlabel.text stringByAppendingString:txt];
            }
        } else {
//            self.staticHeaderlabel.text = [self.staticHeaderlabel.text stringByAppendingString:@"+++"];
            [self.staticHeaderlabel setGravityLeft:16];
        }
        [self.staticHeaderlabel sizeToFit];
        [self.staticHeaderlabel setHeight:44];

        //the +++ are displayed in red color
        NSMutableAttributedString* attrText = [[NSMutableAttributedString alloc] initWithString:self.staticHeaderlabel.text attributes:@{NSForegroundColorAttributeName:[UIColor db_333333]}];
        NSDictionary* hightlightAttr = @{NSForegroundColorAttributeName:[UIColor db_mainColor]};
        NSRange searchrange = NSMakeRange(0, self.staticHeaderlabel.text.length-1);
        while(true){
            NSRange plusRange = [self.staticHeaderlabel.text rangeOfString:@"+++" options:0 range:searchrange];
            if(plusRange.location != NSNotFound){
                [attrText setAttributes:hightlightAttr range:plusRange];
                searchrange = NSMakeRange(plusRange.location+3, self.staticHeaderlabel.text.length-(plusRange.location+3));
                if(searchrange.location >= self.staticHeaderlabel.text.length){
                    break;
                }
            } else {
                break;
            }
        }
        self.staticHeaderlabel.attributedText = attrText;
        
        if(self.endlessAnimation){
            [UIView animateWithDuration:6 delay:0 options:UIViewAnimationOptionRepeat|UIViewAnimationOptionCurveLinear animations:^{
                [self.staticHeaderlabel setGravityLeft:-self.sizeOfBlock];
            } completion:nil];
        }
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(didBecomeActive)
                                                   name:UIApplicationDidBecomeActiveNotification
                                                 object:nil];

        self.line = [[UIView alloc] initWithFrame:CGRectMake(0, 45, self.frame.size.width, 1)];
        self.line.backgroundColor = [UIColor db_light_lineColor];
        [self addSubview:self.line];
        
        self.icon = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"news_coupon"]];
        [self addSubview:self.icon];
        
        self.textBlock = [UIView new];
        [self addSubview:self.textBlock];
        
        UILabel* title = [[UILabel alloc] initWithFrame:CGRectZero];
        [self.textBlock addSubview:title];
        title.numberOfLines = 2;
        title.font = [UIFont db_BoldFourteen];
        title.textColor = [UIColor db_333333];
        self.titleLabel = title;
        
        
        UILabel* content = [[UILabel alloc] initWithFrame:CGRectZero];
        [self.textBlock addSubview:content];
        content.numberOfLines = 3;
        content.font = [UIFont db_RegularFourteen];
        content.textColor = [UIColor db_333333];
        self.contentLabel = content;


        self.contentLabel.isAccessibilityElement = NO;
        self.staticHeaderlabel.isAccessibilityElement = NO;
        self.titleLabel.isAccessibilityElement = NO;

        self.touchAreaButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.sizeWidth, self.sizeHeight)];
        [self.touchAreaButton addTarget:self action:@selector(touchAreaButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.touchAreaButton];
        
    }
    return self;
}

-(BOOL)endlessAnimation{
    return false;//!UIAccessibilityIsVoiceOverRunning() && !UIAccessibilityIsReduceMotionEnabled();
}

-(void)didBecomeActive{
    if(self.endlessAnimation){
        [self.staticHeaderlabel.layer removeAllAnimations];
        [self.staticHeaderlabel setGravityLeft:0];
        [UIView animateWithDuration:6 delay:0 options:UIViewAnimationOptionRepeat|UIViewAnimationOptionCurveLinear animations:^{
            [self.staticHeaderlabel setGravityLeft:-self.sizeOfBlock];
        } completion:nil];
    }
}

-(void)linkButtonPressed:(id)sender{
    [MBUrlOpening openURL:[NSURL URLWithString:self.news.link]];
}
-(void)touchAreaButtonPressed:(id)sender{
    //STATIC FIX BAHNHOFLIVE-2519
    [MBTrackingManager trackActionsWithStationInfo:@[@"h1",@"tap",@"ersatzverkehrteaser"]];
    MBContentSearchResult* res = [MBContentSearchResult searchResultWithKeywords:CONTENT_SEARCH_KEY_STATIONINFO_SEV];
    MBRootContainerViewController* root = [MBRootContainerViewController currentlyVisibleInstance];
    //[root handleSearchResult:res];
    MBMenuItem* sevItem = [MBServiceListCollectionViewController createMenuItemErsatzverkehrWithStation:root.station];
    MBServiceListTableViewController* vclist = [[MBServiceListTableViewController alloc] initWithItem:sevItem station:root.station];
    res.service = sevItem.services.firstObject;
    vclist.searchResult = res;
    [root.stationContainerNavigationController  pushViewController:vclist animated:true];


/*
    if(self.news.newsType == MBNewsTypeOffer && self.containerVC.station.hasShops){
        [MBTrackingManager trackActionsWithStationInfo:@[@"h1",@"tap",@"coupon"]];
        MBContentSearchResult* res = [MBContentSearchResult searchResultWithCoupon:self.news];
        MBRootContainerViewController* root = [MBRootContainerViewController currentlyVisibleInstance];
        [root handleSearchResult:res];
    } else {
        [MBTrackingManager trackActionsWithStationInfo:@[@"h1",@"tap",@"newsbox"]];
        [MBTrackingManager trackActionsWithStationInfo:@[@"h1",@"tap",@"newstype",[NSString stringWithFormat:@"%lu",(unsigned long)self.news.newsType]]];
        
        MBNewsOverlayViewController* vc = [[MBNewsOverlayViewController alloc] init];
        vc.news = self.news;
        [MBRootContainerViewController presentViewControllerAsOverlay:vc];
    }*/
}

-(void)setNews:(MBNews *)news{
    _news = news;
    self.titleLabel.text = news.title;
    if(news.subtitle.length > 0){
        self.contentLabel.text = news.subtitle;
    } else {
        self.contentLabel.text = news.content;
    }
    NSString* iconName = nil;
    switch (news.newsType) {
        case MBNewsTypePoll:
            iconName = @"news_survey";
            break;
        case MBNewsTypeOffer:
            iconName = @"news_coupon";
            break;
        case MBNewsTypeMajorDisruption:
        case MBNewsTypeDisruption:
            iconName = @"SEV_Icon";//@"news_malfunction";//BAHNHOFLIVE-2353
            break;
        case MBNewsTypeProductsServices:
            iconName = @"news_neuambahnhof";
            break;
        case MBNewsTypeUndefined:
            break;
    }
    if(iconName){
        self.icon.image = [UIImage db_imageNamed:iconName];
        CGRect f = self.icon.frame;
        f.size = CGSizeMake(52, 52);//BAHNHOFLIVE-2353
        self.icon.frame = f;
    } else {
        self.icon.image = nil;
    }
    //update layout: resize and position text labels
    
    [self.icon setGravityLeft:15];
    [self.icon setGravityTop:CGRectGetMaxY(self.line.frame)+(self.size.height-20-CGRectGetMaxY(self.line.frame))/2-self.icon.frame.size.height/2];

    NSInteger x = CGRectGetMaxX(self.icon.frame)+15;
    NSInteger contentWidth = self.frame.size.width-20-x;
    
    NSInteger blockY = CGRectGetMaxY(self.line.frame)+10;
    
    self.titleLabel.frame = CGRectMake(0, 0, contentWidth, self.sizeHeight);
    NSInteger maxHeight = self.sizeHeight-60-20;
    CGSize size = [self.titleLabel sizeThatFits:CGSizeMake(self.titleLabel.sizeWidth, maxHeight)];
    [self.titleLabel setSize:CGSizeMake(ceilf(size.width), ceilf(size.height))];
    
    NSInteger y = CGRectGetMaxY(self.titleLabel.frame)+5;
    maxHeight = self.sizeHeight-y-20;
    self.contentLabel.frame = CGRectMake(0, y, contentWidth, self.sizeHeight);
    size = [self.contentLabel sizeThatFits:CGSizeMake(self.contentLabel.sizeWidth, maxHeight)];
    [self.contentLabel setSize:CGSizeMake(ceilf(size.width), MIN(maxHeight,ceilf(size.height)))];
    y  = CGRectGetMaxY(self.contentLabel.frame);
    
    [self.textBlock setSize:CGSizeMake(contentWidth, y)];
    [self.textBlock setX:x];
    //center textblock after y, max height 74 (that's a header and 3 content lines)
    blockY = blockY + (74-self.textBlock.sizeHeight)/2;
    [self.textBlock setY:blockY];

    self.touchAreaButton.accessibilityLabel = [NSString stringWithFormat:@"Aktuelle Informationen. %@. Zur Anzeige von Details doppeltippen",self.news.title];
    if(self.news.headerOverwrite != nil){
        self.touchAreaButton.accessibilityLabel = [NSString stringWithFormat:@"%@. %@: %@. Zur Anzeige von Details doppeltippen",self.news.headerOverwrite,self.news.title,self.news.content];
    }
}

@end
